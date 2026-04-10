module ac_alarm_clock_soc_top (
    input  wire        clk,
    input  wire        reset_sw,
    input  wire [15:0] sw,
    input  wire        btn_mode,
    input  wire        btn_confirm,
    input  wire        btn_hour_up,
    input  wire        btn_min_up,
    input  wire        btn_field_sel,
    output wire [15:0] led,
    output wire [3:0]  an,
    output wire [6:0]  seg
);
    localparam [2:0] MODE_TIME        = 3'd0;
    localparam [2:0] MODE_SET_ALARM   = 3'd1;
    localparam [2:0] MODE_SHOW_ALARM  = 3'd2;
    localparam [2:0] MODE_RINGING     = 3'd3;
    localparam [2:0] MODE_SET_TIME    = 3'd4;

    wire tick_1hz;
    wire tick_scan;

    reg [6:0] blink_div;
    reg blink_on;

    wire [2:0] mode;
    wire pulse_confirm;
    wire pulse_hour_up;
    wire pulse_min_up;
    wire pulse_field_sel;

    reg ringing_latch;
    wire [2:0] effective_mode = ringing_latch ? MODE_RINGING : mode;

    wire [4:0] curr_hour;
    wire [5:0] curr_min;
    wire [5:0] curr_sec;

    wire [3:0] alarm_rd_slot = sw[3:0];
    wire [4:0] alarm_hour;
    wire [5:0] alarm_min;
    wire alarm_valid;
    wire [9:0] valid_bitmap;

    wire alarm_match_found;
    wire [3:0] alarm_match_slot;

    reg alarm_wr_en;
    reg alarm_clr_en;
    reg [3:0] alarm_slot;

    wire [3:0] challenge;
    reg challenge_step;
    reg challenge_seed_load;

    wire [3:0] d3;
    wire [3:0] d2;
    wire [3:0] d1;
    wire [3:0] d0;

    // CPU subsystem wires
    wire [7:0] cpu_instr_addr;
    wire [15:0] cpu_instr_data;
    wire [7:0] cpu_data_addr;
    wire [15:0] cpu_data_wdata;
    wire cpu_data_we;
    wire [15:0] cpu_data_rdata;
    wire cpu_halted;
    wire [3:0] cpu_dbg_state;
    wire [7:0] cpu_dbg_pc;

    // QSPI boundary stub wires (implemented in next phase)
    wire [109:0] qspi_alarms_in  = 110'd0;
    wire [109:0] qspi_alarms_out;
    wire qspi_busy;
    wire qspi_done;
    wire qspi_error;

    ac_clock_divider u_clkdiv (
        .clk      (clk),
        .reset    (reset_sw),
        .tick_1hz (tick_1hz),
        .tick_scan(tick_scan)
    );

    // 400Hz scan -> toggle every 100 ticks gives 2Hz blink
    always @(posedge clk or posedge reset_sw) begin
        if (reset_sw) begin
            blink_div <= 7'd0;
            blink_on  <= 1'b0;
        end else if (tick_scan) begin
            if (blink_div == 7'd99) begin
                blink_div <= 7'd0;
                blink_on  <= ~blink_on;
            end else begin
                blink_div <= blink_div + 1'b1;
            end
        end
    end

    ac_mode_manager u_mode (
        .clk            (clk),
        .reset          (reset_sw),
        .btn_mode       (btn_mode),
        .btn_confirm    (btn_confirm),
        .btn_hour_up    (btn_hour_up),
        .btn_min_up     (btn_min_up),
        .btn_field_sel  (btn_field_sel),
        .mode           (mode),
        .pulse_confirm  (pulse_confirm),
        .pulse_hour_up  (pulse_hour_up),
        .pulse_min_up   (pulse_min_up),
        .pulse_field_sel(pulse_field_sel)
    );

    ac_rtc_timekeeper u_rtc (
        .clk        (clk),
        .reset      (reset_sw),
        .tick_1hz   (tick_1hz),
        .set_time_en((mode == MODE_SET_TIME) && pulse_confirm),
        .set_hour   (sw[15:11]),
        .set_min    (sw[10:5]),
        .hour       (curr_hour),
        .minute     (curr_min),
        .second     (curr_sec)
    );

    always @(*) begin
        alarm_wr_en = 1'b0;
        alarm_clr_en = 1'b0;
        alarm_slot = sw[3:0];

        if ((mode == MODE_SET_ALARM) && pulse_confirm) begin
            alarm_wr_en = 1'b1;
            alarm_slot = sw[3:0];
        end

        if (ringing_latch && (sw[3:0] == challenge)) begin
            alarm_clr_en = 1'b1;
            alarm_slot = alarm_match_slot;
        end
    end

    ac_alarm_table10 u_alarm_tbl (
        .clk        (clk),
        .reset      (reset_sw),
        .wr_en      (alarm_wr_en),
        .clr_en     (alarm_clr_en),
        .slot       (alarm_slot),
        .wr_hour    (sw[15:11]),
        .wr_min     (sw[10:5]),
        .rd_slot    (alarm_rd_slot),
        .rd_hour    (alarm_hour),
        .rd_min     (alarm_min),
        .rd_valid   (alarm_valid),
        .match_en   (tick_1hz),
        .curr_hour  (curr_hour),
        .curr_min   (curr_min),
        .match_found(alarm_match_found),
        .match_slot (alarm_match_slot),
        .valid_bitmap(valid_bitmap)
    );

    always @(posedge clk or posedge reset_sw) begin
        if (reset_sw) begin
            ringing_latch <= 1'b0;
            challenge_step <= 1'b0;
            challenge_seed_load <= 1'b1;
        end else begin
            challenge_step <= 1'b0;
            challenge_seed_load <= 1'b0;

            if (!ringing_latch && alarm_match_found) begin
                ringing_latch <= 1'b1;
                challenge_seed_load <= 1'b1;
                challenge_step <= 1'b1;
            end else if (ringing_latch && (sw[3:0] == challenge)) begin
                ringing_latch <= 1'b0;
            end else if (ringing_latch && tick_1hz) begin
                challenge_step <= 1'b1;
            end
        end
    end

    ac_lfsr4 u_challenge (
        .clk      (clk),
        .reset    (reset_sw),
        .step_en  (challenge_step),
        .seed     ({curr_hour[1:0], curr_min[1:0]}),
        .load_seed(challenge_seed_load),
        .value    (challenge)
    );

    ac_led_controller u_led (
        .mode         (effective_mode),
        .valid_bitmap (valid_bitmap),
        .selected_slot(alarm_rd_slot),
        .blink_on     (blink_on),
        .led          (led)
    );

    ac_display_formatter u_fmt (
        .mode      (effective_mode),
        .curr_hour (curr_hour),
        .curr_min  (curr_min),
        .alarm_hour(alarm_hour),
        .alarm_min (alarm_min),
        .alarm_valid(alarm_valid),
        .challenge (challenge),
        .d3        (d3),
        .d2        (d2),
        .d1        (d1),
        .d0        (d0)
    );

    ac_seg7_mux4 u_seg (
        .clk      (clk),
        .reset    (reset_sw),
        .tick_scan(tick_scan),
        .d3       (d3),
        .d2       (d2),
        .d1       (d1),
        .d0       (d0),
        .an       (an),
        .seg      (seg)
    );

    // CPU path is live and available for upcoming firmware/peripheral mapping phases.
    ac_instr_rom16 u_rom (
        .addr(cpu_instr_addr),
        .data(cpu_instr_data)
    );

    ac_data_ram16 u_ram (
        .clk  (clk),
        .we   (cpu_data_we),
        .addr (cpu_data_addr),
        .wdata(cpu_data_wdata),
        .rdata(cpu_data_rdata)
    );

    ac_cpu16_core u_cpu (
        .clk       (clk),
        .reset     (reset_sw),
        .instr_addr(cpu_instr_addr),
        .instr_data(cpu_instr_data),
        .data_addr (cpu_data_addr),
        .data_wdata(cpu_data_wdata),
        .data_we   (cpu_data_we),
        .data_rdata(cpu_data_rdata),
        .halted    (cpu_halted),
        .dbg_state (cpu_dbg_state),
        .dbg_pc    (cpu_dbg_pc)
    );

    ac_qspi_persistence_stub u_qspi_stub (
        .clk            (clk),
        .reset          (reset_sw),
        .load_req       (1'b0),
        .save_req       (1'b0),
        .alarms_packed_in (qspi_alarms_in),
        .alarms_packed_out(qspi_alarms_out),
        .busy           (qspi_busy),
        .done           (qspi_done),
        .error          (qspi_error)
    );
endmodule

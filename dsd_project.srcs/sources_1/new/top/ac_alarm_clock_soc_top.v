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
    localparam [2:0] MODE_SHOW_TIME     = 3'd0;
    localparam [2:0] MODE_SHOW_ALARMS   = 3'd1;
    localparam [2:0] MODE_SET_ALARM     = 3'd2;
    localparam [2:0] MODE_SET_TIME      = 3'd3;
    localparam [2:0] MODE_RINGING       = 3'd4;
    localparam [2:0] MODE_ALARM_DISABLE = 3'd5;

    wire tick_1hz;
    wire tick_scan;

    reg [6:0] blink_div;
    reg blink_on;

    reg [23:0] por_counter = 24'd0;
    reg        por_reset   = 1'b1;
    wire       sys_reset = reset_sw | por_reset;

    wire [2:0] mode;
    reg        force_mode_en;
    reg [2:0]  force_mode;

    wire pulse_mode;
    wire pulse_confirm;
    wire pulse_hour_up;
    wire pulse_min_up;
    wire pulse_field_sel;

    reg [2:0] mode_prev;

    reg [3:0] selected_slot;
    reg [3:0] active_alarm_slot;

    reg [4:0] edit_alarm_hour;
    reg [5:0] edit_alarm_min;
    reg [4:0] edit_time_hour;
    reg [5:0] edit_time_min;

    reg [4:0] rtc_set_hour;
    reg [5:0] rtc_set_min;
    reg       rtc_set_pulse;

    wire [4:0] curr_hour;
    wire [5:0] curr_min;
    wire [5:0] curr_sec;

    wire [4:0] alarm_hour;
    wire [5:0] alarm_min;
    wire alarm_valid;
    wire [9:0] valid_bitmap;

    wire alarm_match_found;
    wire [3:0] alarm_match_slot;

    wire duplicate_alarm;

    reg alarm_wr_cmd;
    reg alarm_clr_cmd;
    reg [3:0] alarm_slot_cmd;
    reg [4:0] alarm_hour_cmd;
    reg [5:0] alarm_min_cmd;

    reg sw15_prev;
    reg cancel_toggle;

    wire [3:0] challenge;
    reg challenge_step;
    reg challenge_seed_load;

    wire [4:0] s3;
    wire [4:0] s2;
    wire [4:0] s1;
    wire [4:0] s0;

    wire [4:0] snooze5_hour;
    wire [5:0] snooze5_min;
    wire [4:0] snooze10_hour;
    wire [5:0] snooze10_min;

    reg err_active;
    reg err_led;
    reg [2:0] err_phase;
    reg [26:0] err_counter;
    reg err_request;

    wire status_led = err_active ? err_led : ((mode == MODE_ALARM_DISABLE) ? blink_on : 1'b0);

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

    // QSPI boundary stub wires
    wire [109:0] qspi_alarms_in  = 110'd0;
    wire [109:0] qspi_alarms_out;
    wire qspi_busy;
    wire qspi_done;
    wire qspi_error;

    ac_clock_divider u_clkdiv (
        .clk      (clk),
        .reset    (sys_reset),
        .tick_1hz (tick_1hz),
        .tick_scan(tick_scan)
    );

    always @(posedge clk or posedge reset_sw) begin
        if (reset_sw) begin
            por_counter <= 24'd0;
            por_reset   <= 1'b1;
        end else if (por_reset) begin
            por_counter <= por_counter + 1'b1;
            if (&por_counter) begin
                por_reset <= 1'b0;
            end
        end
    end

    // 400Hz scan -> toggle every 100 ticks gives 2Hz blink
    always @(posedge clk or posedge sys_reset) begin
        if (sys_reset) begin
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
        .reset          (sys_reset),
        .btn_mode       (btn_mode),
        .btn_confirm    (btn_confirm),
        .btn_hour_up    (btn_hour_up),
        .btn_min_up     (btn_min_up),
        .btn_field_sel  (btn_field_sel),
        .force_mode_en  (force_mode_en),
        .force_mode     (force_mode),
        .mode           (mode),
        .pulse_mode     (pulse_mode),
        .pulse_confirm  (pulse_confirm),
        .pulse_hour_up  (pulse_hour_up),
        .pulse_min_up   (pulse_min_up),
        .pulse_field_sel(pulse_field_sel)
    );

    wire sw15_db;
    ac_debouncer u_db_sw15 (
        .clk      (clk),
        .reset    (sys_reset),
        .noisy_in (sw[15]),
        .clean_out(sw15_db)
    );

    always @(posedge clk or posedge sys_reset) begin
        if (sys_reset) begin
            sw15_prev    <= 1'b0;
            cancel_toggle <= 1'b0;
        end else begin
            cancel_toggle <= (sw15_db ^ sw15_prev);
            sw15_prev     <= sw15_db;
        end
    end

    ac_rtc_timekeeper u_rtc (
        .clk        (clk),
        .reset      (sys_reset),
        .tick_1hz   (tick_1hz),
        .set_time_en(rtc_set_pulse),
        .set_hour   (rtc_set_hour),
        .set_min    (rtc_set_min),
        .hour       (curr_hour),
        .minute     (curr_min),
        .second     (curr_sec)
    );

    ac_alarm_table10 u_alarm_tbl (
        .clk        (clk),
        .reset      (sys_reset),
        .wr_en      (alarm_wr_cmd),
        .clr_en     (alarm_clr_cmd),
        .slot       (alarm_slot_cmd),
        .wr_hour    (alarm_hour_cmd),
        .wr_min     (alarm_min_cmd),
        .rd_slot    (selected_slot),
        .rd_hour    (alarm_hour),
        .rd_min     (alarm_min),
        .rd_valid   (alarm_valid),
        .match_en   (tick_1hz),
        .curr_hour  (curr_hour),
        .curr_min   (curr_min),
        .match_found(alarm_match_found),
        .match_slot (alarm_match_slot),
        .chk_en     (mode == MODE_SET_ALARM),
        .chk_hour   (edit_alarm_hour),
        .chk_min    (edit_alarm_min),
        .chk_exclude_slot(selected_slot),
        .chk_duplicate(duplicate_alarm),
        .valid_bitmap(valid_bitmap)
    );

    ac_snooze_calc u_snooze5 (
        .curr_hour (curr_hour),
        .curr_min  (curr_min),
        .plus_ten  (1'b0),
        .new_hour  (snooze5_hour),
        .new_min   (snooze5_min)
    );

    ac_snooze_calc u_snooze10 (
        .curr_hour (curr_hour),
        .curr_min  (curr_min),
        .plus_ten  (1'b1),
        .new_hour  (snooze10_hour),
        .new_min   (snooze10_min)
    );

    always @(posedge clk or posedge sys_reset) begin
        if (sys_reset) begin
            force_mode_en   <= 1'b0;
            force_mode      <= MODE_SHOW_TIME;
            mode_prev       <= MODE_SHOW_TIME;
            selected_slot   <= 4'd0;
            active_alarm_slot <= 4'd0;
            edit_alarm_hour <= 5'd0;
            edit_alarm_min  <= 6'd0;
            edit_time_hour  <= 5'd0;
            edit_time_min   <= 6'd0;
            rtc_set_hour    <= 5'd0;
            rtc_set_min     <= 6'd0;
            rtc_set_pulse   <= 1'b0;
            alarm_wr_cmd    <= 1'b0;
            alarm_clr_cmd   <= 1'b0;
            alarm_slot_cmd  <= 4'd0;
            alarm_hour_cmd  <= 5'd0;
            alarm_min_cmd   <= 6'd0;
            challenge_seed_load <= 1'b1;
            challenge_step  <= 1'b0;
            err_request     <= 1'b0;
        end else begin
            force_mode_en   <= 1'b0;
            rtc_set_pulse   <= 1'b0;
            alarm_wr_cmd    <= 1'b0;
            alarm_clr_cmd   <= 1'b0;
            challenge_seed_load <= 1'b0;
            challenge_step  <= 1'b0;
            err_request     <= 1'b0;

            // Enter ringing mode only by alarm trigger.
            if ((mode != MODE_RINGING) && (mode != MODE_ALARM_DISABLE) && alarm_match_found) begin
                force_mode_en   <= 1'b1;
                force_mode      <= MODE_RINGING;
                active_alarm_slot <= alarm_match_slot;
            end else begin
                case (mode)
                    MODE_SHOW_ALARMS: begin
                        if (pulse_hour_up) begin
                            selected_slot <= (selected_slot == 4'd0) ? 4'd9 : (selected_slot - 1'b1);
                        end
                        if (pulse_confirm) begin
                            selected_slot <= (selected_slot == 4'd9) ? 4'd0 : (selected_slot + 1'b1);
                        end
                        if (pulse_field_sel) begin
                            alarm_clr_cmd  <= 1'b1;
                            alarm_slot_cmd <= selected_slot;
                        end
                        if (pulse_min_up) begin
                            edit_alarm_hour <= alarm_valid ? alarm_hour : 5'd0;
                            edit_alarm_min  <= alarm_valid ? alarm_min  : 6'd0;
                            force_mode_en <= 1'b1;
                            force_mode    <= MODE_SET_ALARM;
                        end
                    end

                    MODE_SET_ALARM: begin
                        if (cancel_toggle) begin
                            force_mode_en <= 1'b1;
                            force_mode    <= MODE_SHOW_ALARMS;
                        end else begin
                            if (pulse_hour_up) begin
                                edit_alarm_hour <= (edit_alarm_hour == 5'd0) ? 5'd23 : (edit_alarm_hour - 1'b1);
                            end
                            if (pulse_confirm) begin
                                edit_alarm_hour <= (edit_alarm_hour == 5'd23) ? 5'd0 : (edit_alarm_hour + 1'b1);
                            end
                            if (pulse_mode) begin
                                edit_alarm_min <= (edit_alarm_min == 6'd59) ? 6'd0 : (edit_alarm_min + 1'b1);
                            end
                            if (pulse_min_up) begin
                                edit_alarm_min <= (edit_alarm_min == 6'd0) ? 6'd59 : (edit_alarm_min - 1'b1);
                            end
                            if (pulse_field_sel) begin
                                if (duplicate_alarm) begin
                                    err_request <= 1'b1;
                                end else begin
                                    alarm_wr_cmd   <= 1'b1;
                                    alarm_slot_cmd <= selected_slot;
                                    alarm_hour_cmd <= edit_alarm_hour;
                                    alarm_min_cmd  <= edit_alarm_min;
                                    force_mode_en  <= 1'b1;
                                    force_mode     <= MODE_SHOW_ALARMS;
                                end
                            end
                        end
                    end

                    MODE_SET_TIME: begin
                        if (mode_prev != MODE_SET_TIME) begin
                            edit_time_hour <= curr_hour;
                            edit_time_min  <= curr_min;
                        end

                        if (cancel_toggle) begin
                            force_mode_en <= 1'b1;
                            force_mode    <= MODE_SHOW_TIME;
                        end else begin
                            if (pulse_hour_up) begin
                                edit_time_hour <= (edit_time_hour == 5'd0) ? 5'd23 : (edit_time_hour - 1'b1);
                            end
                            if (pulse_confirm) begin
                                edit_time_hour <= (edit_time_hour == 5'd23) ? 5'd0 : (edit_time_hour + 1'b1);
                            end
                            if (pulse_min_up) begin
                                edit_time_min <= (edit_time_min == 6'd0) ? 6'd59 : (edit_time_min - 1'b1);
                            end
                            if (pulse_field_sel) begin
                                rtc_set_hour  <= edit_time_hour;
                                rtc_set_min   <= edit_time_min;
                                rtc_set_pulse <= 1'b1;
                                force_mode_en <= 1'b1;
                                force_mode    <= MODE_SHOW_TIME;
                            end
                        end
                    end

                    MODE_RINGING: begin
                        if (pulse_mode) begin
                            alarm_wr_cmd   <= 1'b1;
                            alarm_slot_cmd <= active_alarm_slot;
                            alarm_hour_cmd <= snooze5_hour;
                            alarm_min_cmd  <= snooze5_min;
                            force_mode_en  <= 1'b1;
                            force_mode     <= MODE_SHOW_TIME;
                        end else if (pulse_min_up) begin
                            alarm_wr_cmd   <= 1'b1;
                            alarm_slot_cmd <= active_alarm_slot;
                            alarm_hour_cmd <= snooze10_hour;
                            alarm_min_cmd  <= snooze10_min;
                            force_mode_en  <= 1'b1;
                            force_mode     <= MODE_SHOW_TIME;
                        end else if (pulse_field_sel) begin
                            force_mode_en      <= 1'b1;
                            force_mode         <= MODE_ALARM_DISABLE;
                            challenge_seed_load <= 1'b1;
                            challenge_step     <= 1'b1;
                        end
                    end

                    MODE_ALARM_DISABLE: begin
                        if (pulse_mode) begin
                            alarm_wr_cmd   <= 1'b1;
                            alarm_slot_cmd <= active_alarm_slot;
                            alarm_hour_cmd <= snooze5_hour;
                            alarm_min_cmd  <= snooze5_min;
                            force_mode_en  <= 1'b1;
                            force_mode     <= MODE_SHOW_TIME;
                        end else if (pulse_min_up) begin
                            alarm_wr_cmd   <= 1'b1;
                            alarm_slot_cmd <= active_alarm_slot;
                            alarm_hour_cmd <= snooze10_hour;
                            alarm_min_cmd  <= snooze10_min;
                            force_mode_en  <= 1'b1;
                            force_mode     <= MODE_SHOW_TIME;
                        end else if (pulse_confirm) begin
                            if (sw[3:0] == challenge) begin
                                alarm_clr_cmd   <= 1'b1;
                                alarm_slot_cmd  <= active_alarm_slot;
                                force_mode_en   <= 1'b1;
                                force_mode      <= MODE_SHOW_TIME;
                            end else begin
                                err_request <= 1'b1;
                                challenge_step <= 1'b1;
                            end
                        end else if (pulse_hour_up) begin
                            err_request <= 1'b1;
                            challenge_step <= 1'b1;
                        end
                    end

                    default: begin
                        // mode 0 uses normal cycle only.
                    end
                endcase
            end

            mode_prev <= mode;
        end
    end

    always @(posedge clk or posedge sys_reset) begin
        if (sys_reset) begin
            err_active   <= 1'b0;
            err_led      <= 1'b0;
            err_phase    <= 3'd0;
            err_counter  <= 27'd0;
        end else if (err_request) begin
            err_active   <= 1'b1;
            err_led      <= 1'b1;
            err_phase    <= 3'd0;
            err_counter  <= 27'd0;
        end else if (err_active) begin
            if (err_counter == 27'd99_999_999) begin
                err_counter <= 27'd0;
                if (err_phase == 3'd5) begin
                    err_active <= 1'b0;
                    err_led    <= 1'b0;
                end else begin
                    err_phase <= err_phase + 1'b1;
                    err_led   <= ~err_led;
                end
            end else begin
                err_counter <= err_counter + 1'b1;
            end
        end
    end

    ac_lfsr4 u_challenge (
        .clk      (clk),
        .reset    (sys_reset),
        .step_en  (challenge_step),
        .seed     ({curr_hour[1:0], curr_min[1:0]}),
        .load_seed(challenge_seed_load),
        .value    (challenge)
    );

    ac_led_controller u_led (
        .mode         (mode),
        .valid_bitmap (valid_bitmap),
        .selected_slot(selected_slot),
        .blink_on     (blink_on),
        .status_led   (status_led),
        .led          (led)
    );

    ac_display_formatter u_fmt (
        .mode          (mode),
        .curr_hour     (curr_hour),
        .curr_min      (curr_min),
        .alarm_hour    (alarm_hour),
        .alarm_min     (alarm_min),
        .alarm_valid(alarm_valid),
        .edit_alarm_hour(edit_alarm_hour),
        .edit_alarm_min (edit_alarm_min),
        .edit_time_hour (edit_time_hour),
        .edit_time_min  (edit_time_min),
        .disable_hex    (challenge),
        .s3            (s3),
        .s2            (s2),
        .s1            (s1),
        .s0            (s0)
    );

    ac_seg7_mux4 u_seg (
        .clk      (clk),
        .reset    (sys_reset),
        .tick_scan(tick_scan),
        .s3       (s3),
        .s2       (s2),
        .s1       (s1),
        .s0       (s0),
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
        .reset     (sys_reset),
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
        .reset          (sys_reset),
        .load_req       (1'b0),
        .save_req       (1'b0),
        .alarms_packed_in (qspi_alarms_in),
        .alarms_packed_out(qspi_alarms_out),
        .busy           (qspi_busy),
        .done           (qspi_done),
        .error          (qspi_error)
    );
endmodule

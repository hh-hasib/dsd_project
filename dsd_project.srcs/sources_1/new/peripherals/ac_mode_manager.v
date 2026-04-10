module ac_mode_manager (
    input  wire       clk,
    input  wire       reset,
    input  wire       btn_mode,
    input  wire       btn_confirm,
    input  wire       btn_hour_up,
    input  wire       btn_min_up,
    input  wire       btn_field_sel,
    output reg  [2:0] mode,
    output wire       pulse_confirm,
    output wire       pulse_hour_up,
    output wire       pulse_min_up,
    output wire       pulse_field_sel
);
    localparam [2:0] MODE_TIME        = 3'd0;
    localparam [2:0] MODE_SET_ALARM   = 3'd1;
    localparam [2:0] MODE_SHOW_ALARM  = 3'd2;
    localparam [2:0] MODE_RINGING     = 3'd3;
    localparam [2:0] MODE_SET_TIME    = 3'd4;

    wire mode_db;
    wire confirm_db;
    wire hour_db;
    wire min_db;
    wire field_db;

    wire pulse_mode;

    ac_debouncer u_db_mode (.clk(clk), .reset(reset), .noisy_in(btn_mode),      .clean_out(mode_db));
    ac_debouncer u_db_c    (.clk(clk), .reset(reset), .noisy_in(btn_confirm),   .clean_out(confirm_db));
    ac_debouncer u_db_h    (.clk(clk), .reset(reset), .noisy_in(btn_hour_up),   .clean_out(hour_db));
    ac_debouncer u_db_m    (.clk(clk), .reset(reset), .noisy_in(btn_min_up),    .clean_out(min_db));
    ac_debouncer u_db_f    (.clk(clk), .reset(reset), .noisy_in(btn_field_sel), .clean_out(field_db));

    ac_edge_pulse u_ep_mode (.clk(clk), .reset(reset), .level_in(mode_db),    .pulse_out(pulse_mode));
    ac_edge_pulse u_ep_c    (.clk(clk), .reset(reset), .level_in(confirm_db), .pulse_out(pulse_confirm));
    ac_edge_pulse u_ep_h    (.clk(clk), .reset(reset), .level_in(hour_db),    .pulse_out(pulse_hour_up));
    ac_edge_pulse u_ep_m    (.clk(clk), .reset(reset), .level_in(min_db),     .pulse_out(pulse_min_up));
    ac_edge_pulse u_ep_f    (.clk(clk), .reset(reset), .level_in(field_db),   .pulse_out(pulse_field_sel));

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mode <= MODE_TIME;
        end else if (pulse_mode) begin
            if (mode == MODE_SET_TIME) begin
                mode <= MODE_TIME;
            end else begin
                mode <= mode + 1'b1;
            end
        end
    end
endmodule

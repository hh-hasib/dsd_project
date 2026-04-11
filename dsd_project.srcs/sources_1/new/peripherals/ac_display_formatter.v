module ac_display_formatter (
    input  wire [2:0] mode,
    input  wire [4:0] curr_hour,
    input  wire [5:0] curr_min,
    input  wire [4:0] alarm_hour,
    input  wire [5:0] alarm_min,
    input  wire       alarm_valid,
    input  wire [4:0] edit_alarm_hour,
    input  wire [5:0] edit_alarm_min,
    input  wire [4:0] edit_time_hour,
    input  wire [5:0] edit_time_min,
    input  wire [3:0] disable_hex,
    output reg  [4:0] s3,
    output reg  [4:0] s2,
    output reg  [4:0] s1,
    output reg  [4:0] s0
);
    localparam [2:0] MODE_SHOW_TIME     = 3'd0;
    localparam [2:0] MODE_SHOW_ALARMS   = 3'd1;
    localparam [2:0] MODE_SET_ALARM     = 3'd2;
    localparam [2:0] MODE_SET_TIME      = 3'd3;
    localparam [2:0] MODE_RINGING       = 3'd4;
    localparam [2:0] MODE_ALARM_DISABLE = 3'd5;

    localparam [4:0] SYM_A     = 5'd10;
    localparam [4:0] SYM_F     = 5'd15;
    localparam [4:0] SYM_BLANK = 5'd16;
    localparam [4:0] SYM_L     = 5'd17;
    localparam [4:0] SYM_r     = 5'd18;
    localparam [4:0] SYM_M     = 5'd19;
    localparam [4:0] SYM_O     = 5'd20;

    reg [3:0] hour_tens;
    reg [3:0] hour_ones;
    reg [3:0] min_tens;
    reg [3:0] min_ones;
    reg [3:0] alarm_hour_tens;
    reg [3:0] alarm_hour_ones;
    reg [3:0] alarm_min_tens;
    reg [3:0] alarm_min_ones;
    reg [3:0] edit_alarm_hour_tens;
    reg [3:0] edit_alarm_hour_ones;
    reg [3:0] edit_alarm_min_tens;
    reg [3:0] edit_alarm_min_ones;
    reg [3:0] edit_time_hour_tens;
    reg [3:0] edit_time_hour_ones;
    reg [3:0] edit_time_min_tens;
    reg [3:0] edit_time_min_ones;

    always @(*) begin
        hour_tens = curr_hour / 10;
        hour_ones = curr_hour % 10;
        min_tens  = curr_min / 10;
        min_ones  = curr_min % 10;

        alarm_hour_tens = alarm_hour / 10;
        alarm_hour_ones = alarm_hour % 10;
        alarm_min_tens  = alarm_min  / 10;
        alarm_min_ones  = alarm_min  % 10;

        edit_alarm_hour_tens = edit_alarm_hour / 10;
        edit_alarm_hour_ones = edit_alarm_hour % 10;
        edit_alarm_min_tens  = edit_alarm_min  / 10;
        edit_alarm_min_ones  = edit_alarm_min  % 10;

        edit_time_hour_tens = edit_time_hour / 10;
        edit_time_hour_ones = edit_time_hour % 10;
        edit_time_min_tens  = edit_time_min  / 10;
        edit_time_min_ones  = edit_time_min  % 10;

        case (mode)
            MODE_SHOW_TIME: begin
                s3 = {1'b0, hour_tens};
                s2 = {1'b0, hour_ones};
                s1 = {1'b0, min_tens};
                s0 = {1'b0, min_ones};
            end

            MODE_SHOW_ALARMS: begin
                if (alarm_valid) begin
                    s3 = {1'b0, alarm_hour_tens};
                    s2 = {1'b0, alarm_hour_ones};
                    s1 = {1'b0, alarm_min_tens};
                    s0 = {1'b0, alarm_min_ones};
                end else begin
                    s3 = SYM_A;
                    s2 = SYM_A;
                    s1 = SYM_A;
                    s0 = SYM_A;
                end
            end

            MODE_SET_ALARM: begin
                s3 = {1'b0, edit_alarm_hour_tens};
                s2 = {1'b0, edit_alarm_hour_ones};
                s1 = {1'b0, edit_alarm_min_tens};
                s0 = {1'b0, edit_alarm_min_ones};
            end

            MODE_SET_TIME: begin
                s3 = {1'b0, edit_time_hour_tens};
                s2 = {1'b0, edit_time_hour_ones};
                s1 = {1'b0, edit_time_min_tens};
                s0 = {1'b0, edit_time_min_ones};
            end

            MODE_RINGING: begin
                s3 = SYM_A;
                s2 = SYM_L;
                s1 = SYM_r;
                s0 = SYM_M;
            end

            MODE_ALARM_DISABLE: begin
                s3 = SYM_BLANK;
                s2 = {1'b0, disable_hex};
                s1 = SYM_O;
                s0 = SYM_F;
            end

            default: begin
                s3 = SYM_BLANK;
                s2 = SYM_BLANK;
                s1 = SYM_BLANK;
                s0 = SYM_BLANK;
            end
        endcase
    end
endmodule

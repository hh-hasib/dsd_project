module ac_display_formatter (
    input  wire [2:0] mode,
    input  wire [4:0] curr_hour,
    input  wire [5:0] curr_min,
    input  wire [4:0] alarm_hour,
    input  wire [5:0] alarm_min,
    input  wire       alarm_valid,
    input  wire [3:0] challenge,
    output reg  [3:0] d3,
    output reg  [3:0] d2,
    output reg  [3:0] d1,
    output reg  [3:0] d0
);
    localparam [2:0] MODE_TIME        = 3'd0;
    localparam [2:0] MODE_SET_ALARM   = 3'd1;
    localparam [2:0] MODE_SHOW_ALARM  = 3'd2;
    localparam [2:0] MODE_RINGING     = 3'd3;
    localparam [2:0] MODE_SET_TIME    = 3'd4;

    reg [3:0] hour_tens;
    reg [3:0] hour_ones;
    reg [3:0] min_tens;
    reg [3:0] min_ones;
    reg [3:0] challenge_tens;
    reg [3:0] challenge_ones;

    always @(*) begin
        hour_tens = curr_hour / 10;
        hour_ones = curr_hour % 10;
        min_tens  = curr_min / 10;
        min_ones  = curr_min % 10;

        challenge_tens = challenge / 10;
        challenge_ones = challenge % 10;

        case (mode)
            MODE_TIME,
            MODE_SET_TIME: begin
                d3 = hour_tens;
                d2 = hour_ones;
                d1 = min_tens;
                d0 = min_ones;
            end

            MODE_SET_ALARM,
            MODE_SHOW_ALARM: begin
                if (alarm_valid) begin
                    d3 = alarm_hour / 10;
                    d2 = alarm_hour % 10;
                    d1 = alarm_min  / 10;
                    d0 = alarm_min  % 10;
                end else begin
                    d3 = 4'hF;
                    d2 = 4'hF;
                    d1 = 4'hF;
                    d0 = 4'hF;
                end
            end

            MODE_RINGING: begin
                d3 = 4'd0;
                d2 = 4'd0;
                d1 = challenge_tens;
                d0 = challenge_ones;
            end

            default: begin
                d3 = 4'hF;
                d2 = 4'hF;
                d1 = 4'hF;
                d0 = 4'hF;
            end
        endcase
    end
endmodule

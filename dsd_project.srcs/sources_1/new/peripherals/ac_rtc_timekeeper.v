module ac_rtc_timekeeper (
    input  wire       clk,
    input  wire       reset,
    input  wire       tick_1hz,
    input  wire       set_time_en,
    input  wire [4:0] set_hour,
    input  wire [5:0] set_min,
    output reg  [4:0] hour,
    output reg  [5:0] minute,
    output reg  [5:0] second
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            hour   <= 5'd0;
            minute <= 6'd0;
            second <= 6'd0;
        end else if (set_time_en) begin
            hour   <= (set_hour <= 5'd23) ? set_hour : 5'd0;
            minute <= (set_min  <= 6'd59) ? set_min  : 6'd0;
            second <= 6'd0;
        end else if (tick_1hz) begin
            if (second == 6'd59) begin
                second <= 6'd0;
                if (minute == 6'd59) begin
                    minute <= 6'd0;
                    if (hour == 5'd23) begin
                        hour <= 5'd0;
                    end else begin
                        hour <= hour + 1'b1;
                    end
                end else begin
                    minute <= minute + 1'b1;
                end
            end else begin
                second <= second + 1'b1;
            end
        end
    end
endmodule

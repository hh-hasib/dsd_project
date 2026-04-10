module ac_led_controller (
    input  wire [2:0]  mode,
    input  wire [9:0]  valid_bitmap,
    input  wire [3:0]  selected_slot,
    input  wire        blink_on,
    output reg  [15:0] led
);
    localparam [2:0] MODE_SHOW_ALARM  = 3'd2;
    localparam [2:0] MODE_RINGING     = 3'd3;

    always @(*) begin
        led = 16'd0;

        if (mode == MODE_RINGING) begin
            led = blink_on ? 16'hFFFF : 16'h0000;
        end else begin
            led[9:0] = valid_bitmap;
            if ((mode == MODE_SHOW_ALARM) && (selected_slot < 4'd10) && valid_bitmap[selected_slot]) begin
                led[selected_slot] = blink_on;
            end
        end
    end
endmodule

module ac_led_controller (
    input  wire [2:0]  mode,
    input  wire [9:0]  valid_bitmap,
    input  wire [3:0]  selected_slot,
    input  wire        blink_on,
    input  wire        status_led,
    output reg  [15:0] led
);
    localparam [2:0] MODE_SHOW_TIME     = 3'd0;
    localparam [2:0] MODE_SHOW_ALARMS   = 3'd1;
    localparam [2:0] MODE_SET_ALARM     = 3'd2;
    localparam [2:0] MODE_SET_TIME      = 3'd3;
    localparam [2:0] MODE_RINGING       = 3'd4;
    localparam [2:0] MODE_ALARM_DISABLE = 3'd5;

    always @(*) begin
        led = 16'd0;

        if (mode == MODE_RINGING) begin
            led = blink_on ? 16'hFFFF : 16'h0000;
        end else begin
            // Alarm occupancy map: led[0]..led[9] -> alarm0..alarm9.
            led[9:0] = valid_bitmap;

            // Show selected alarm slot by blinking its LED in mode 1.
            if ((mode == MODE_SHOW_ALARMS) && (selected_slot < 4'd10)) begin
                led[selected_slot] = blink_on;
            end

            // Mode indicator LEDs: led[10]..led[14] => modes 0..4.
            case (mode)
                MODE_SHOW_TIME:   led[10] = 1'b1;
                MODE_SHOW_ALARMS: led[11] = 1'b1;
                MODE_SET_ALARM:   led[12] = 1'b1;
                MODE_SET_TIME:    led[13] = 1'b1;
                MODE_RINGING:     led[14] = 1'b1;
                MODE_ALARM_DISABLE: led[14] = blink_on;
                default: ;
            endcase

            // Status LED (L1) is externally generated policy.
            led[15] = status_led;
        end
    end
endmodule

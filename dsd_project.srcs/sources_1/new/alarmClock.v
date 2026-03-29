// Module 1: clock_divider
// Generates one-cycle enable pulses from a 100MHz master clock.
module clock_divider #(
    parameter integer CLK_FREQ_HZ   = 100_000_000,
    parameter integer TICK_1HZ_HZ   = 1,
    parameter integer TICK_400HZ_HZ = 400,
    parameter integer COUNTER_WIDTH = 32
)(
    input  wire clk,
    input  wire reset,       // Active-high asynchronous reset
    output reg  tick_1Hz,
    output reg  tick_400Hz
);

    localparam integer DIV_1HZ   = CLK_FREQ_HZ / TICK_1HZ_HZ;     // 100,000,000 @100MHz
    localparam integer DIV_400HZ = CLK_FREQ_HZ / TICK_400HZ_HZ;   //   250,000 @100MHz

    reg [COUNTER_WIDTH-1:0] cnt_1Hz;
    reg [COUNTER_WIDTH-1:0] cnt_400Hz;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt_1Hz    <= {COUNTER_WIDTH{1'b0}};
            cnt_400Hz  <= {COUNTER_WIDTH{1'b0}};
            tick_1Hz   <= 1'b0;
            tick_400Hz <= 1'b0;
        end else begin
            // Default low; pulse high for exactly one master-clock cycle.
            tick_1Hz   <= 1'b0;
            tick_400Hz <= 1'b0;

            if (cnt_1Hz == (DIV_1HZ - 1)) begin
                cnt_1Hz  <= {COUNTER_WIDTH{1'b0}};
                tick_1Hz <= 1'b1;
            end else begin
                cnt_1Hz <= cnt_1Hz + 1'b1;
            end

            if (cnt_400Hz == (DIV_400HZ - 1)) begin
                cnt_400Hz  <= {COUNTER_WIDTH{1'b0}};
                tick_400Hz <= 1'b1;
            end else begin
                cnt_400Hz <= cnt_400Hz + 1'b1;
            end
        end
    end

endmodule


// Module 2: rtc_counter
// Maintains HH:MM:SS with base-60/base-24 rollover.
module rtc_counter #(
    parameter integer HOUR_MAX   = 23,
    parameter integer MINUTE_MAX = 59,
    parameter integer SECOND_MAX = 59
)(
    input  wire       clk,
    input  wire       reset,       // Active-high asynchronous reset
    input  wire       tick_1Hz,    // One-cycle time-base enable
    input  wire       LD_time,     // Load override for hour/minute
    input  wire [4:0] set_hour,
    input  wire [5:0] set_minute,
    output reg  [4:0] curr_hour,
    output reg  [5:0] curr_minute,
    output reg  [5:0] curr_second
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            curr_hour   <= 5'd0;
            curr_minute <= 6'd0;
            curr_second <= 6'd0;
        end else if (LD_time) begin
            // Clamp invalid set values to 0 for predictable behavior.
            curr_hour   <= (set_hour   <= HOUR_MAX)   ? set_hour   : 5'd0;
            curr_minute <= (set_minute <= MINUTE_MAX) ? set_minute : 6'd0;
            curr_second <= 6'd0;
        end else if (tick_1Hz) begin
            if (curr_second == SECOND_MAX) begin
                curr_second <= 6'd0;

                if (curr_minute == MINUTE_MAX) begin
                    curr_minute <= 6'd0;

                    if (curr_hour == HOUR_MAX) begin
                        curr_hour <= 5'd0;
                    end else begin
                        curr_hour <= curr_hour + 1'b1;
                    end
                end else begin
                    curr_minute <= curr_minute + 1'b1;
                end
            end else begin
                curr_second <= curr_second + 1'b1;
            end
        end
    end

endmodule


// Module 3: digit_splitter
// Pure combinational binary-to-decimal digit splitter.
module digit_splitter (
    input  wire [4:0] curr_hour,
    input  wire [5:0] curr_minute,
    input  wire [5:0] curr_second,
    output wire [3:0] hour_tens,
    output wire [3:0] hour_ones,
    output wire [3:0] min_tens,
    output wire [3:0] min_ones,
    output wire [3:0] sec_tens,
    output wire [3:0] sec_ones
);

    assign hour_tens = curr_hour / 10;
    assign hour_ones = curr_hour % 10;

    assign min_tens  = curr_minute / 10;
    assign min_ones  = curr_minute % 10;

    assign sec_tens  = curr_second / 10;
    assign sec_ones  = curr_second % 10;

endmodule


// Module 4: seg7_driver
// Multiplexes four BCD digits onto the BASYS 3's 4-digit 7-segment display.
// Uses a 2-bit counter gated by tick_400Hz for digit scanning.
module seg7_driver (
    input  wire       clk,
    input  wire       reset,        // Active-high synchronous reset
    input  wire       tick_400Hz,   // One-cycle enable pulse for digit transition
    input  wire [3:0] digit3,       // Hour Tens  (leftmost digit)
    input  wire [3:0] digit2,       // Hour Ones
    input  wire [3:0] digit1,       // Minute Tens
    input  wire [3:0] digit0,       // Minute Ones (rightmost digit)
    output reg  [3:0] an,           // Active-low anode enables
    output reg  [6:0] seg           // Active-low cathode segments {A,B,C,D,E,F,G}
);

    reg [1:0] digit_sel;            // 2-bit scan counter
    reg [3:0] current_digit;        // MUX output: selected BCD digit

    // ---- 2-bit scan counter (increments on tick_400Hz) ----
    always @(posedge clk or posedge reset) begin
        if (reset)
            digit_sel <= 2'b00;
        else if (tick_400Hz)
            digit_sel <= digit_sel + 1'b1;
    end

    // ---- Digit MUX & active-low anode driver ----
    always @(*) begin
        case (digit_sel)
            2'b00: begin current_digit = digit0; an = 4'b1110; end
            2'b01: begin current_digit = digit1; an = 4'b1101; end
            2'b10: begin current_digit = digit2; an = 4'b1011; end
            2'b11: begin current_digit = digit3; an = 4'b0111; end
            default: begin current_digit = 4'b0000; an = 4'b1111; end
        endcase
    end

    // ---- BCD-to-7-segment decoder (active-low: 0 = LED ON) ----
    //   seg = {A, B, C, D, E, F, G}
    //       A
    //      ---
    //   F |   | B
    //      -G-
    //   E |   | C
    //      ---
    //       D
    always @(*) begin
        case (current_digit)
            4'd0: seg = 7'b000_0001;  // 0
            4'd1: seg = 7'b100_1111;  // 1
            4'd2: seg = 7'b001_0010;  // 2
            4'd3: seg = 7'b000_0110;  // 3
            4'd4: seg = 7'b100_1100;  // 4
            4'd5: seg = 7'b010_0100;  // 5
            4'd6: seg = 7'b010_0000;  // 6
            4'd7: seg = 7'b000_1111;  // 7
            4'd8: seg = 7'b000_0000;  // 8
            4'd9: seg = 7'b000_0100;  // 9
            default: seg = 7'b111_1111; // blank
        endcase
    end

endmodule


// Module 5: top_clock
// Top-level module for the BASYS 3 digital clock.
// Wires clock_divider, rtc_counter, digit_splitter, and seg7_driver together.
module top_clock (
    input  wire        clk,          // 100 MHz system clock
    input  wire        btnC,         // Centre button = reset (active-high)
    input  wire        btnU,         // Up button     = load time
    input  wire [15:0] sw,           // Slide switches
    output wire [3:0]  an,           // 7-seg active-low anodes
    output wire [6:0]  seg           // 7-seg active-low cathodes
);

    // ---------- Internal nets ----------
    wire tick_1Hz;
    wire tick_400Hz;

    wire [4:0] curr_hour;
    wire [5:0] curr_minute;
    wire [5:0] curr_second;

    wire [3:0] hour_tens, hour_ones;
    wire [3:0] min_tens,  min_ones;
    wire [3:0] sec_tens,  sec_ones;   // available but unused on 4-digit display

    // ---------- Module instantiations ----------

    // 1. Clock Divider – produces 1 Hz and 400 Hz enable pulses
    clock_divider u_clk_div (
        .clk       (clk),
        .reset     (btnC),
        .tick_1Hz  (tick_1Hz),
        .tick_400Hz(tick_400Hz)
    );

    // 2. RTC Counter – hours / minutes / seconds
    //    sw[13:10] → set_hour  (zero-extended to 5 bits)
    //    sw[5:0]   → set_minute
    rtc_counter u_rtc (
        .clk        (clk),
        .reset      (btnC),
        .tick_1Hz   (tick_1Hz),
        .LD_time    (btnU),
        .set_hour   ({1'b0, sw[13:10]}),
        .set_minute (sw[5:0]),
        .curr_hour  (curr_hour),
        .curr_minute(curr_minute),
        .curr_second(curr_second)
    );

    // 3. Digit Splitter – binary → BCD digits
    digit_splitter u_splitter (
        .curr_hour  (curr_hour),
        .curr_minute(curr_minute),
        .curr_second(curr_second),
        .hour_tens  (hour_tens),
        .hour_ones  (hour_ones),
        .min_tens   (min_tens),
        .min_ones   (min_ones),
        .sec_tens   (sec_tens),
        .sec_ones   (sec_ones)
    );

    // 4. 7-Segment Driver – display HH:MM
    seg7_driver u_seg7 (
        .clk       (clk),
        .reset     (btnC),
        .tick_400Hz(tick_400Hz),
        .digit3    (hour_tens),   // leftmost
        .digit2    (hour_ones),
        .digit1    (min_tens),
        .digit0    (min_ones),    // rightmost
        .an        (an),
        .seg       (seg)
    );

endmodule


// Module 6: time_loader
// Synchronizes the asynchronous LD_time button, detects its rising edge,
// and converts BCD switch inputs to binary for loading into the RTC.
module time_loader (
    input  wire       clk,
    input  wire       reset,
    input  wire       LD_time,       // Asynchronous button input
    input  wire [1:0] H_in1,         // Hour tens   (BCD: 0-2)
    input  wire [3:0] H_in0,         // Hour ones   (BCD: 0-9)
    input  wire [3:0] M_in1,         // Minute tens  (BCD: 0-5)
    input  wire [3:0] M_in0,         // Minute ones  (BCD: 0-9)
    output reg        load_en,       // 1-cycle pulse on LD_time rising edge
    output reg  [4:0] load_hour,     // Binary hour   (0-23)
    output reg  [5:0] load_min       // Binary minute (0-59)
);

    // ---- 3-stage synchronizer / edge detector ----
    reg sync_0, sync_1, sync_2;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sync_0 <= 1'b0;
            sync_1 <= 1'b0;
            sync_2 <= 1'b0;
        end else begin
            sync_0 <= LD_time;       // 1st FF  - capture metastable input
            sync_1 <= sync_0;        // 2nd FF  - resolve metastability
            sync_2 <= sync_1;        // 3rd FF  - delayed copy for edge detect
        end
    end

    wire ld_edge = sync_1 & ~sync_2; // Rising-edge pulse (1 clk wide)

    // ---- BCD-to-binary conversion & load pulse ----
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            load_en   <= 1'b0;
            load_hour <= 5'd0;
            load_min  <= 6'd0;
        end else begin
            load_en <= 1'b0;          // Default: deassert after 1 cycle
            if (ld_edge) begin
                load_en   <= 1'b1;
                load_hour <= (H_in1 * 4'd10) + {1'b0, H_in0};
                load_min  <= (M_in1 * 4'd10) + {2'b00, M_in0};
            end
        end
    end

endmodule


// Module 7: alarm_memory
// 3-entry SRAM storing binary-packed {Hour[4:0], Minute[5:0]} per slot.
// Writes on the synchronized rising edge of LD_alarm.
module alarm_memory (
    input  wire        clk,
    input  wire        reset,
    input  wire        LD_alarm,      // Asynchronous button input
    input  wire [1:0]  slot_sel,      // Memory slot selector (00, 01, 10)
    input  wire [1:0]  H_in1,         // Hour tens   (BCD: 0-2)
    input  wire [3:0]  H_in0,         // Hour ones   (BCD: 0-9)
    input  wire [3:0]  M_in1,         // Minute tens  (BCD: 0-5)
    input  wire [3:0]  M_in0,         // Minute ones  (BCD: 0-9)
    output wire [10:0] alarm_0,       // Slot 0: {hour[4:0], min[5:0]}
    output wire [10:0] alarm_1,       // Slot 1
    output wire [10:0] alarm_2        // Slot 2
);

    // ---- 3-stage synchronizer / edge detector ----
    reg sync_0, sync_1, sync_2;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sync_0 <= 1'b0;
            sync_1 <= 1'b0;
            sync_2 <= 1'b0;
        end else begin
            sync_0 <= LD_alarm;
            sync_1 <= sync_0;
            sync_2 <= sync_1;
        end
    end

    wire ld_edge = sync_1 & ~sync_2;

    // ---- BCD-to-binary conversion ----
    wire [4:0] bin_hour = (H_in1 * 4'd10) + {1'b0, H_in0};
    wire [5:0] bin_min  = (M_in1 * 4'd10) + {2'b00, M_in0};
    wire [10:0] packed  = {bin_hour, bin_min};

    // ---- 3-entry alarm memory ----
    reg [10:0] alarm_mem [0:2];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            alarm_mem[0] <= 11'd0;
            alarm_mem[1] <= 11'd0;
            alarm_mem[2] <= 11'd0;
        end else if (ld_edge) begin
            case (slot_sel)
                2'b00: alarm_mem[0] <= packed;
                2'b01: alarm_mem[1] <= packed;
                2'b10: alarm_mem[2] <= packed;
                // 2'b11: ignored - protects memory bounds
                default: ;
            endcase
        end
    end

    // ---- Flatten internal array to output ports ----
    assign alarm_0 = alarm_mem[0];
    assign alarm_1 = alarm_mem[1];
    assign alarm_2 = alarm_mem[2];

endmodule
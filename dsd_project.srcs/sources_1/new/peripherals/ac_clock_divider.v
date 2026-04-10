module ac_clock_divider #(
    parameter integer CLK_FREQ_HZ    = 100_000_000,
    parameter integer TICK_1HZ_HZ    = 1,
    parameter integer TICK_SCAN_HZ   = 400,
    parameter integer COUNTER_WIDTH  = 32
)(
    input  wire clk,
    input  wire reset,
    output reg  tick_1hz,
    output reg  tick_scan
);
    localparam integer DIV_1HZ  = CLK_FREQ_HZ / TICK_1HZ_HZ;
    localparam integer DIV_SCAN = CLK_FREQ_HZ / TICK_SCAN_HZ;

    reg [COUNTER_WIDTH-1:0] c1;
    reg [COUNTER_WIDTH-1:0] cscan;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            c1        <= {COUNTER_WIDTH{1'b0}};
            cscan     <= {COUNTER_WIDTH{1'b0}};
            tick_1hz  <= 1'b0;
            tick_scan <= 1'b0;
        end else begin
            tick_1hz  <= 1'b0;
            tick_scan <= 1'b0;

            if (c1 == DIV_1HZ - 1) begin
                c1       <= {COUNTER_WIDTH{1'b0}};
                tick_1hz <= 1'b1;
            end else begin
                c1 <= c1 + 1'b1;
            end

            if (cscan == DIV_SCAN - 1) begin
                cscan     <= {COUNTER_WIDTH{1'b0}};
                tick_scan <= 1'b1;
            end else begin
                cscan <= cscan + 1'b1;
            end
        end
    end
endmodule

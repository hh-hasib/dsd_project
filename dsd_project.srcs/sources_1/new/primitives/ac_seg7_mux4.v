module ac_seg7_mux4 (
    input  wire       clk,
    input  wire       reset,
    input  wire       tick_scan,
    input  wire [3:0] d3,
    input  wire [3:0] d2,
    input  wire [3:0] d1,
    input  wire [3:0] d0,
    output reg  [3:0] an,
    output wire [6:0] seg
);
    reg [1:0] scan_sel;
    reg [3:0] active_digit;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            scan_sel <= 2'd0;
        end else if (tick_scan) begin
            scan_sel <= scan_sel + 1'b1;
        end
    end

    always @(*) begin
        case (scan_sel)
            2'd0: begin active_digit = d0; an = 4'b1110; end
            2'd1: begin active_digit = d1; an = 4'b1101; end
            2'd2: begin active_digit = d2; an = 4'b1011; end
            2'd3: begin active_digit = d3; an = 4'b0111; end
            default: begin active_digit = 4'd0; an = 4'b1111; end
        endcase
    end

    ac_bcd_to_7seg u_bcd (
        .bcd(active_digit),
        .seg(seg)
    );
endmodule

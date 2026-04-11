module ac_seg7_mux4 (
    input  wire       clk,
    input  wire       reset,
    input  wire       tick_scan,
    input  wire [4:0] s3,
    input  wire [4:0] s2,
    input  wire [4:0] s1,
    input  wire [4:0] s0,
    output reg  [3:0] an,
    output wire [6:0] seg
);
    reg [1:0] scan_sel;
    reg [4:0] active_symbol;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            scan_sel <= 2'd0;
        end else if (tick_scan) begin
            scan_sel <= scan_sel + 1'b1;
        end
    end

    always @(*) begin
        case (scan_sel)
            2'd0: begin active_symbol = s0; an = 4'b1110; end
            2'd1: begin active_symbol = s1; an = 4'b1101; end
            2'd2: begin active_symbol = s2; an = 4'b1011; end
            2'd3: begin active_symbol = s3; an = 4'b0111; end
            default: begin active_symbol = 5'd16; an = 4'b1111; end
        endcase
    end

    ac_symbol_to_7seg u_sym (
        .symbol(active_symbol),
        .seg(seg)
    );
endmodule

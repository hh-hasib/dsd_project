module ac_symbol_to_7seg (
    input  wire [4:0] symbol,
    output reg  [6:0] seg
);
    localparam [4:0] SYM_BLANK = 5'd16;
    localparam [4:0] SYM_L     = 5'd17;
    localparam [4:0] SYM_r     = 5'd18;
    localparam [4:0] SYM_M     = 5'd19;
    localparam [4:0] SYM_O     = 5'd20;

    always @(*) begin
        case (symbol)
            5'd0:  seg = 7'b0000001; // 0
            5'd1:  seg = 7'b1001111; // 1
            5'd2:  seg = 7'b0010010; // 2
            5'd3:  seg = 7'b0000110; // 3
            5'd4:  seg = 7'b1001100; // 4
            5'd5:  seg = 7'b0100100; // 5
            5'd6:  seg = 7'b0100000; // 6
            5'd7:  seg = 7'b0001111; // 7
            5'd8:  seg = 7'b0000000; // 8
            5'd9:  seg = 7'b0000100; // 9
            5'd10: seg = 7'b0001000; // A
            5'd11: seg = 7'b1100000; // b
            5'd12: seg = 7'b0110001; // C
            5'd13: seg = 7'b1000010; // d
            5'd14: seg = 7'b0110000; // E
            5'd15: seg = 7'b0111000; // F
            SYM_L: seg = 7'b1110001; // L
            SYM_r: seg = 7'b1111010; // r
            SYM_M: seg = 7'b1001000; // M-like glyph (H-style on 7-seg)
            SYM_O: seg = 7'b0000001; // O
            SYM_BLANK: seg = 7'b1111111;
            default: seg = 7'b1111111;
        endcase
    end
endmodule

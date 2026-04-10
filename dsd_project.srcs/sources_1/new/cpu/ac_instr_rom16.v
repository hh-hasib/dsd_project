module ac_instr_rom16 (
    input  wire [7:0]  addr,
    output reg  [15:0] data
);
    // Opcode map:
    // 0:NOP 1:ADD 2:SUB 3:AND 4:OR 5:XOR 6:ADDI 7:LD 8:ST 9:BEQ A:BNE B:JMP C:HALT D:MOV E:CMP
    always @(*) begin
        case (addr)
            8'h00: data = 16'h6000; // ADDI r0, r0, 0 (NOP-like)
            8'h01: data = 16'hB000; // JMP 0x00
            default: data = 16'hC000; // HALT
        endcase
    end
endmodule

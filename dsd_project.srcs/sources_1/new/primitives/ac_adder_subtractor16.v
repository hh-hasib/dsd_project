module ac_adder_subtractor16 (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire        sub,
    output wire [15:0] result,
    output wire        carry_out
);
    wire [15:0] b_xor;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : GEN_B_XOR
            ac_xor_gate u_xor (
                .a(b[i]),
                .b(sub),
                .y(b_xor[i])
            );
        end
    endgenerate

    ac_ripple_adder16 u_add (
        .a   (a),
        .b   (b_xor),
        .cin (sub),
        .sum (result),
        .cout(carry_out)
    );
endmodule

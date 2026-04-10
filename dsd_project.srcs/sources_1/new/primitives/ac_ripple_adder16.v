module ac_ripple_adder16 (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire        cin,
    output wire [15:0] sum,
    output wire        cout
);
    wire [16:0] c;
    assign c[0] = cin;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : GEN_FA
            ac_full_adder u_fa (
                .a   (a[i]),
                .b   (b[i]),
                .cin (c[i]),
                .sum (sum[i]),
                .cout(c[i+1])
            );
        end
    endgenerate

    assign cout = c[16];
endmodule

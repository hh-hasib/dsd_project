module ac_mux2_16 (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire        sel,
    output wire [15:0] y
);
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : GEN_MUX
            ac_mux2_1 u_mux (
                .a  (a[i]),
                .b  (b[i]),
                .sel(sel),
                .y  (y[i])
            );
        end
    endgenerate
endmodule

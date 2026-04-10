module ac_comparator16 (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire        eq,
    output wire        lt,
    output wire        gt
);
    wire [15:0] diff;
    wire carry_out;

    ac_adder_subtractor16 u_sub (
        .a        (a),
        .b        (b),
        .sub      (1'b1),
        .result   (diff),
        .carry_out(carry_out)
    );

    assign eq = (diff == 16'd0);
    assign lt = ~carry_out;
    assign gt = (~eq) & (~lt);
endmodule

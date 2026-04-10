module ac_half_adder (
    input  wire a,
    input  wire b,
    output wire sum,
    output wire carry
);
    ac_xor_gate u_xor (.a(a), .b(b), .y(sum));
    ac_and_gate u_and (.a(a), .b(b), .y(carry));
endmodule

module ac_full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);
    wire s0;
    wire c0;
    wire c1;

    ac_half_adder u_ha0 (.a(a),  .b(b),   .sum(s0),  .carry(c0));
    ac_half_adder u_ha1 (.a(s0), .b(cin), .sum(sum), .carry(c1));
    ac_or_gate    u_or  (.a(c0), .b(c1),  .y(cout));
endmodule

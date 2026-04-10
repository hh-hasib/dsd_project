module ac_and_gate (
    input  wire a,
    input  wire b,
    output wire y
);
    assign y = a & b;
endmodule

module ac_or_gate (
    input  wire a,
    input  wire b,
    output wire y
);
    assign y = a | b;
endmodule

module ac_xor_gate (
    input  wire a,
    input  wire b,
    output wire y
);
    assign y = a ^ b;
endmodule

module ac_not_gate (
    input  wire a,
    output wire y
);
    assign y = ~a;
endmodule

module ac_mux2_1 (
    input  wire a,
    input  wire b,
    input  wire sel,
    output wire y
);
    wire n_sel;
    wire a_term;
    wire b_term;

    ac_not_gate u_not (.a(sel), .y(n_sel));
    ac_and_gate u_and0 (.a(a), .b(n_sel), .y(a_term));
    ac_and_gate u_and1 (.a(b), .b(sel), .y(b_term));
    ac_or_gate  u_or0  (.a(a_term), .b(b_term), .y(y));
endmodule

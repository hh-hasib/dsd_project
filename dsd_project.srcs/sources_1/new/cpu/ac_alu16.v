module ac_alu16 (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire [3:0]  alu_sel,
    output reg  [15:0] result,
    output wire        carry,
    output wire        zero,
    output wire        lt,
    output wire        gt
);
    wire [15:0] addsub_result;
    wire addsub_carry;
    wire cmp_eq;

    ac_adder_subtractor16 u_addsub (
        .a        (a),
        .b        (b),
        .sub      (alu_sel == 4'h1),
        .result   (addsub_result),
        .carry_out(addsub_carry)
    );

    ac_comparator16 u_cmp (
        .a (a),
        .b (b),
        .eq(cmp_eq),
        .lt(lt),
        .gt(gt)
    );

    always @(*) begin
        case (alu_sel)
            4'h0: result = addsub_result; // ADD
            4'h1: result = addsub_result; // SUB
            4'h2: result = a & b;         // AND
            4'h3: result = a | b;         // OR
            4'h4: result = a ^ b;         // XOR
            4'h5: result = b;             // PASS B
            default: result = 16'd0;
        endcase
    end

    assign carry = addsub_carry;
    assign zero  = (result == 16'd0);
endmodule

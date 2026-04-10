`timescale 1ns/1ps

module tb_ac_ripple_adder16;
    reg  [15:0] a;
    reg  [15:0] b;
    reg         cin;
    wire [15:0] sum;
    wire        cout;

    ac_ripple_adder16 dut (
        .a   (a),
        .b   (b),
        .cin (cin),
        .sum (sum),
        .cout(cout)
    );

    initial begin
        a = 16'h0000; b = 16'h0000; cin = 1'b0; #10;
        if ({cout, sum} !== 17'h00000) $fatal("Adder test 0 failed");

        a = 16'h0001; b = 16'h0001; cin = 1'b0; #10;
        if ({cout, sum} !== 17'h00002) $fatal("Adder test 1 failed");

        a = 16'hFFFF; b = 16'h0001; cin = 1'b0; #10;
        if ({cout, sum} !== 17'h10000) $fatal("Adder carry test failed");

        a = 16'h1234; b = 16'h0101; cin = 1'b1; #10;
        if ({cout, sum} !== 17'h01336) $fatal("Adder random vector failed");

        $display("tb_ac_ripple_adder16 PASSED");
        $finish;
    end
endmodule

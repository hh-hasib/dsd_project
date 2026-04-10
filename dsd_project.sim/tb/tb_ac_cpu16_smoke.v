`timescale 1ns/1ps

module tb_ac_cpu16_smoke;
    reg clk;
    reg reset;

    wire [7:0] instr_addr;
    wire [15:0] instr_data;
    wire [7:0] data_addr;
    wire [15:0] data_wdata;
    wire data_we;
    wire [15:0] data_rdata;
    wire halted;
    wire [3:0] dbg_state;
    wire [7:0] dbg_pc;

    ac_instr_rom16 u_rom (
        .addr(instr_addr),
        .data(instr_data)
    );

    ac_data_ram16 u_ram (
        .clk(clk),
        .we(data_we),
        .addr(data_addr),
        .wdata(data_wdata),
        .rdata(data_rdata)
    );

    ac_cpu16_core u_cpu (
        .clk(clk),
        .reset(reset),
        .instr_addr(instr_addr),
        .instr_data(instr_data),
        .data_addr(data_addr),
        .data_wdata(data_wdata),
        .data_we(data_we),
        .data_rdata(data_rdata),
        .halted(halted),
        .dbg_state(dbg_state),
        .dbg_pc(dbg_pc)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;

        #30;
        reset = 1'b0;

        #400;
        $display("CPU smoke run complete. halted=%0d state=%0d pc=%0d", halted, dbg_state, dbg_pc);
        $finish;
    end
endmodule

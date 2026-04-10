module ac_register_file16 (
    input  wire        clk,
    input  wire        reset,
    input  wire        we,
    input  wire [2:0]  waddr,
    input  wire [15:0] wdata,
    input  wire [2:0]  raddr_a,
    input  wire [2:0]  raddr_b,
    output wire [15:0] rdata_a,
    output wire [15:0] rdata_b
);
    reg [15:0] regs [0:7];
    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 8; i = i + 1) begin
                regs[i] <= 16'd0;
            end
        end else if (we && (waddr != 3'd0)) begin
            regs[waddr] <= wdata;
        end
    end

    assign rdata_a = (raddr_a == 3'd0) ? 16'd0 : regs[raddr_a];
    assign rdata_b = (raddr_b == 3'd0) ? 16'd0 : regs[raddr_b];
endmodule

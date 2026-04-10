module ac_data_ram16 (
    input  wire        clk,
    input  wire        we,
    input  wire [7:0]  addr,
    input  wire [15:0] wdata,
    output wire [15:0] rdata
);
    reg [15:0] mem [0:255];

    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= wdata;
        end
    end

    assign rdata = mem[addr];
endmodule

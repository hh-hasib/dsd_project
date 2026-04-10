module ac_lfsr4 (
    input  wire       clk,
    input  wire       reset,
    input  wire       step_en,
    input  wire [3:0] seed,
    input  wire       load_seed,
    output reg  [3:0] value
);
    wire feedback = value[3] ^ value[2];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            value <= 4'b0001;
        end else if (load_seed) begin
            value <= (seed == 4'b0000) ? 4'b0001 : seed;
        end else if (step_en) begin
            value <= {value[2:0], feedback};
            if (value == 4'b0000) begin
                value <= 4'b0001;
            end
        end
    end
endmodule

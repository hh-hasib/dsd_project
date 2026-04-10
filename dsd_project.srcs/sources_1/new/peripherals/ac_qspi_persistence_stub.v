module ac_qspi_persistence_stub (
    input  wire         clk,
    input  wire         reset,
    input  wire         load_req,
    input  wire         save_req,
    input  wire [109:0] alarms_packed_in,
    output reg  [109:0] alarms_packed_out,
    output reg          busy,
    output reg          done,
    output reg          error
);
    reg [109:0] shadow;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            shadow            <= 110'd0;
            alarms_packed_out <= 110'd0;
            busy              <= 1'b0;
            done              <= 1'b0;
            error             <= 1'b0;
        end else begin
            done  <= 1'b0;
            error <= 1'b0;

            if (save_req) begin
                busy   <= 1'b1;
                shadow <= alarms_packed_in;
                busy   <= 1'b0;
                done   <= 1'b1;
            end else if (load_req) begin
                busy              <= 1'b1;
                alarms_packed_out <= shadow;
                busy              <= 1'b0;
                done              <= 1'b1;
            end
        end
    end
endmodule

module ac_debouncer #(
    parameter integer CNTR_WIDTH = 19
)(
    input  wire clk,
    input  wire reset,
    input  wire noisy_in,
    output reg  clean_out
);
    reg sync_ff0;
    reg sync_ff1;
    reg [CNTR_WIDTH-1:0] stable_counter;
    reg sampled;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sync_ff0       <= 1'b0;
            sync_ff1       <= 1'b0;
            stable_counter <= {CNTR_WIDTH{1'b0}};
            sampled        <= 1'b0;
            clean_out      <= 1'b0;
        end else begin
            sync_ff0 <= noisy_in;
            sync_ff1 <= sync_ff0;

            if (sync_ff1 != sampled) begin
                sampled        <= sync_ff1;
                stable_counter <= {CNTR_WIDTH{1'b0}};
            end else if (&stable_counter == 1'b0) begin
                stable_counter <= stable_counter + 1'b1;
            end

            if (&stable_counter) begin
                clean_out <= sampled;
            end
        end
    end
endmodule

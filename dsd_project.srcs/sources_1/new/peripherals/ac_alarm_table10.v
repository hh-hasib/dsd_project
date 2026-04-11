module ac_alarm_table10 (
    input  wire       clk,
    input  wire       reset,
    input  wire       wr_en,
    input  wire       clr_en,
    input  wire [3:0] slot,
    input  wire [4:0] wr_hour,
    input  wire [5:0] wr_min,
    input  wire [3:0] rd_slot,
    output reg  [4:0] rd_hour,
    output reg  [5:0] rd_min,
    output reg        rd_valid,
    input  wire       match_en,
    input  wire [4:0] curr_hour,
    input  wire [5:0] curr_min,
    output reg        match_found,
    output reg  [3:0] match_slot,
    input  wire       chk_en,
    input  wire [4:0] chk_hour,
    input  wire [5:0] chk_min,
    input  wire [3:0] chk_exclude_slot,
    output reg        chk_duplicate,
    output wire [9:0] valid_bitmap
);
    reg [4:0] alarm_hour [0:9];
    reg [5:0] alarm_min  [0:9];
    reg       alarm_valid[0:9];

    integer i;
    reg found_local;
    reg [3:0] slot_local;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 10; i = i + 1) begin
                alarm_hour[i]  <= 5'd0;
                alarm_min[i]   <= 6'd0;
                alarm_valid[i] <= 1'b0;
            end
        end else begin
            if (wr_en && (slot < 4'd10)) begin
                alarm_hour[slot]  <= (wr_hour <= 5'd23) ? wr_hour : 5'd0;
                alarm_min[slot]   <= (wr_min  <= 6'd59) ? wr_min  : 6'd0;
                alarm_valid[slot] <= 1'b1;
            end
            if (clr_en && (slot < 4'd10)) begin
                alarm_valid[slot] <= 1'b0;
            end
        end
    end

    always @(*) begin
        if (rd_slot < 4'd10) begin
            rd_hour  = alarm_hour[rd_slot];
            rd_min   = alarm_min[rd_slot];
            rd_valid = alarm_valid[rd_slot];
        end else begin
            rd_hour  = 5'd0;
            rd_min   = 6'd0;
            rd_valid = 1'b0;
        end
    end

    always @(*) begin
        found_local = 1'b0;
        slot_local  = 4'd0;
        if (match_en) begin
            for (i = 0; i < 10; i = i + 1) begin
                if (!found_local && alarm_valid[i] && (alarm_hour[i] == curr_hour) && (alarm_min[i] == curr_min)) begin
                    found_local = 1'b1;
                    slot_local  = i[3:0];
                end
            end
        end
        match_found = found_local;
        match_slot  = slot_local;
    end

    always @(*) begin
        chk_duplicate = 1'b0;
        if (chk_en) begin
            for (i = 0; i < 10; i = i + 1) begin
                if ((i[3:0] != chk_exclude_slot) && alarm_valid[i] && (alarm_hour[i] == chk_hour) && (alarm_min[i] == chk_min)) begin
                    chk_duplicate = 1'b1;
                end
            end
        end
    end

    assign valid_bitmap = {
        alarm_valid[9], alarm_valid[8], alarm_valid[7], alarm_valid[6], alarm_valid[5],
        alarm_valid[4], alarm_valid[3], alarm_valid[2], alarm_valid[1], alarm_valid[0]
    };
endmodule

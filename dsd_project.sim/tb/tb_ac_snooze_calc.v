`timescale 1ns/1ps

module tb_ac_snooze_calc;
    reg  [4:0] curr_hour;
    reg  [5:0] curr_min;
    reg        plus_ten;
    wire [4:0] new_hour;
    wire [5:0] new_min;

    integer errors;

    ac_snooze_calc dut (
        .curr_hour(curr_hour),
        .curr_min (curr_min),
        .plus_ten (plus_ten),
        .new_hour (new_hour),
        .new_min  (new_min)
    );

    task expect_time;
        input [4:0] exp_h;
        input [5:0] exp_m;
        begin
            #1;
            if ((new_hour !== exp_h) || (new_min !== exp_m)) begin
                $display("[FAIL] plus_ten=%0d in=%0d:%0d out=%0d:%0d expected=%0d:%0d",
                         plus_ten, curr_hour, curr_min, new_hour, new_min, exp_h, exp_m);
                errors = errors + 1;
            end else begin
                $display("[PASS] plus_ten=%0d in=%0d:%0d out=%0d:%0d",
                         plus_ten, curr_hour, curr_min, new_hour, new_min);
            end
        end
    endtask

    initial begin
        errors = 0;

        // +5 minute cases
        plus_ten = 1'b0;
        curr_hour = 5'd10; curr_min = 6'd20; expect_time(5'd10, 6'd25);
        curr_hour = 5'd10; curr_min = 6'd55; expect_time(5'd11, 6'd0);
        curr_hour = 5'd23; curr_min = 6'd58; expect_time(5'd0,  6'd3);

        // +10 minute cases
        plus_ten = 1'b1;
        curr_hour = 5'd8;  curr_min = 6'd4;  expect_time(5'd8,  6'd14);
        curr_hour = 5'd8;  curr_min = 6'd54; expect_time(5'd9,  6'd4);
        curr_hour = 5'd23; curr_min = 6'd55; expect_time(5'd0,  6'd5);

        if (errors == 0) begin
            $display("tb_ac_snooze_calc: PASS");
        end else begin
            $display("tb_ac_snooze_calc: FAIL (%0d errors)", errors);
            $fatal(1);
        end

        $finish;
    end
endmodule

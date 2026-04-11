`timescale 1ns/1ps

module tb_ac_mode_manager_6mode;
    localparam integer DB_CYCLES = 524300;

    reg clk;
    reg reset;

    reg btn_mode;
    reg btn_confirm;
    reg btn_hour_up;
    reg btn_min_up;
    reg btn_field_sel;

    reg force_mode_en;
    reg [2:0] force_mode;

    wire [2:0] mode;
    wire pulse_mode;
    wire pulse_confirm;
    wire pulse_hour_up;
    wire pulse_min_up;
    wire pulse_field_sel;

    integer errors;

    ac_mode_manager dut (
        .clk            (clk),
        .reset          (reset),
        .btn_mode       (btn_mode),
        .btn_confirm    (btn_confirm),
        .btn_hour_up    (btn_hour_up),
        .btn_min_up     (btn_min_up),
        .btn_field_sel  (btn_field_sel),
        .force_mode_en  (force_mode_en),
        .force_mode     (force_mode),
        .mode           (mode),
        .pulse_mode     (pulse_mode),
        .pulse_confirm  (pulse_confirm),
        .pulse_hour_up  (pulse_hour_up),
        .pulse_min_up   (pulse_min_up),
        .pulse_field_sel(pulse_field_sel)
    );

    always #5 clk = ~clk;

    task press_mode_button;
        begin
            btn_mode = 1'b1;
            repeat (DB_CYCLES) @(posedge clk);
            btn_mode = 1'b0;
            repeat (DB_CYCLES) @(posedge clk);
        end
    endtask

    task expect_mode;
        input [2:0] exp_mode;
        input [255:0] note;
        begin
            if (mode !== exp_mode) begin
                $display("[FAIL] %0s expected mode=%0d got=%0d", note, exp_mode, mode);
                errors = errors + 1;
            end else begin
                $display("[PASS] %0s mode=%0d", note, mode);
            end
        end
    endtask

    task force_to;
        input [2:0] to_mode;
        begin
            force_mode    = to_mode;
            force_mode_en = 1'b1;
            @(posedge clk);
            force_mode_en = 1'b0;
            @(posedge clk);
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        btn_mode = 1'b0;
        btn_confirm = 1'b0;
        btn_hour_up = 1'b0;
        btn_min_up = 1'b0;
        btn_field_sel = 1'b0;
        force_mode_en = 1'b0;
        force_mode = 3'd0;
        errors = 0;

        repeat (5) @(posedge clk);
        reset = 1'b0;
        repeat (5) @(posedge clk);

        expect_mode(3'd0, "reset state");

        // Validate constrained cycle 0 -> 1 -> 3 -> 0 via mode button.
        press_mode_button();
        expect_mode(3'd1, "cycle step 0->1");

        press_mode_button();
        expect_mode(3'd3, "cycle step 1->3");

        press_mode_button();
        expect_mode(3'd0, "cycle step 3->0");

        // Mode 2 should hold on mode button presses.
        force_to(3'd2);
        expect_mode(3'd2, "force enter mode 2");
        press_mode_button();
        expect_mode(3'd2, "mode 2 ignores mode button");

        // Mode 4 should also hold on mode button presses.
        force_to(3'd4);
        expect_mode(3'd4, "force enter mode 4");
        press_mode_button();
        expect_mode(3'd4, "mode 4 ignores mode button");

        // Force override should always work.
        force_to(3'd5);
        expect_mode(3'd5, "force enter mode 5");

        force_to(3'd0);
        expect_mode(3'd0, "force return mode 0");

        if (errors == 0) begin
            $display("tb_ac_mode_manager_6mode: PASS");
        end else begin
            $display("tb_ac_mode_manager_6mode: FAIL (%0d errors)", errors);
            $fatal(1);
        end

        $finish;
    end
endmodule

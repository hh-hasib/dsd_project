module ac_snooze_calc (
    input  wire [4:0] curr_hour,
    input  wire [5:0] curr_min,
    input  wire       plus_ten,
    output wire [4:0] new_hour,
    output wire [5:0] new_min
);
    wire [15:0] minute_in = {10'd0, curr_min};
    wire [15:0] addend    = plus_ten ? 16'd10 : 16'd5;

    wire [15:0] minute_sum;
    wire minute_sum_cout;

    wire min_eq_60;
    wire min_lt_60;
    wire min_gt_60;

    wire [15:0] minute_minus_60;
    wire minute_minus_60_cout;

    wire [15:0] hour_plus_carry;
    wire hour_plus_carry_cout;

    wire hour_eq_24;
    wire hour_lt_24;
    wire hour_gt_24;

    wire [15:0] hour_minus_24;
    wire hour_minus_24_cout;

    wire minute_wrap = min_eq_60 | min_gt_60;
    wire [15:0] minute_norm = minute_wrap ? minute_minus_60 : minute_sum;

    wire [15:0] hour_in  = {11'd0, curr_hour};
    wire [15:0] hour_inc = minute_wrap ? 16'd1 : 16'd0;
    wire [15:0] hour_raw = hour_plus_carry;
    wire hour_wrap = hour_eq_24 | hour_gt_24;
    wire [15:0] hour_norm = hour_wrap ? hour_minus_24 : hour_raw;

    ac_adder_subtractor16 u_min_add (
        .a        (minute_in),
        .b        (addend),
        .sub      (1'b0),
        .result   (minute_sum),
        .carry_out(minute_sum_cout)
    );

    ac_comparator16 u_min_cmp_60 (
        .a (minute_sum),
        .b (16'd60),
        .eq(min_eq_60),
        .lt(min_lt_60),
        .gt(min_gt_60)
    );

    ac_adder_subtractor16 u_min_sub_60 (
        .a        (minute_sum),
        .b        (16'd60),
        .sub      (1'b1),
        .result   (minute_minus_60),
        .carry_out(minute_minus_60_cout)
    );

    ac_adder_subtractor16 u_hour_add (
        .a        (hour_in),
        .b        (hour_inc),
        .sub      (1'b0),
        .result   (hour_plus_carry),
        .carry_out(hour_plus_carry_cout)
    );

    ac_comparator16 u_hour_cmp_24 (
        .a (hour_raw),
        .b (16'd24),
        .eq(hour_eq_24),
        .lt(hour_lt_24),
        .gt(hour_gt_24)
    );

    ac_adder_subtractor16 u_hour_sub_24 (
        .a        (hour_raw),
        .b        (16'd24),
        .sub      (1'b1),
        .result   (hour_minus_24),
        .carry_out(hour_minus_24_cout)
    );

    assign new_min  = minute_norm[5:0];
    assign new_hour = hour_norm[4:0];
endmodule

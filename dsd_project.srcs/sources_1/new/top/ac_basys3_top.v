module ac_basys3_top (
    input  wire        clk,
    input  wire [15:0] sw,
    input  wire        btnU,
    input  wire        btnD,
    input  wire        btnL,
    input  wire        btnR,
    input  wire        btnC,
    output wire [15:0] led,
    output wire [3:0]  an,
    output wire [6:0]  seg
);
    // Mapping chosen for this implementation start:
    // sw[15]  -> system reset
    // btnU    -> mode cycle
    // btnR    -> confirm/accept
    // btnL    -> hour increment
    // btnD    -> minute increment
    // btnC    -> field select

    ac_alarm_clock_soc_top u_soc (
        .clk          (clk),
        .reset_sw     (sw[15]),
        .sw           (sw),
        .btn_mode     (btnU),
        .btn_confirm  (btnR),
        .btn_hour_up  (btnL),
        .btn_min_up   (btnD),
        .btn_field_sel(btnC),
        .led          (led),
        .an           (an),
        .seg          (seg)
    );
endmodule

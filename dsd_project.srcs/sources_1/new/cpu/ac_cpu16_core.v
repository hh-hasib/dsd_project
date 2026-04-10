module ac_cpu16_core (
    input  wire        clk,
    input  wire        reset,
    output reg  [7:0]  instr_addr,
    input  wire [15:0] instr_data,
    output reg  [7:0]  data_addr,
    output reg  [15:0] data_wdata,
    output reg         data_we,
    input  wire [15:0] data_rdata,
    output reg         halted,
    output reg  [3:0]  dbg_state,
    output reg  [7:0]  dbg_pc
);
    localparam [3:0] OP_NOP  = 4'h0;
    localparam [3:0] OP_ADD  = 4'h1;
    localparam [3:0] OP_SUB  = 4'h2;
    localparam [3:0] OP_AND  = 4'h3;
    localparam [3:0] OP_OR   = 4'h4;
    localparam [3:0] OP_XOR  = 4'h5;
    localparam [3:0] OP_ADDI = 4'h6;
    localparam [3:0] OP_LD   = 4'h7;
    localparam [3:0] OP_ST   = 4'h8;
    localparam [3:0] OP_BEQ  = 4'h9;
    localparam [3:0] OP_BNE  = 4'hA;
    localparam [3:0] OP_JMP  = 4'hB;
    localparam [3:0] OP_HALT = 4'hC;
    localparam [3:0] OP_MOV  = 4'hD;
    localparam [3:0] OP_CMP  = 4'hE;

    localparam [3:0] ST_FETCH  = 4'd0;
    localparam [3:0] ST_DECODE = 4'd1;
    localparam [3:0] ST_EXEC   = 4'd2;
    localparam [3:0] ST_MEM    = 4'd3;
    localparam [3:0] ST_WB     = 4'd4;
    localparam [3:0] ST_HALT   = 4'd5;

    reg [3:0]  state;
    reg [7:0]  pc;
    reg [15:0] ir;
    reg [15:0] wb_data;
    reg [2:0]  wb_addr;
    reg        wb_en;

    reg        flag_zero;
    reg        flag_carry;
    reg        flag_lt;

    wire [3:0] opcode = ir[15:12];
    wire [2:0] rd     = ir[11:9];
    wire [2:0] rs     = ir[8:6];
    wire [2:0] rt     = ir[5:3];
    wire [5:0] imm6   = ir[5:0];
    wire [7:0] imm8_sx = {{2{imm6[5]}}, imm6};

    reg [3:0] alu_sel;
    reg [15:0] alu_a;
    reg [15:0] alu_b;

    wire [15:0] rf_rs_data;
    wire [15:0] rf_rt_data;
    wire [15:0] alu_result;
    wire alu_carry;
    wire alu_zero;
    wire alu_lt;
    wire alu_gt;

    ac_register_file16 u_rf (
        .clk    (clk),
        .reset  (reset),
        .we     (wb_en),
        .waddr  (wb_addr),
        .wdata  (wb_data),
        .raddr_a(rs),
        .raddr_b(rt),
        .rdata_a(rf_rs_data),
        .rdata_b(rf_rt_data)
    );

    ac_alu16 u_alu (
        .a      (alu_a),
        .b      (alu_b),
        .alu_sel(alu_sel),
        .result (alu_result),
        .carry  (alu_carry),
        .zero   (alu_zero),
        .lt     (alu_lt),
        .gt     (alu_gt)
    );

    always @(*) begin
        alu_a   = rf_rs_data;
        alu_b   = rf_rt_data;
        alu_sel = 4'h0;

        case (opcode)
            OP_ADD:  begin alu_sel = 4'h0; alu_b = rf_rt_data; end
            OP_SUB:  begin alu_sel = 4'h1; alu_b = rf_rt_data; end
            OP_AND:  begin alu_sel = 4'h2; alu_b = rf_rt_data; end
            OP_OR:   begin alu_sel = 4'h3; alu_b = rf_rt_data; end
            OP_XOR:  begin alu_sel = 4'h4; alu_b = rf_rt_data; end
            OP_ADDI: begin alu_sel = 4'h0; alu_b = {{10{imm6[5]}}, imm6}; end
            OP_MOV:  begin alu_sel = 4'h5; alu_b = rf_rs_data; end
            OP_CMP:  begin alu_sel = 4'h1; alu_b = rf_rt_data; end
            default: begin alu_sel = 4'h0; alu_b = rf_rt_data; end
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state      <= ST_FETCH;
            pc         <= 8'd0;
            ir         <= 16'd0;
            instr_addr <= 8'd0;
            data_addr  <= 8'd0;
            data_wdata <= 16'd0;
            data_we    <= 1'b0;
            halted     <= 1'b0;
            wb_en      <= 1'b0;
            wb_addr    <= 3'd0;
            wb_data    <= 16'd0;
            flag_zero  <= 1'b0;
            flag_carry <= 1'b0;
            flag_lt    <= 1'b0;
            dbg_state  <= ST_FETCH;
            dbg_pc     <= 8'd0;
        end else begin
            data_we <= 1'b0;
            wb_en   <= 1'b0;

            case (state)
                ST_FETCH: begin
                    instr_addr <= pc;
                    ir         <= instr_data;
                    pc         <= pc + 1'b1;
                    state      <= ST_DECODE;
                end

                ST_DECODE: begin
                    state <= ST_EXEC;
                end

                ST_EXEC: begin
                    case (opcode)
                        OP_NOP: begin
                            state <= ST_FETCH;
                        end

                        OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR, OP_ADDI, OP_MOV: begin
                            wb_en      <= 1'b1;
                            wb_addr    <= rd;
                            wb_data    <= alu_result;
                            flag_zero  <= alu_zero;
                            flag_carry <= alu_carry;
                            flag_lt    <= alu_lt;
                            state      <= ST_FETCH;
                        end

                        OP_CMP: begin
                            flag_zero  <= alu_zero;
                            flag_carry <= alu_carry;
                            flag_lt    <= alu_lt;
                            state      <= ST_FETCH;
                        end

                        OP_LD: begin
                            data_addr <= rf_rs_data[7:0] + imm8_sx;
                            state     <= ST_MEM;
                        end

                        OP_ST: begin
                            data_addr  <= rf_rs_data[7:0] + imm8_sx;
                            data_wdata <= rf_rt_data;
                            data_we    <= 1'b1;
                            state      <= ST_FETCH;
                        end

                        OP_BEQ: begin
                            if (rf_rs_data == rf_rt_data) begin
                                pc <= pc + imm8_sx;
                            end
                            state <= ST_FETCH;
                        end

                        OP_BNE: begin
                            if (rf_rs_data != rf_rt_data) begin
                                pc <= pc + imm8_sx;
                            end
                            state <= ST_FETCH;
                        end

                        OP_JMP: begin
                            pc    <= ir[7:0];
                            state <= ST_FETCH;
                        end

                        OP_HALT: begin
                            halted <= 1'b1;
                            state  <= ST_HALT;
                        end

                        default: begin
                            state <= ST_FETCH;
                        end
                    endcase
                end

                ST_MEM: begin
                    state <= ST_WB;
                end

                ST_WB: begin
                    if (opcode == OP_LD) begin
                        wb_en   <= 1'b1;
                        wb_addr <= rd;
                        wb_data <= data_rdata;
                    end
                    state <= ST_FETCH;
                end

                ST_HALT: begin
                    state <= ST_HALT;
                end

                default: begin
                    state <= ST_FETCH;
                end
            endcase

            dbg_state <= state;
            dbg_pc    <= pc;
        end
    end
endmodule

module Program(input clk, INF.Program_inf inf);
import usertype::*;

typedef enum logic [2:0]{
            IDLE,
            INDEX_CHECK,
            UPDATE,
            CHECK_DATE,
            READ_DRAM,
            WRITE_DRAM,
            COMPUTE,
            OUT_DATE_WARN
        } state_t;

state_t cs, ns;
Data_Dir data_dir;
Order_Info order_info;
logic [1:0]  action_reg;
logic [1:0]  read_cnt; 
logic [11:0] threshold;
logic [12:0] add_L10, add_L11;
logic [13:0] add_L2, add3;
logic [11:0] comp_L00, comp_L01, comp_L02, comp_L03;
logic [11:0] comp_L10, comp_L11, comp_L12, comp_L13;
logic [11:0] comp_L20, comp_L21, comp_L22, comp_L23;
logic        comp_cond0, comp_cond1, comp_cond2, comp_cond3;
logic [2:0]  comp_add;
logic [4:0]  compute_cnt;
logic        date_warn_flag;
logic [63:0] in_buf;

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        inf.AR_VALID <= 0;
    else if (inf.data_no_valid)
        inf.AR_VALID <= 1;
    else if (inf.AR_READY)
        inf.AR_VALID <= 0;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        inf.AW_VALID <= 0;
    else if (inf.data_no_valid)
        inf.AW_VALID <= 1;
    else if (inf.AW_READY)
        inf.AW_VALID <= 0;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.W_VALID <= 0;
        inf.B_READY <= 0;
    end
    else if(cs == WRITE_DRAM && compute_cnt[0]) begin
        inf.W_VALID <= 1;
        inf.B_READY <= 1;
    end
    else begin
        inf.W_VALID <= 0;
        inf.B_READY <= 0;
    end
end

always_comb begin
    if (inf.W_VALID) begin
        inf.W_DATA[63:52] = data_dir.Index_A;
        inf.W_DATA[51:40] = data_dir.Index_B;
        inf.W_DATA[31:20] = data_dir.Index_C;
        inf.W_DATA[19:8] = data_dir.Index_D;
        inf.W_DATA[39:32] = data_dir.M;
        inf.W_DATA[7:0] = data_dir.D;
    end
    else
        inf.W_DATA = 0;
end

always_comb
    inf.R_READY = cs == READ_DRAM;

always_comb
    inf.AW_ADDR = inf.AR_ADDR;

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        read_cnt <= 0;
    else begin
        if (inf.index_valid) begin
            read_cnt <= read_cnt + 1;
        end
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        compute_cnt <= 0;
    else begin
        case (cs)
            COMPUTE: compute_cnt <= compute_cnt + 1;
            WRITE_DRAM: compute_cnt <= 1;
            default: compute_cnt <= 0;
        endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        cs <= IDLE;
    end
    else begin
        cs <= ns;
    end
end

always_comb begin
    date_warn_flag = (in_buf[39:32] > data_dir.M) || ((in_buf[39:32] == data_dir.M) && (in_buf[7:0] > data_dir.D));
end

always_comb begin
    case (cs)
        IDLE: begin
            if (inf.sel_action_valid) begin
                case (inf.D.d_act[0])
                    Index_Check: ns = INDEX_CHECK;
                    Update: ns = UPDATE;
                    Check_Valid_Date: ns = CHECK_DATE;
                    default: ns = IDLE;
                endcase
            end
            else
                ns = IDLE;
        end
        INDEX_CHECK: ns = (read_cnt == 2'd3 && inf.index_valid)? READ_DRAM : INDEX_CHECK;
        UPDATE: ns = (read_cnt == 2'd3 && inf.index_valid)? READ_DRAM : UPDATE;
        CHECK_DATE: ns = (inf.data_no_valid)? READ_DRAM : CHECK_DATE;
        READ_DRAM: begin
            if (inf.R_VALID) begin
                case (action_reg)
                    Index_Check: ns = COMPUTE;
                    Update: ns = WRITE_DRAM;
                    Check_Valid_Date: ns = OUT_DATE_WARN;
                    default: ns = READ_DRAM;
                endcase
            end
            else
                ns = READ_DRAM;
        end
        COMPUTE: begin
            if (date_warn_flag || action_reg == 2'd2)
                ns = OUT_DATE_WARN;
            else begin
                case (order_info.Formula_Type_O)
                    Formula_A, Formula_B, Formula_C: ns = (compute_cnt == 2)? IDLE : COMPUTE;
                    Formula_D, Formula_E: ns = (compute_cnt == 1)? IDLE : COMPUTE;
                    Formula_F: ns = (compute_cnt == 5)? IDLE : COMPUTE;
                    Formula_G: ns = (compute_cnt == 5)? IDLE : COMPUTE;
                    Formula_H: ns = (compute_cnt == 3)? IDLE : COMPUTE;
                    default: ns = COMPUTE; 
                endcase
            end
        end
        WRITE_DRAM: begin
            if (inf.B_VALID)
                ns = IDLE;
            else
                ns = WRITE_DRAM;
        end
        default: ns = IDLE; 
    endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        action_reg <= 0;
        order_info.Formula_Type_O <= 0;
        order_info.Mode_O <= 0;
        {data_dir.M, data_dir.D} <= 0;
        inf.AR_ADDR <= 0;
    end
    else begin
        action_reg <= (inf.sel_action_valid)? inf.D.d_act[0] : action_reg;
        case (cs)
            INDEX_CHECK: begin
                if (inf.formula_valid)
                    order_info.Formula_Type_O <= inf.D.d_formula[0];
                if (inf.mode_valid)
                    order_info.Mode_O <= inf.D.d_mode[0];
                if (inf.date_valid) 
                    {data_dir.M, data_dir.D} <= inf.D.d_date[0];
                if (inf.data_no_valid)
                    inf.AR_ADDR <= {1'd1, 5'd0, inf.D.d_data_no[0], 3'd0};
            end 
            UPDATE: begin
                if (inf.date_valid) 
                    {data_dir.M, data_dir.D} <= inf.D.d_date[0];
                if (inf.data_no_valid)
                    inf.AR_ADDR <= {1'd1, 5'd0, inf.D.d_data_no[0], 3'd0};
            end
            CHECK_DATE: begin
                if (inf.date_valid) 
                    {data_dir.M, data_dir.D} <= inf.D.d_date[0];
                if (inf.data_no_valid)
                    inf.AR_ADDR <= {1'd1, 5'd0, inf.D.d_data_no[0], 3'd0};
            end
        endcase
    end
end

always_ff @(posedge clk) begin
    if (cs == COMPUTE && !compute_cnt) begin
        in_buf[63:52] <= (data_dir.Index_A >= in_buf[63:52])? data_dir.Index_A - in_buf[63:52] : in_buf[63:52] - data_dir.Index_A;
        in_buf[51:40] <= (data_dir.Index_B >= in_buf[51:40])? data_dir.Index_B - in_buf[51:40] : in_buf[51:40] - data_dir.Index_B;
        in_buf[31:20] <= (data_dir.Index_C >= in_buf[31:20])? data_dir.Index_C - in_buf[31:20] : in_buf[31:20] - data_dir.Index_C;
        in_buf[19:8] <= (data_dir.Index_D >= in_buf[19:8])? data_dir.Index_D - in_buf[19:8] : in_buf[19:8] - data_dir.Index_D;
    end
    else if (inf.R_VALID)
        in_buf <= inf.R_DATA;
end

logic [12:0] sign_sumA, sign_sumB, sign_sumC, sign_sumD;
always_comb begin
    sign_sumA = in_buf[63:52] + {data_dir.Index_A[11], data_dir.Index_A};
    sign_sumB = in_buf[51:40] + {data_dir.Index_B[11], data_dir.Index_B};
    sign_sumC = in_buf[31:20] + {data_dir.Index_C[11], data_dir.Index_C};
    sign_sumD = in_buf[19:8] + {data_dir.Index_D[11], data_dir.Index_D};
end

always_ff @(posedge clk) begin
    if (cs == WRITE_DRAM && !compute_cnt) begin
        case (sign_sumA[12:11])
            2'b10: data_dir.Index_A <= 4095;
            2'b11: data_dir.Index_A <= 0;
            default: data_dir.Index_A <= sign_sumA[11:0];
        endcase
        case (sign_sumB[12:11])
            2'b10: data_dir.Index_B <= 4095;
            2'b11: data_dir.Index_B <= 0;
            default: data_dir.Index_B <= sign_sumB[11:0];
        endcase
        case (sign_sumC[12:11])
            2'b10: data_dir.Index_C <= 4095;
            2'b11: data_dir.Index_C <= 0;
            default: data_dir.Index_C <= sign_sumC[11:0];
        endcase
        case (sign_sumD[12:11])
            2'b10: data_dir.Index_D <= 4095;
            2'b11: data_dir.Index_D <= 0;
            default: data_dir.Index_D <= sign_sumD[11:0];
        endcase
    end
    else if (inf.index_valid) begin
        case (read_cnt)
            2'd0: data_dir.Index_A <= inf.D.d_index[0];
            2'd1: data_dir.Index_B <= inf.D.d_index[0];
            2'd2: data_dir.Index_C <= inf.D.d_index[0];
            2'd3: data_dir.Index_D <= inf.D.d_index[0];
        endcase
    end
end

always_ff @(posedge clk) begin
    case (order_info.Formula_Type_O)
        Formula_F: add_L10 <= comp_L21 + comp_L22;
        Formula_G: add_L10 <= comp_L21[11:2] + comp_L22[11:2];
        default: add_L10 <= in_buf[63:52] + in_buf[51:40];
    endcase
    add_L11 <= in_buf[31:20] + in_buf[19:8];
    add_L2 <= (order_info.Formula_Type_O == 3'd6)? (add_L10 + comp_L23[11:1]) : (add_L10 + add_L11);
end

always_comb begin
    comp_L00 = in_buf[63:52];
    comp_L01 = in_buf[51:40];
    comp_L02 = in_buf[31:20];
    comp_L03 = in_buf[19:8];
end

always_ff @(posedge clk) begin
    {comp_L10, comp_L11} <= (comp_L00 >= comp_L01)? {comp_L00, comp_L01} : {comp_L01, comp_L00};
    {comp_L12, comp_L13} <= (comp_L02 >= comp_L03)? {comp_L02, comp_L03} : {comp_L03, comp_L02};
    {comp_L20, comp_L21} <= (comp_L10 >= comp_L12)? {comp_L10, comp_L12} : {comp_L12, comp_L10};
    {comp_L22, comp_L23} <= (comp_L11 >= comp_L13)? {comp_L11, comp_L13} : {comp_L13, comp_L11};
end

always_ff @(posedge clk) begin
    comp_cond0 <= in_buf[63:52] >= ((order_info.Formula_Type_O[2])? data_dir.Index_A : 2047);
    comp_cond1 <= in_buf[51:40] >= ((order_info.Formula_Type_O[2])? data_dir.Index_B : 2047);
    comp_cond2 <= in_buf[31:20] >= ((order_info.Formula_Type_O[2])? data_dir.Index_C : 2047);
    comp_cond3 <= in_buf[19:8] >= ((order_info.Formula_Type_O[2])? data_dir.Index_D : 2047);
end

always_comb begin
    comp_add = comp_cond0 + comp_cond1 + comp_cond2 + comp_cond3;
end

logic [13:0] dividend;
always_ff @(posedge clk)
    dividend <= add_L10 + comp_L23;

always_comb begin
    case ({order_info.Formula_Type_O, order_info.Mode_O})
        {Formula_A, Insensitive}: threshold = 2047;
        {Formula_A, Normal}:      threshold = 1023;
        {Formula_A, Sensitive}:   threshold = 511;
        {Formula_B, Insensitive}: threshold = 800;
        {Formula_B, Normal}:      threshold = 400;
        {Formula_B, Sensitive}:   threshold = 200;
        {Formula_C, Insensitive}: threshold = 2047;
        {Formula_C, Normal}:      threshold = 1023;
        {Formula_C, Sensitive}:   threshold = 511;
        {Formula_D, Insensitive}: threshold = 3;
        {Formula_D, Normal}:      threshold = 2;
        {Formula_D, Sensitive}:   threshold = 1;
        {Formula_E, Insensitive}: threshold = 3;
        {Formula_E, Normal}:      threshold = 2;
        {Formula_E, Sensitive}:   threshold = 1;
        {Formula_F, Insensitive}: threshold = 2400;
        {Formula_F, Normal}:      threshold = 1200;
        {Formula_F, Sensitive}:   threshold = 600;
        {Formula_G, Insensitive}: threshold = 800;
        {Formula_G, Normal}:      threshold = 400;
        {Formula_G, Sensitive}:   threshold = 200;
        {Formula_H, Insensitive}: threshold = 800;
        {Formula_H, Normal}:      threshold = 400;
        {Formula_H, Sensitive}:   threshold = 200;
        default: threshold = 0;
    endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.out_valid <= 0;
        inf.warn_msg <= 0;
        inf.complete <= 0;
    end
    else begin
        case (cs)
            IDLE: {inf.out_valid, inf.warn_msg, inf.complete} <= 0;
            OUT_DATE_WARN: {inf.out_valid, inf.warn_msg, inf.complete} <= (date_warn_flag)? {1'd1, 2'd1, 1'd0} : {1'd1, 2'd0, 1'd1};
            COMPUTE: begin
                inf.out_valid <= ns == IDLE;
                case (order_info.Formula_Type_O)
                    Formula_A: {inf.warn_msg, inf.complete} <= (add_L2[13:2] >= threshold)? 3'd4 : 3'd1;
                    Formula_B: {inf.warn_msg, inf.complete} <= ((comp_L20 - comp_L23) >= threshold)? 3'd4 : 3'd1;
                    Formula_C: {inf.warn_msg, inf.complete} <= (comp_L23 >= threshold)? 3'd4 : 3'd1;
                    Formula_D: {inf.warn_msg, inf.complete} <= (comp_add >= threshold)? 3'd4 : 3'd1;
                    Formula_E: {inf.warn_msg, inf.complete} <= (comp_add >= threshold)? 3'd4 : 3'd1;
                    Formula_F: {inf.warn_msg, inf.complete} <= (dividend >= threshold)? 3'd4 : 3'd1;
                    Formula_G: {inf.warn_msg, inf.complete} <= (add_L2[11:0] >= threshold)? 3'd4 : 3'd1;
                    Formula_H: {inf.warn_msg, inf.complete} <= (add_L2[13:2] >= threshold)? 3'd4 : 3'd1;
                endcase
            end
            WRITE_DRAM: begin
                inf.out_valid <= ns == IDLE;
                if (!compute_cnt) begin
                    {inf.warn_msg, inf.complete} <= (sign_sumA[12] || sign_sumB[12] || sign_sumC[12] || sign_sumD[12])? 3'd6 : 3'd1;
                end
            end
        endcase
    end
end

endmodule

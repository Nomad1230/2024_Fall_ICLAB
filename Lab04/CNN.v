//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Convolution Neural Network 
//   Author     		: Yu-Chi Lin (a6121461214.st12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CNN.v
//   Module Name : CNN
//   Release version : V1.0 (Release Date: 2024-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel_ch1,
    Kernel_ch2,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );


//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

localparam FP_0 = 32'h00000000;
localparam FP_1 = 32'h3f800000;
localparam FP_2 = 32'h40000000;
localparam FP_05 = 32'h3f400000;
localparam FP_ln05 = 32'hbe934b10;
localparam FP_ln2 = 32'h3f317218;
localparam FP_ln2_recip = 32'h3fb8aa3b;
localparam FP_ln2_recip_n = 32'hbfb8aa3b;
localparam FP_ln2_recip_mul2 = 32'h4038aa3b;
integer i;

input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] Img, Kernel_ch1, Kernel_ch2, Weight;
input Opt;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;


//---------------------------------------------------------------------
//   Reg & Wires
//---------------------------------------------------------------------
reg [6:0] cnt, n_cnt;
reg [4:0] img_cnt, n_img_cnt;
reg [inst_sig_width+inst_exp_width:0] IMG_reg [0:24];
reg [inst_sig_width+inst_exp_width:0] n_IMG_reg [0:24];
reg [inst_sig_width+inst_exp_width:0] IMG2_reg [0:24];
reg [inst_sig_width+inst_exp_width:0] n_IMG2_reg [0:24];
reg [inst_sig_width+inst_exp_width:0] Kernel1_reg [0:11];
reg [inst_sig_width+inst_exp_width:0] Kernel2_reg [0:11];
reg [inst_sig_width+inst_exp_width:0] n_Kernel1_reg [0:11];
reg [inst_sig_width+inst_exp_width:0] n_Kernel2_reg [0:11];

reg [inst_sig_width+inst_exp_width:0] w_1_reg      [0:7];
reg [inst_sig_width+inst_exp_width:0] n_w_1_reg    [0:7];
reg [inst_sig_width+inst_exp_width:0] w_2_reg      [0:7];
reg [inst_sig_width+inst_exp_width:0] n_w_2_reg    [0:7];
reg [inst_sig_width+inst_exp_width:0] w_3_reg      [0:7];
reg [inst_sig_width+inst_exp_width:0] n_w_3_reg    [0:7];
reg Opt_reg;
reg n_Opt_reg;

reg [5:0] pipe_cnt, n_pipe_cnt;
reg [inst_sig_width+inst_exp_width:0] mul3, mul4;
reg [inst_sig_width+inst_exp_width:0] mul_out2, mul_out2_ff;
reg [inst_sig_width+inst_exp_width:0] exp_in, exp_out, log_in, log_out, exp_out_ff, log_out_ff;
reg [inst_sig_width+inst_exp_width:0] sub1 [0:1];
reg [inst_sig_width+inst_exp_width:0] sub2 [0:1];
reg [inst_sig_width+inst_exp_width:0] sub_out [0:1];
reg [inst_sig_width+inst_exp_width:0] sub_out_ff [0:1];
reg [inst_sig_width+inst_exp_width:0] pipe_reg;
reg sub1_op;
reg [inst_sig_width+inst_exp_width:0] act_out [0:7];

//---------------------------------------------------------------------
// IPs
//---------------------------------------------------------------------

//---------------------------------------------------------------------
// Design
//---------------------------------------------------------------------

//---------------------------//
//            FSM            //
//---------------------------//
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        cnt <= 0;
    end
    else begin
        cnt <= n_cnt;
    end
end
always @(*) begin
    if(cnt == 0 && (~in_valid)) begin
        n_cnt = 0;
    end
    else if(cnt == ((Opt_reg)? 103 : 102)) begin
        n_cnt = 0;
    end
    else begin
        n_cnt = cnt + 1;
    end
end

always @(posedge clk) begin
    for(i = 0; i < 25; i = i + 1) begin
        IMG_reg[i] <= n_IMG_reg[i];
    end
    for(i = 0; i < 25; i = i + 1) begin
        IMG2_reg[i] <= n_IMG2_reg[i];
    end
    for(i = 0; i < 12; i = i + 1) begin
        Kernel1_reg[i] <= n_Kernel1_reg[i];
    end
    for(i = 0; i < 12; i = i + 1) begin
        Kernel2_reg[i] <= n_Kernel2_reg[i];
    end
    for(i = 0; i < 8; i = i + 1) begin
        w_1_reg[i] <= n_w_1_reg[i];
    end
    for(i = 0; i < 8; i = i + 1) begin
        w_2_reg[i] <= n_w_2_reg[i];
    end
    for(i = 0; i < 8; i = i + 1) begin
        w_3_reg[i] <= n_w_3_reg[i];
    end
    Opt_reg <= n_Opt_reg;
end

always @(*) begin
    for(i = 0; i < 25; i = i + 1) begin
        if((cnt == i) || (cnt == (i + 25)) || (cnt == (i + 50))) begin
            n_IMG_reg[i] = Img;
        end
        else begin
            n_IMG_reg[i] = IMG_reg[i];
        end
    end
end

always @(*) begin
    for(i = 0; i < 25; i = i + 1) begin
        if(cnt == (i + 50)) begin
            n_IMG2_reg[i] = Img;
        end
        else begin
            n_IMG2_reg[i] = IMG2_reg[i];
        end
    end
end

always @(*) begin
    for (i = 0; i < 12; i = i + 1) begin
        if (cnt == i) begin
            n_Kernel1_reg[i] = Kernel_ch1;
        end
        else begin
            n_Kernel1_reg[i] = Kernel1_reg[i];
        end
    end
end

always @(*) begin
    for (i = 0; i < 12; i = i + 1) begin
        if (cnt == i) begin
            n_Kernel2_reg[i] = Kernel_ch2;
        end
        else begin
            n_Kernel2_reg[i] = Kernel2_reg[i];
        end
    end
end

always @(*) begin
    for (i = 0; i < 8; i = i + 1) begin
        if (cnt == i) begin
            n_w_1_reg[i] = Weight;
        end
        else begin
            n_w_1_reg[i] = w_1_reg[i];
        end
        if (cnt == i + 8) begin
            n_w_2_reg[i] = Weight;
        end
        else begin
            n_w_2_reg[i] = w_2_reg[i];
        end
        if (cnt == i + 16) begin
            n_w_3_reg[i] = Weight;
        end
        else begin
            n_w_3_reg[i] = w_3_reg[i];
        end
    end
end

always @(*) begin
    n_Opt_reg = (cnt == 0  && in_valid == 1) ? Opt : Opt_reg;
end

//---------------------------//
//        convolution        //
//---------------------------//
reg [1:0] phase;
reg [1:0] phase2;

always @(*) begin
    if (cnt <= 78) begin
        if (cnt <= 28) begin
            phase = 2'd0;
        end
        else begin
            phase = 2'd1;
        end
    end
    else begin
        phase = 2'd2;
    end
end

always @(*) begin
    if (cnt <= 79) begin
        if (cnt <= 28) begin
            phase2 = 2'd0;
        end
        else begin
            phase2 = 2'd1;
        end
    end
    else begin
        phase2 = 2'd2;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        img_cnt <= 0;
    end
    else begin
        img_cnt <= n_img_cnt;
    end
end
always @(*) begin
    if (img_cnt >= 24 || cnt <= 3) begin
        n_img_cnt = 0;
    end
    else begin
        n_img_cnt = img_cnt + 1;
    end
end

reg [4:0] cal_cnt, n_cal_cnt;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        cal_cnt <= 0;
    end
    else begin
        cal_cnt <= n_cal_cnt;
    end
end

always @(*) begin
    if (cal_cnt >= 24 || cnt <= 4) begin
        n_cal_cnt = 0;
    end
    else begin
        n_cal_cnt = cal_cnt + 1;
    end
end

reg [inst_sig_width+inst_exp_width:0] w1, w2, w3, w4, w5, w6, w7, w8;
reg [inst_sig_width+inst_exp_width:0] img1, img2, img3, img4, img21, img22, img23, img24;
reg [inst_sig_width+inst_exp_width:0] conv_tmp1 [0:35];
reg [inst_sig_width+inst_exp_width:0] conv_tmp2 [0:35];

reg [inst_sig_width+inst_exp_width:0] img_2to1_reg, img_4to3_reg;

always @(posedge clk) begin
    img_2to1_reg <= img2;
    img_4to3_reg <= img4;
end

always @(*) begin
    case (img_cnt)
        5'd0: begin // start
            if (phase[1])
                img1 = IMG_reg[19];
            else
                img1 = (Opt_reg)? IMG_reg[0] : FP_0;
        end
        5'd5: img1 = (Opt_reg)? IMG_reg[0] : FP_0;
        5'd10: img1 = (Opt_reg)? IMG_reg[5] : FP_0;
        5'd15: img1 = (Opt_reg)? IMG_reg[10] : FP_0;
        5'd20: img1 = (Opt_reg)? IMG_reg[15] : FP_0;
        default: img1 = img_2to1_reg;
    endcase
end

always @(*) begin
    case (img_cnt)
        5'd0: begin
            if (phase[1])
                img3 = IMG_reg[24];
            else
                img3 = (Opt_reg)? IMG_reg[0] : FP_0;
        end
        5'd5: img3 = (Opt_reg)? IMG_reg[5] : FP_0;
        5'd10: img3 = (Opt_reg)? IMG_reg[10] : FP_0;
        5'd15: img3 = (Opt_reg)? IMG_reg[15] : FP_0;
        5'd20: img3 = (Opt_reg)? IMG_reg[20] : FP_0;
        default: img3 = img_4to3_reg;
    endcase
end

always @(*) begin
    case (img_cnt)
        5'd0: begin
            if (phase[1])
                img2 = (Opt_reg)? IMG_reg[19] : FP_0;
            else
                img2 = (Opt_reg)? IMG_reg[0] : FP_0;
        end
        5'd1: img2 = (Opt_reg)? IMG_reg[1] : FP_0;
        5'd2: img2 = (Opt_reg)? IMG_reg[2] : FP_0;
        5'd3: img2 = (Opt_reg)? IMG_reg[3] : FP_0;
        5'd4: img2 = (Opt_reg)? IMG_reg[4] : FP_0;

        5'd5, 5'd6, 5'd7, 5'd8, 5'd9,
        5'd10, 5'd11, 5'd12, 5'd13, 5'd14,
        5'd15, 5'd16, 5'd17, 5'd18, 5'd19,
        5'd20, 5'd21, 5'd22, 5'd23, 5'd24 : img2 = IMG_reg[img_cnt - 5];
        default: img2 = FP_0;
    endcase
end

always @(*) begin
    case (img_cnt)
        5'd0: begin
            if (phase[1])
                img4 = (Opt_reg)? IMG_reg[24] : FP_0;
            else
                img4 = IMG_reg[0];
        end
        5'd1, 5'd2, 5'd3, 5'd4,
        5'd5, 5'd6, 5'd7, 5'd8, 5'd9,
        5'd10, 5'd11, 5'd12, 5'd13, 5'd14,
        5'd15, 5'd16, 5'd17, 5'd18, 5'd19,
        5'd20, 5'd21, 5'd22, 5'd23, 5'd24 : img4 = IMG_reg[img_cnt];
        default: img4 = FP_0;
    endcase
end

always @(*) begin
    case (img_cnt)
        5'd0: begin // start
            if (phase)
                img21 = IMG_reg[24];
            else
                img21 = FP_0; 
        end 
        5'd1: begin
            if (phase)
                img21 = IMG_reg[19];
            else
                img21 = FP_0;
        end
        5'd4: img21 = (Opt_reg)? IMG_reg[4] : FP_0;
        5'd9: img21 = IMG_reg[4];
        5'd14: img21 = IMG_reg[9];
        5'd19: img21 = IMG_reg[14];
        5'd20: img21 = (Opt_reg)? IMG_reg[20] : FP_0;
        5'd21: img21 = IMG_reg[20];
        5'd22: img21 = IMG_reg[21];
        5'd23: img21 = IMG_reg[22];
        5'd24: img21 = IMG_reg[23];
        default: img21 = FP_0;
    endcase
end

always @(*) begin
    case (img_cnt)
        5'd0: begin
            if (phase)
                img22 = (Opt_reg)? IMG_reg[24] : FP_0;
            else
                img22 = FP_0; 
        end 
        5'd1: begin
            if (phase)
                img22 = (Opt_reg)? IMG_reg[19] : FP_0;
            else
                img22 = FP_0;
        end
        5'd4: img22 = (Opt_reg)? IMG_reg[4] : FP_0;
        5'd9: img22 = (Opt_reg)? IMG_reg[4] : FP_0;
        5'd14: img22 = (Opt_reg)? IMG_reg[9] : FP_0;
        5'd19: img22 = (Opt_reg)? IMG_reg[14] : FP_0;
        5'd20: img22 = IMG_reg[20];
        5'd21: img22 = IMG_reg[21];
        5'd22: img22 = IMG_reg[22];
        5'd23: img22 = IMG_reg[23];
        5'd24: img22 = IMG_reg[24];
        default: img22 = FP_0;
    endcase
end

always @(*) begin
    case (img_cnt)
        5'd0: begin
            if (phase)
                img23 = (Opt_reg)? IMG_reg[24] : FP_0;
            else
                img23 = FP_0; 
        end 
        5'd1: begin
            if (phase)
                img23 = IMG_reg[24];
            else
                img23 = FP_0;
        end
        5'd4: img23 = IMG_reg[4];
        5'd9: img23 = IMG_reg[9];
        5'd14: img23 = IMG_reg[14];
        5'd19: img23 = IMG_reg[19];
        5'd20: img23 = (Opt_reg)? IMG_reg[20] : FP_0;
        5'd21: img23 = (Opt_reg)? IMG_reg[20] : FP_0;
        5'd22: img23 = (Opt_reg)? IMG_reg[21] : FP_0;
        5'd23: img23 = (Opt_reg)? IMG_reg[22] : FP_0;
        5'd24: img23 = (Opt_reg)? IMG_reg[23] : FP_0;
        default: img23 = FP_0;
    endcase
end

always @(*) begin
    case (img_cnt)
        5'd0: begin
            if (phase)
                img24 = (Opt_reg)? IMG_reg[24] : FP_0;
            else
                img24 = FP_0; 
        end 
        5'd1: begin
            if (phase)
                img24 = (Opt_reg)? IMG_reg[24] : FP_0;
            else
                img24 = FP_0;
        end
        5'd4: img24 = (Opt_reg)? IMG_reg[4] : FP_0;
        5'd9: img24 = (Opt_reg)? IMG_reg[9] : FP_0;
        5'd14: img24 = (Opt_reg)? IMG_reg[14] : FP_0;
        5'd19: img24 = (Opt_reg)? IMG_reg[19] : FP_0;
        5'd20: img24 = (Opt_reg)? IMG_reg[20] : FP_0;
        5'd21: img24 = (Opt_reg)? IMG_reg[21] : FP_0;
        5'd22: img24 = (Opt_reg)? IMG_reg[22] : FP_0;
        5'd23: img24 = (Opt_reg)? IMG_reg[23] : FP_0;
        5'd24: img24 = (Opt_reg)? IMG_reg[24] : FP_0;
        default: img24 = FP_0;
    endcase
end

reg [inst_sig_width+inst_exp_width:0] mul1 [0:15];
reg [inst_sig_width+inst_exp_width:0] mul2 [0:15];
reg [inst_sig_width+inst_exp_width:0] mul_out [0:15];
reg [inst_sig_width+inst_exp_width:0] mul_out_ff [0:15];
reg [inst_sig_width+inst_exp_width:0] add1 [0:15];
reg [inst_sig_width+inst_exp_width:0] add2 [0:15];
reg [inst_sig_width+inst_exp_width:0] add_sum1 [0:15];
reg [inst_sig_width+inst_exp_width:0] cmp0a, cmp0b, cmp1a, cmp1b, cmp2a, cmp2b, cmp3a, cmp3b;
reg [inst_sig_width+inst_exp_width:0] cmp_out0, cmp_out1, cmp_out2, cmp_out3;
reg [inst_sig_width+inst_exp_width:0] Max0, Max1, Max2, Max3, Max4, Max5, Max6, Max7;


DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    mult0 ( .a(mul1[0]), .b(mul2[0]), .rnd(3'b0), .z(mul_out[0]), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    mult1 ( .a(mul1[1]), .b(mul2[1]), .rnd(3'b0), .z(mul_out[1]), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    mult2 ( .a(mul1[2]), .b(mul2[2]), .rnd(3'b0), .z(mul_out[2]), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    mult3 ( .a(mul1[3]), .b(mul2[3]), .rnd(3'b0), .z(mul_out[3]), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    mult4 ( .a(mul1[4]), .b(mul2[4]), .rnd(3'b0), .z(mul_out[4]), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    mult5 ( .a(mul1[5]), .b(mul2[5]), .rnd(3'b0), .z(mul_out[5]), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    mult6 ( .a(mul1[6]), .b(mul2[6]), .rnd(3'b0), .z(mul_out[6]), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    mult7 ( .a(mul1[7]), .b(mul2[7]), .rnd(3'b0), .z(mul_out[7]), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    mult8 ( .a(mul1[8]), .b(mul2[8]), .rnd(3'b0), .z(mul_out[8]), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    mult9 ( .a(mul1[9]), .b(mul2[9]), .rnd(3'b0), .z(mul_out[9]), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    mult10 ( .a(mul1[10]), .b(mul2[10]), .rnd(3'b0), .z(mul_out[10]), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    mult11 ( .a(mul1[11]), .b(mul2[11]), .rnd(3'b0), .z(mul_out[11]), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    mult12 ( .a(mul1[12]), .b(mul2[12]), .rnd(3'b0), .z(mul_out[12]), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    mult13 ( .a(mul1[13]), .b(mul2[13]), .rnd(3'b0), .z(mul_out[13]), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    mult14 ( .a(mul1[14]), .b(mul2[14]), .rnd(3'b0), .z(mul_out[14]), .status( ) );
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    mult15 ( .a(mul1[15]), .b(mul2[15]), .rnd(3'b0), .z(mul_out[15]), .status( ) );

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    fp_add0 ( .a(add1[0]), .b(add2[0]), .rnd(3'b0), .z(add_sum1[0]), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    fp_add1 ( .a(add1[1]), .b(add2[1]), .rnd(3'b0), .z(add_sum1[1]), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    fp_add2 ( .a(add1[2]), .b(add2[2]), .rnd(3'b0), .z(add_sum1[2]), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    fp_add3 ( .a(add1[3]), .b(add2[3]), .rnd(3'b0), .z(add_sum1[3]), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    fp_add4 ( .a(add1[4]), .b(add2[4]), .rnd(3'b0), .z(add_sum1[4]), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    fp_add5 ( .a(add1[5]), .b(add2[5]), .rnd(3'b0), .z(add_sum1[5]), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    fp_add6 ( .a(add1[6]), .b(add2[6]), .rnd(3'b0), .z(add_sum1[6]), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    fp_add7 ( .a(add1[7]), .b(add2[7]), .rnd(3'b0), .z(add_sum1[7]), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    fp_add8 ( .a(add1[8]), .b(add2[8]), .rnd(3'b0), .z(add_sum1[8]), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    fp_add9 ( .a(add1[9]), .b(add2[9]), .rnd(3'b0), .z(add_sum1[9]), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    fp_add10 ( .a(add1[10]), .b(add2[10]), .rnd(3'b0), .z(add_sum1[10]), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    fp_add11 ( .a(add1[11]), .b(add2[11]), .rnd(3'b0), .z(add_sum1[11]), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    fp_add12 ( .a(add1[12]), .b(add2[12]), .rnd(3'b0), .z(add_sum1[12]), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    fp_add13 ( .a(add1[13]), .b(add2[13]), .rnd(3'b0), .z(add_sum1[13]), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    fp_add14 ( .a(add1[14]), .b(add2[14]), .rnd(3'b0), .z(add_sum1[14]), .status() );
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    fp_add15 ( .a(add1[15]), .b(add2[15]), .rnd(3'b0), .z(add_sum1[15]), .status() );

reg [1:0] mul_case;

assign mul_case = cnt - 90;

always @(*) begin
    if (cnt <= 81) begin
        mul1[0] = img1;
        mul1[1] = img2;
        mul1[2] = img3;
        mul1[3] = img4;
        mul1[4] = img1;
        mul1[5] = img2;
        mul1[6] = img3;
        mul1[7] = img4;
        mul1[8] = img21;
        mul1[9] = img22;
        mul1[10] = img23;
        mul1[11] = img24;
        mul1[12] = img21;
        mul1[13] = img22;
        mul1[14] = img23;
        mul1[15] = img24;
    end
    else begin
        case (mul_case)
            2'd0: begin
                if (!Opt_reg) begin
                    mul1[0] = act_out[0];
                    mul1[1] = act_out[1];
                    mul1[2] = act_out[2];
                    mul1[3] = act_out[3];
                    mul1[4] = act_out[4];
                    mul1[5] = act_out[5];
                    mul1[6] = act_out[6];
                    mul1[7] = exp_out_ff;
                    mul1[8] = act_out[0];
                    mul1[9] = act_out[1];
                    mul1[10] = act_out[2];
                    mul1[11] = act_out[3];
                    mul1[12] = act_out[4];
                    mul1[13] = act_out[5];
                    mul1[14] = act_out[6];
                    mul1[15] = exp_out_ff;
                end
                else begin
                    mul1[0] = FP_0;
                    mul1[1] = FP_0;
                    mul1[2] = FP_0;
                    mul1[3] = FP_0;
                    mul1[4] = FP_0;
                    mul1[5] = FP_0;
                    mul1[6] = FP_0;
                    mul1[7] = FP_0;
                    mul1[8] = FP_0;
                    mul1[9] = FP_0;
                    mul1[10] = FP_0;
                    mul1[11] = FP_0;
                    mul1[12] = FP_0;
                    mul1[13] = FP_0;
                    mul1[14] = FP_0;
                    mul1[15] = FP_0;
                end
            end
            2'd1: begin
                if (Opt_reg) begin
                    mul1[0] = act_out[0];
                    mul1[1] = act_out[1];
                    mul1[2] = act_out[2];
                    mul1[3] = act_out[3];
                    mul1[4] = act_out[4];
                    mul1[5] = act_out[5];
                    mul1[6] = act_out[6];
                    mul1[7] = sub_out_ff[0];
                    mul1[8] = act_out[0];
                    mul1[9] = act_out[1];
                    mul1[10] = act_out[2];
                    mul1[11] = act_out[3];
                    mul1[12] = act_out[4];
                    mul1[13] = act_out[5];
                    mul1[14] = act_out[6];
                    mul1[15] = sub_out_ff[0];
                end
                else begin
                    mul1[0] = act_out[0];
                    mul1[1] = act_out[1];
                    mul1[2] = act_out[2];
                    mul1[3] = act_out[3];
                    mul1[4] = act_out[4];
                    mul1[5] = act_out[5];
                    mul1[6] = act_out[6];
                    mul1[7] = act_out[7];
                    mul1[8] = FP_0;
                    mul1[9] = FP_0;
                    mul1[10] = FP_0;
                    mul1[11] = FP_0;
                    mul1[12] = FP_0;
                    mul1[13] = FP_0;
                    mul1[14] = FP_0;
                    mul1[15] = FP_0;
                end
            end
            2'd2: begin
                if (Opt_reg) begin
                    mul1[0] = act_out[0];
                    mul1[1] = act_out[1];
                    mul1[2] = act_out[2];
                    mul1[3] = act_out[3];
                    mul1[4] = act_out[4];
                    mul1[5] = act_out[5];
                    mul1[6] = act_out[6];
                    mul1[7] = act_out[7];
                    mul1[8] = FP_0;
                    mul1[9] = FP_0;
                    mul1[10] = FP_0;
                    mul1[11] = FP_0;
                    mul1[12] = FP_0;
                    mul1[13] = FP_0;
                    mul1[14] = FP_0;
                    mul1[15] = FP_0;
                end
                else begin
                    mul1[0] = FP_0;
                    mul1[1] = FP_0;
                    mul1[2] = FP_0;
                    mul1[3] = FP_0;
                    mul1[4] = FP_0;
                    mul1[5] = FP_0;
                    mul1[6] = FP_0;
                    mul1[7] = FP_0;
                    mul1[8] = FP_0;
                    mul1[9] = FP_0;
                    mul1[10] = FP_0;
                    mul1[11] = FP_0;
                    mul1[12] = FP_0;
                    mul1[13] = FP_0;
                    mul1[14] = FP_0;
                    mul1[15] = FP_0;
                end
            end
            default: begin
                mul1[0] = FP_0;
                mul1[1] = FP_0;
                mul1[2] = FP_0;
                mul1[3] = FP_0;
                mul1[4] = FP_0;
                mul1[5] = FP_0;
                mul1[6] = FP_0;
                mul1[7] = FP_0;
                mul1[8] = FP_0;
                mul1[9] = FP_0;
                mul1[10] = FP_0;
                mul1[11] = FP_0;
                mul1[12] = FP_0;
                mul1[13] = FP_0;
                mul1[14] = FP_0;
                mul1[15] = FP_0;
            end
        endcase
    end
end

always @(*) begin
    if (cnt <= 81) begin
        if (cnt <= 28) begin
            mul2[0] = Kernel1_reg[0];
            mul2[1] = Kernel1_reg[1];
            mul2[2] = Kernel1_reg[2];
            mul2[3] = Kernel1_reg[3];
            mul2[4] = Kernel2_reg[0];
            mul2[5] = Kernel2_reg[1];
            mul2[6] = Kernel2_reg[2];
            mul2[7] = Kernel2_reg[3];
        end
        else if (cnt <= 53) begin
            mul2[0] = Kernel1_reg[4];
            mul2[1] = Kernel1_reg[5];
            mul2[2] = Kernel1_reg[6];
            mul2[3] = Kernel1_reg[7];
            mul2[4] = Kernel2_reg[4];
            mul2[5] = Kernel2_reg[5];
            mul2[6] = Kernel2_reg[6];
            mul2[7] = Kernel2_reg[7];
        end
        else begin
            mul2[0] = Kernel1_reg[8];
            mul2[1] = Kernel1_reg[9];
            mul2[2] = Kernel1_reg[10];
            mul2[3] = Kernel1_reg[11];
            mul2[4] = Kernel2_reg[8];
            mul2[5] = Kernel2_reg[9];
            mul2[6] = Kernel2_reg[10];
            mul2[7] = Kernel2_reg[11];
        end
    end
    else begin
        case (mul_case)
            2'd0: begin
                if (!Opt_reg) begin
                    mul2[0] = w_1_reg[0];
                    mul2[1] = w_1_reg[1];
                    mul2[2] = w_1_reg[2];
                    mul2[3] = w_1_reg[3];
                    mul2[4] = w_1_reg[4];
                    mul2[5] = w_1_reg[5];
                    mul2[6] = w_1_reg[6];
                    mul2[7] = w_1_reg[7];
                end
                else begin
                    mul2[0] = FP_0;
                    mul2[1] = FP_0;
                    mul2[2] = FP_0;
                    mul2[3] = FP_0;
                    mul2[4] = FP_0;
                    mul2[5] = FP_0;
                    mul2[6] = FP_0;
                    mul2[7] = FP_0;
                end
            end
            2'd1: begin
                if (Opt_reg) begin
                    mul2[0] = w_1_reg[0];
                    mul2[1] = w_1_reg[1];
                    mul2[2] = w_1_reg[2];
                    mul2[3] = w_1_reg[3];
                    mul2[4] = w_1_reg[4];
                    mul2[5] = w_1_reg[5];
                    mul2[6] = w_1_reg[6];
                    mul2[7] = w_1_reg[7];
                end
                else begin
                    mul2[0] = w_3_reg[0];
                    mul2[1] = w_3_reg[1];
                    mul2[2] = w_3_reg[2];
                    mul2[3] = w_3_reg[3];
                    mul2[4] = w_3_reg[4];
                    mul2[5] = w_3_reg[5];
                    mul2[6] = w_3_reg[6];
                    mul2[7] = w_3_reg[7];
                end
            end
            2'd2: begin
                if (Opt_reg) begin
                    mul2[0] = w_3_reg[0];
                    mul2[1] = w_3_reg[1];
                    mul2[2] = w_3_reg[2];
                    mul2[3] = w_3_reg[3];
                    mul2[4] = w_3_reg[4];
                    mul2[5] = w_3_reg[5];
                    mul2[6] = w_3_reg[6];
                    mul2[7] = w_3_reg[7];
                end
                else begin
                    mul2[0] = FP_0;
                    mul2[1] = FP_0;
                    mul2[2] = FP_0;
                    mul2[3] = FP_0;
                    mul2[4] = FP_0;
                    mul2[5] = FP_0;
                    mul2[6] = FP_0;
                    mul2[7] = FP_0;
                end
            end
            default: begin
                mul2[0] = FP_0;
                mul2[1] = FP_0;
                mul2[2] = FP_0;
                mul2[3] = FP_0;
                mul2[4] = FP_0;
                mul2[5] = FP_0;
                mul2[6] = FP_0;
                mul2[7] = FP_0;
            end
        endcase
    end
end

always @(*) begin
    if (cnt <= 81) begin
        if (cnt <= 31) begin
            mul2[8] = Kernel1_reg[0];
            mul2[9] = Kernel1_reg[1];
            mul2[10] = Kernel1_reg[2];
            mul2[11] = Kernel1_reg[3];
            mul2[12] = Kernel2_reg[0];
            mul2[13] = Kernel2_reg[1];
            mul2[14] = Kernel2_reg[2];
            mul2[15] = Kernel2_reg[3];
        end
        else if (cnt <= 56) begin
            mul2[8] = Kernel1_reg[4];
            mul2[9] = Kernel1_reg[5];
            mul2[10] = Kernel1_reg[6];
            mul2[11] = Kernel1_reg[7];
            mul2[12] = Kernel2_reg[4];
            mul2[13] = Kernel2_reg[5];
            mul2[14] = Kernel2_reg[6];
            mul2[15] = Kernel2_reg[7];
        end
        else begin
            mul2[8] = Kernel1_reg[8];
            mul2[9] = Kernel1_reg[9];
            mul2[10] = Kernel1_reg[10];
            mul2[11] = Kernel1_reg[11];
            mul2[12] = Kernel2_reg[8];
            mul2[13] = Kernel2_reg[9];
            mul2[14] = Kernel2_reg[10];
            mul2[15] = Kernel2_reg[11];
        end
    end
    else begin
        case (mul_case)
            2'd0: begin
                if (!Opt_reg) begin
                    mul2[8] = w_2_reg[0];
                    mul2[9] = w_2_reg[1];
                    mul2[10] = w_2_reg[2];
                    mul2[11] = w_2_reg[3];
                    mul2[12] = w_2_reg[4];
                    mul2[13] = w_2_reg[5];
                    mul2[14] = w_2_reg[6];
                    mul2[15] = w_2_reg[7];
                end
                else begin
                    mul2[8] = FP_0;
                    mul2[9] = FP_0;
                    mul2[10] = FP_0;
                    mul2[11] = FP_0;
                    mul2[12] = FP_0;
                    mul2[13] = FP_0;
                    mul2[14] = FP_0;
                    mul2[15] = FP_0;
                end
            end
            2'd1: begin
                if (Opt_reg) begin
                    mul2[8] = w_2_reg[0];
                    mul2[9] = w_2_reg[1];
                    mul2[10] = w_2_reg[2];
                    mul2[11] = w_2_reg[3];
                    mul2[12] = w_2_reg[4];
                    mul2[13] = w_2_reg[5];
                    mul2[14] = w_2_reg[6];
                    mul2[15] = w_2_reg[7];
                end
                else begin
                    mul2[8] = FP_0;
                    mul2[9] = FP_0;
                    mul2[10] = FP_0;
                    mul2[11] = FP_0;
                    mul2[12] = FP_0;
                    mul2[13] = FP_0;
                    mul2[14] = FP_0;
                    mul2[15] = FP_0;
                end
            end
            default: begin
                mul2[8] = FP_0;
                mul2[9] = FP_0;
                mul2[10] = FP_0;
                mul2[11] = FP_0;
                mul2[12] = FP_0;
                mul2[13] = FP_0;
                mul2[14] = FP_0;
                mul2[15] = FP_0;
            end
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 16; i = i + 1) begin
            mul_out_ff[i] <= FP_0;
        end
    end
    else begin
        for (i = 0; i < 16; i = i + 1) begin
            mul_out_ff[i] <= mul_out[i];
        end
    end
end

always @(*) begin
    if (cnt <= 81) begin
        add1[0] = mul_out_ff[0];
        add2[0] = mul_out_ff[1];
        add1[1] = mul_out_ff[2];
        add2[1] = mul_out_ff[3];
        add1[2] = mul_out_ff[4];
        add2[2] = mul_out_ff[5];
        add1[3] = mul_out_ff[6];
        add2[3] = mul_out_ff[7];
        add1[4] = mul_out_ff[8];
        add2[4] = mul_out_ff[9];
        add1[5] = mul_out_ff[10];
        add2[5] = mul_out_ff[11];
        add1[6] = mul_out_ff[12];
        add2[6] = mul_out_ff[13];
        add1[7] = mul_out_ff[14];
        add2[7] = mul_out_ff[15];
    end
    else begin
        case (mul_case)
            2'd1: begin
                if (!Opt_reg) begin
                    add1[0] = mul_out_ff[0];
                    add2[0] = mul_out_ff[1];
                    add1[1] = mul_out_ff[2];
                    add2[1] = mul_out_ff[3];
                    add1[2] = mul_out_ff[4];
                    add2[2] = mul_out_ff[5];
                    add1[3] = mul_out_ff[6];
                    add2[3] = mul_out_ff[7];
                    add1[4] = mul_out_ff[8];
                    add2[4] = mul_out_ff[9];
                    add1[5] = mul_out_ff[10];
                    add2[5] = mul_out_ff[11];
                    add1[6] = mul_out_ff[12];
                    add2[6] = mul_out_ff[13];
                    add1[7] = mul_out_ff[14];
                    add2[7] = mul_out_ff[15];
                end
                else begin
                    add1[0] = FP_0;
                    add2[0] = FP_0;
                    add1[1] = FP_0;
                    add2[1] = FP_0;
                    add1[2] = FP_0;
                    add2[2] = FP_0;
                    add1[3] = FP_0;
                    add2[3] = FP_0;
                    add1[4] = FP_0;
                    add2[4] = FP_0;
                    add1[5] = FP_0;
                    add2[5] = FP_0;
                    add1[6] = FP_0;
                    add2[6] = FP_0;
                    add1[7] = FP_0;
                    add2[7] = FP_0;
                end
            end 
            2'd2: begin
                if (Opt_reg) begin
                    add1[0] = mul_out_ff[0];
                    add2[0] = mul_out_ff[1];
                    add1[1] = mul_out_ff[2];
                    add2[1] = mul_out_ff[3];
                    add1[2] = mul_out_ff[4];
                    add2[2] = mul_out_ff[5];
                    add1[3] = mul_out_ff[6];
                    add2[3] = mul_out_ff[7];
                    add1[4] = mul_out_ff[8];
                    add2[4] = mul_out_ff[9];
                    add1[5] = mul_out_ff[10];
                    add2[5] = mul_out_ff[11];
                    add1[6] = mul_out_ff[12];
                    add2[6] = mul_out_ff[13];
                    add1[7] = mul_out_ff[14];
                    add2[7] = mul_out_ff[15];
                end
                else begin
                    add1[0] = mul_out_ff[0];
                    add2[0] = mul_out_ff[1];
                    add1[1] = mul_out_ff[2];
                    add2[1] = mul_out_ff[3];
                    add1[2] = mul_out_ff[4];
                    add2[2] = mul_out_ff[5];
                    add1[3] = mul_out_ff[6];
                    add2[3] = mul_out_ff[7];
                    add1[4] = FP_0;
                    add2[4] = FP_0;
                    add1[5] = FP_0;
                    add2[5] = FP_0;
                    add1[6] = FP_0;
                    add2[6] = FP_0;
                    add1[7] = FP_0;
                    add2[7] = FP_0;
                end
            end
            2'd3: begin
                if (Opt_reg) begin
                    add1[0] = mul_out_ff[0];
                    add2[0] = mul_out_ff[1];
                    add1[1] = mul_out_ff[2];
                    add2[1] = mul_out_ff[3];
                    add1[2] = mul_out_ff[4];
                    add2[2] = mul_out_ff[5];
                    add1[3] = mul_out_ff[6];
                    add2[3] = mul_out_ff[7];
                    add1[4] = FP_0;
                    add2[4] = FP_0;
                    add1[5] = FP_0;
                    add2[5] = FP_0;
                    add1[6] = FP_0;
                    add2[6] = FP_0;
                    add1[7] = FP_0;
                    add2[7] = FP_0;
                end
                else begin
                    add1[0] = FP_0;
                    add2[0] = FP_0;
                    add1[1] = FP_0;
                    add2[1] = FP_0;
                    add1[2] = FP_0;
                    add2[2] = FP_0;
                    add1[3] = FP_0;
                    add2[3] = FP_0;
                    add1[4] = FP_0;
                    add2[4] = FP_0;
                    add1[5] = FP_0;
                    add2[5] = FP_0;
                    add1[6] = FP_0;
                    add2[6] = FP_0;
                    add1[7] = FP_0;
                    add2[7] = FP_0;
                end
            end
            default: begin
                add1[0] = FP_0;
                add2[0] = FP_0;
                add1[1] = FP_0;
                add2[1] = FP_0;
                add1[2] = FP_0;
                add2[2] = FP_0;
                add1[3] = FP_0;
                add2[3] = FP_0;
                add1[4] = FP_0;
                add2[4] = FP_0;
                add1[5] = FP_0;
                add2[5] = FP_0;
                add1[6] = FP_0;
                add2[6] = FP_0;
                add1[7] = FP_0;
                add2[7] = FP_0;
            end
        endcase
    end
end

always @(*) begin
    if (cnt <= 81) begin
        add1[8] = add_sum1[0];
        add2[8] = add_sum1[1];
        add1[9] = add_sum1[2];
        add2[9] = add_sum1[3];
        add1[10] = add_sum1[4];
        add2[10] = add_sum1[5];
        add1[11] = add_sum1[6];
        add2[11] = add_sum1[7];

        add1[12] = add_sum1[8];
        add1[13] = add_sum1[9];
        add1[14] = add_sum1[10];
        add1[15] = add_sum1[11];
    end
    else begin
        add1[8] = FP_0;
        add2[8] = FP_0;
        add1[9] = FP_0;
        add2[9] = FP_0;
        add1[10] = FP_0;
        add2[10] = FP_0;
        add1[11] = FP_0;
        add2[11] = FP_0;
        add1[12] = FP_0;
        add1[13] = FP_0;
        add1[14] = FP_0;
        add1[15] = FP_0;

        case (mul_case)
            2'd1: begin
                if (!Opt_reg) begin
                    add1[8] = add_sum1[0];
                    add2[8] = add_sum1[1];
                    add1[9] = add_sum1[2];
                    add2[9] = add_sum1[3];
                    add1[10] = add_sum1[4];
                    add2[10] = add_sum1[5];
                    add1[11] = add_sum1[6];
                    add2[11] = add_sum1[7];
                    add1[12] = add_sum1[8];
                    add1[13] = add_sum1[10];
                    add1[14] = FP_0;
                    add1[15] = FP_0;
                end
                else begin
                    add1[8] = FP_0;
                    add2[8] = FP_0;
                    add1[9] = FP_0;
                    add2[9] = FP_0;
                    add1[10] = FP_0;
                    add2[10] = FP_0;
                    add1[11] = FP_0;
                    add2[11] = FP_0;
                    add1[12] = FP_0;
                    add1[13] = FP_0;
                    add1[14] = FP_0;
                    add1[15] = FP_0;
                end
            end
            2'd2: begin
                if (Opt_reg) begin
                    add1[8] = add_sum1[0];
                    add2[8] = add_sum1[1];
                    add1[9] = add_sum1[2];
                    add2[9] = add_sum1[3];
                    add1[10] = add_sum1[4];
                    add2[10] = add_sum1[5];
                    add1[11] = add_sum1[6];
                    add2[11] = add_sum1[7];
                    add1[12] = add_sum1[8];  // W1 = add_sum1[12]
                    add1[13] = add_sum1[10]; // W2 = add_sum1[13]
                    add1[14] = FP_0;
                    add1[15] = FP_0;
                end
                else begin
                    add1[8] = add_sum1[0];
                    add2[8] = add_sum1[1];
                    add1[9] = add_sum1[2];
                    add2[9] = add_sum1[3];
                    add1[10] = FP_0;
                    add2[10] = FP_0;
                    add1[11] = FP_0;
                    add2[11] = FP_0;
                    add1[12] = add_sum1[8]; // W3 = add_sum1[12]
                    add1[13] = FP_0;
                    add1[14] = FP_0;
                    add1[15] = FP_0;
                end
            end
            2'd3: begin
                if (Opt_reg) begin
                    add1[8] = add_sum1[0];
                    add2[8] = add_sum1[1];
                    add1[9] = add_sum1[2];
                    add2[9] = add_sum1[3];
                    add1[10] = FP_0;
                    add2[10] = FP_0;
                    add1[11] = FP_0;
                    add2[11] = FP_0;
                    add1[12] = add_sum1[8]; // W3 = add_sum1[12]
                    add1[13] = FP_0;
                    add1[14] = FP_0;
                    add1[15] = FP_0;
                end
                else begin
                    add1[8] = FP_0;
                    add2[8] = FP_0;
                    add1[9] = FP_0;
                    add2[9] = FP_0;
                    add1[10] = FP_0;
                    add2[10] = FP_0;
                    add1[11] = FP_0;
                    add2[11] = FP_0;
                    add1[12] = FP_0;
                    add1[13] = FP_0;
                    add1[14] = FP_0;
                    add1[15] = FP_0;
                end
            end
            default: begin
                add1[8] = FP_0;
                add2[8] = FP_0;
                add1[9] = FP_0;
                add2[9] = FP_0;
                add1[10] = FP_0;
                add2[10] = FP_0;
                add1[11] = FP_0;
                add2[11] = FP_0;
                add1[12] = FP_0;
                add1[13] = FP_0;
                add1[14] = FP_0;
                add1[15] = FP_0;
            end
        endcase
    end
end

always @(*) begin
    if (cnt <= 81) begin
        case (cal_cnt)
            5'd0: begin
                if (phase2[1]) begin
                    add2[12] = conv_tmp1[29];
                    add2[13] = conv_tmp2[29];
                end
                else begin
                    add2[12] = conv_tmp1[0];
                    add2[13] = conv_tmp2[0];
                end
            end
            5'd1, 5'd2, 5'd3, 5'd4: begin
                add2[12] = conv_tmp1[cal_cnt];
                add2[13] = conv_tmp2[cal_cnt];
            end
            5'd5, 5'd6, 5'd7, 5'd8, 5'd9: begin
                add2[12] = conv_tmp1[cal_cnt + 1];
                add2[13] = conv_tmp2[cal_cnt + 1];
            end
            5'd10, 5'd11, 5'd12, 5'd13, 5'd14: begin
                add2[12] = conv_tmp1[cal_cnt + 2];
                add2[13] = conv_tmp2[cal_cnt + 2];
            end
            5'd15, 5'd16, 5'd17, 5'd18, 5'd19: begin
                add2[12] = conv_tmp1[cal_cnt + 3];
                add2[13] = conv_tmp2[cal_cnt + 3];
            end
            5'd20, 5'd21, 5'd22, 5'd23, 5'd24: begin
                add2[12] = conv_tmp1[cal_cnt + 4];
                add2[13] = conv_tmp2[cal_cnt + 4];
            end
            default: begin
                add2[12] = FP_0;
                add2[13] = FP_0;
            end
        endcase
    end
    else begin
        case (mul_case)
            2'd1: begin
                if (!Opt_reg) begin
                    add2[12] = add_sum1[9];  // W1 = add_sum1[12]
                    add2[13] = add_sum1[11]; // W2 = add_sum1[13]
                end
                else begin
                    add2[12] = FP_0;
                    add2[13] = FP_0;
                end
            end
            2'd2:begin
                if (Opt_reg) begin
                    add2[12] = add_sum1[9];  // W1 = add_sum1[12]
                    add2[13] = add_sum1[11]; // W2 = add_sum1[13]
                end
                else begin
                    add2[12] = add_sum1[9];  // W3 = add_sum1[12]
                    add2[13] = FP_0;
                end
            end
            2'd3: begin
                if (Opt_reg) begin
                    add2[12] = add_sum1[9];  // W3 = add_sum1[12]
                    add2[13] = FP_0;
                end
                else begin
                    add2[12] = FP_0;
                    add2[13] = FP_0;
                end
            end
            default: begin
                add2[12] = FP_0;
                add2[13] = FP_0;
            end
        endcase
    end
end

reg [inst_sig_width+inst_exp_width:0] W_1, W_2, W_3;

always @(posedge clk) begin
    case (cnt)
        7'd0: begin
            W_1 <= FP_0;
            W_2 <= FP_0;
            W_3 <= FP_0;
        end
        7'd91: begin
            if (!Opt_reg) begin
                W_1 <= add_sum1[12];
                W_2 <= add_sum1[13];
            end
        end
        7'd92: begin
            if (Opt_reg) begin
                W_1 <= add_sum1[12];
                W_2 <= add_sum1[13];
            end
            else begin
                W_3 <= add_sum1[12];
            end
        end
        7'd93: begin
            W_3 <= (Opt_reg)? add_sum1[12] : W_3;
        end
        default: begin
            W_1 <= W_1;
            W_2 <= W_2;
            W_3 <= W_3;
        end
    endcase
end

always @(*) begin
    if (cnt <= 81) begin
        case (cal_cnt)
            5'd0: begin
                if (phase2) begin
                    add2[14] = conv_tmp1[35];
                    add2[15] = conv_tmp2[35];
                end
                else begin
                    add2[14] = FP_0;
                    add2[15] = FP_0;
                end
            end
            5'd1: begin
                if (phase2) begin
                    add2[14] = conv_tmp1[29];
                    add2[15] = conv_tmp2[29];
                end
                else begin
                    add2[14] = FP_0;
                    add2[15] = FP_0;
                end
            end
            5'd4: begin
                add2[14] = conv_tmp1[5];
                add2[15] = conv_tmp2[5];
            end
            5'd9: begin
                add2[14] = conv_tmp1[11];
                add2[15] = conv_tmp2[11];
            end
            5'd14: begin
                add2[14] = conv_tmp1[17];
                add2[15] = conv_tmp2[17];
            end
            5'd19: begin
                add2[14] = conv_tmp1[23];
                add2[15] = conv_tmp2[23];
            end
            5'd20, 5'd21, 5'd22, 5'd23, 5'd24: begin
                add2[14] = conv_tmp1[cal_cnt + 10];
                add2[15] = conv_tmp2[cal_cnt + 10];
            end
            default: begin
                add2[14] = FP_0;
                add2[15] = FP_0;
            end
        endcase
    end
    else begin
        add2[14] = FP_0;
        add2[15] = FP_0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 36; i = i + 1) begin
            conv_tmp1[i] <= FP_0;
            conv_tmp2[i] <= FP_0;
        end
    end
    else begin
        if (cnt && cnt <= 81) begin
            case (cal_cnt)
                5'd0: begin
                    if (cnt >= 5 && cnt <= 61) begin
                        conv_tmp1[0] <= add_sum1[12];
                        conv_tmp2[0] <= add_sum1[13];
                    end
                    if (phase2) begin
                        conv_tmp1[35] <= add_sum1[14];
                        conv_tmp2[35] <= add_sum1[15];
                    end
                end 
                5'd1: begin
                    if (cnt <= 60) begin
                        conv_tmp1[1] <= add_sum1[12];
                        conv_tmp2[1] <= add_sum1[13];
                    end
                    if (phase2) begin
                        conv_tmp1[29] <= add_sum1[14];
                        conv_tmp2[29] <= add_sum1[15];
                    end
                end
                5'd2: begin
                    conv_tmp1[2] <= add_sum1[12];
                    conv_tmp2[2] <= add_sum1[13];
                end
                5'd3: begin
                    conv_tmp1[3] <= add_sum1[12];
                    conv_tmp2[3] <= add_sum1[13];
                end
                5'd4: begin
                    conv_tmp1[4] <= add_sum1[12];
                    conv_tmp2[4] <= add_sum1[13];
                    conv_tmp1[5] <= add_sum1[14];
                    conv_tmp2[5] <= add_sum1[15];
                end
                5'd5, 5'd6, 5'd7, 5'd8: begin
                    conv_tmp1[cal_cnt + 1] <= add_sum1[12];
                    conv_tmp2[cal_cnt + 1] <= add_sum1[13];
                end
                5'd9: begin
                    conv_tmp1[10] <= add_sum1[12];
                    conv_tmp2[10] <= add_sum1[13];
                    conv_tmp1[11] <= add_sum1[14];
                    conv_tmp2[11] <= add_sum1[15];
                end
                5'd10, 5'd11, 5'd12, 5'd13: begin
                    conv_tmp1[cal_cnt + 2] <= add_sum1[12];
                    conv_tmp2[cal_cnt + 2] <= add_sum1[13];
                end
                5'd14: begin
                    conv_tmp1[16] <= add_sum1[12];
                    conv_tmp2[16] <= add_sum1[13];
                    conv_tmp1[17] <= add_sum1[14];
                    conv_tmp2[17] <= add_sum1[15];
                end
                5'd15, 5'd16, 5'd17, 5'd18: begin
                    conv_tmp1[cal_cnt + 3] <= add_sum1[12];
                    conv_tmp2[cal_cnt + 3] <= add_sum1[13];
                end
                5'd19: begin
                    conv_tmp1[22] <= add_sum1[12];
                    conv_tmp2[22] <= add_sum1[13];
                    conv_tmp1[23] <= add_sum1[14];
                    conv_tmp2[23] <= add_sum1[15];
                end
                5'd20, 5'd21, 5'd22, 5'd23: begin
                    conv_tmp1[cal_cnt + 4] <= add_sum1[12];
                    conv_tmp2[cal_cnt + 4] <= add_sum1[13];
                    conv_tmp1[cal_cnt + 10] <= add_sum1[14];
                    conv_tmp2[cal_cnt + 10] <= add_sum1[15];
                end
                5'd24: begin
                    conv_tmp1[28] <= add_sum1[12];
                    conv_tmp2[28] <= add_sum1[13];
                    if (phase2) begin
                        conv_tmp1[34] <= add_sum1[14];
                        conv_tmp2[34] <= add_sum1[15];
                    end
                end
                default: begin
                    conv_tmp1[0] <= conv_tmp1[0];
                end
            endcase
        end
        else begin
            if (cnt == 90) begin
                for (i = 0; i < 36; i = i + 1) begin
                    conv_tmp1[i] <= FP_0;
                    conv_tmp2[i] <= FP_0;
                end
            end
        end
    end
end

always @(*) begin
    if (cnt >= 56 && cnt <= 82) begin
        case (cal_cnt)
            5'd0: begin
                cmp0a = conv_tmp1[28];
                cmp0b = conv_tmp1[34];
                cmp1a = conv_tmp2[28];
                cmp1b = conv_tmp2[34];
                cmp2a = cmp_out0;
                cmp2b = Max3;
                cmp3a = cmp_out1;
                cmp3b = Max7;
            end 
            5'd1: begin
                cmp0a = conv_tmp1[0];
                cmp0b = Max0;
                cmp1a = conv_tmp2[0];
                cmp1b = Max4;
                cmp2a = (cnt >= 70)? conv_tmp1[35] : 32'hc7435000;
                cmp2b = Max3;
                cmp3a = (cnt >= 70)? conv_tmp2[35] : 32'hc7435000;
                cmp3b = Max7;
            end
            5'd2: begin
                cmp0a = conv_tmp1[1];
                cmp0b = Max0;
                cmp1a = conv_tmp2[1];
                cmp1b = Max4;
                cmp2a = (cnt >= 70)? conv_tmp1[29] : 32'hff7fffff;
                cmp2b = Max3;
                cmp3a = (cnt >= 70)? conv_tmp2[29] : 32'hff7fffff;
                cmp3b = Max7;
            end
            5'd3: begin
                cmp0a = conv_tmp1[2];
                cmp0b = Max0;
                cmp1a = conv_tmp2[2];
                cmp1b = Max4;
                cmp2a = FP_0;
                cmp2b = FP_0;
                cmp3a = FP_0;
                cmp3b = FP_0;
            end
            5'd4: begin
                cmp0a = conv_tmp1[3];
                cmp0b = Max1;
                cmp1a = conv_tmp2[3];
                cmp1b = Max5;
                cmp2a = FP_0;
                cmp2b = FP_0;
                cmp3a = FP_0;
                cmp3b = FP_0;
            end
            5'd5: begin
                cmp0a = conv_tmp1[4];
                cmp0b = conv_tmp1[5];
                cmp1a = conv_tmp2[4];
                cmp1b = conv_tmp2[5];
                cmp2a = cmp_out0;
                cmp2b = Max1;
                cmp3a = cmp_out1;
                cmp3b = Max5;
            end
            5'd6, 5'd7, 5'd8: begin
                cmp0a = conv_tmp1[cal_cnt];
                cmp0b = Max0;
                cmp1a = conv_tmp2[cal_cnt];
                cmp1b = Max4;
                cmp2a = FP_0;
                cmp2b = FP_0;
                cmp3a = FP_0;
                cmp3b = FP_0;
            end
            5'd9: begin
                cmp0a = conv_tmp1[9];
                cmp0b = Max1;
                cmp1a = conv_tmp2[9];
                cmp1b = Max5;
                cmp2a = FP_0;
                cmp2b = FP_0;
                cmp3a = FP_0;
                cmp3b = FP_0;
            end
            5'd10: begin
                cmp0a = conv_tmp1[10];
                cmp0b = conv_tmp1[11];
                cmp1a = conv_tmp2[10];
                cmp1b = conv_tmp2[11];
                cmp2a = cmp_out0;
                cmp2b = Max1;
                cmp3a = cmp_out1;
                cmp3b = Max5;
            end
            5'd11, 5'd12, 5'd13: begin
                cmp0a = conv_tmp1[cal_cnt + 1];
                cmp0b = Max0;
                cmp1a = conv_tmp2[cal_cnt + 1];
                cmp1b = Max4;
                cmp2a = FP_0;
                cmp2b = FP_0;
                cmp3a = FP_0;
                cmp3b = FP_0;
            end
            5'd14: begin
                cmp0a = conv_tmp1[15];
                cmp0b = Max1;
                cmp1a = conv_tmp2[15];
                cmp1b = Max5;
                cmp2a = FP_0;
                cmp2b = FP_0;
                cmp3a = FP_0;
                cmp3b = FP_0;
            end
            5'd15: begin
                cmp0a = conv_tmp1[16];
                cmp0b = conv_tmp1[17];
                cmp1a = conv_tmp2[16];
                cmp1b = conv_tmp2[17];
                cmp2a = cmp_out0;
                cmp2b = Max1;
                cmp3a = cmp_out1;
                cmp3b = Max5;
            end
            5'd16, 5'd17, 5'd18: begin
                cmp0a = conv_tmp1[cal_cnt + 2];
                cmp0b = Max2;
                cmp1a = conv_tmp2[cal_cnt + 2];
                cmp1b = Max6;
                cmp2a = FP_0;
                cmp2b = FP_0;
                cmp3a = FP_0;
                cmp3b = FP_0;
            end
            5'd19: begin
                cmp0a = conv_tmp1[21];
                cmp0b = Max3;
                cmp1a = conv_tmp2[21];
                cmp1b = Max7;
                cmp2a = FP_0;
                cmp2b = FP_0;
                cmp3a = FP_0;
                cmp3b = FP_0;
            end
            5'd20: begin
                cmp0a = conv_tmp1[22];
                cmp0b = conv_tmp1[23];
                cmp1a = conv_tmp2[22];
                cmp1b = conv_tmp2[23];
                cmp2a = cmp_out0;
                cmp2b = Max3;
                cmp3a = cmp_out1;
                cmp3b = Max7;
            end
            5'd21, 5'd22, 5'd23: begin
                cmp0a = conv_tmp1[cal_cnt + 3];
                cmp0b = conv_tmp1[cal_cnt + 9];
                cmp1a = conv_tmp2[cal_cnt + 3];
                cmp1b = conv_tmp2[cal_cnt + 9];
                cmp2a = cmp_out0;
                cmp2b = Max2;
                cmp3a = cmp_out1;
                cmp3b = Max6;
            end
            5'd24: begin
                cmp0a = conv_tmp1[27];
                cmp0b = conv_tmp1[33];
                cmp1a = conv_tmp2[27];
                cmp1b = conv_tmp2[33];
                cmp2a = cmp_out0;
                cmp2b = Max3;
                cmp3a = cmp_out1;
                cmp3b = Max7;
            end
            default: begin
                cmp0a = FP_0;
                cmp0b = FP_0;
                cmp1a = FP_0;
                cmp1b = FP_0;
                cmp2a = FP_0;
                cmp2b = FP_0;
                cmp3a = FP_0;
                cmp3b = FP_0;
            end
        endcase
    end
    else begin
        cmp0a = FP_0;
        cmp0b = FP_0;
        cmp1a = FP_0;
        cmp1b = FP_0;
        cmp2a = FP_0;
        cmp2b = FP_0;
        cmp3a = FP_0;
        cmp3b = FP_0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        Max0 <= 32'hff7fffff;
        Max1 <= 32'hff7fffff;
        Max2 <= 32'hff7fffff;
        Max3 <= 32'hff7fffff;
        Max4 <= 32'hff7fffff;
        Max5 <= 32'hff7fffff;
        Max6 <= 32'hff7fffff;
        Max7 <= 32'hff7fffff;
    end
    else begin
        if (cnt >= 56 && cnt <= 82) begin
            case (cal_cnt)
                5'd0: begin
                    Max3 <= cmp_out2;
                    Max7 <= cmp_out3;
                end
                5'd1, 5'd2: begin
                    Max0 <= cmp_out0;
                    Max4 <= cmp_out1;
                    Max3 <= cmp_out2;
                    Max7 <= cmp_out3;
                end
                5'd3, 5'd6, 5'd7, 5'd8, 5'd11, 5'd12, 5'd13: begin
                    Max0 <= cmp_out0;
                    Max4 <= cmp_out1;
                end
                5'd5, 5'd10, 5'd15: begin
                    Max1 <= cmp_out2;
                    Max5 <= cmp_out3;
                end
                5'd4, 5'd9, 5'd14: begin
                    Max1 <= cmp_out0;
                    Max5 <= cmp_out1;
                end
                5'd16, 5'd17, 5'd18: begin
                    Max2 <= cmp_out0;
                    Max6 <= cmp_out1;
                end
                5'd21, 5'd22, 5'd23: begin
                    Max2 <= cmp_out2;
                    Max6 <= cmp_out3;
                end
                5'd19: begin
                    Max3 <= cmp_out0;
                    Max7 <= cmp_out1;
                end
                5'd20, 5'd24: begin
                    Max3 <= cmp_out2;
                    Max7 <= cmp_out3;
                end
                default: Max0 <= Max0;
            endcase
        end
        else begin
            if (out_valid) begin
                Max0 <= 32'hff7fffff;
                Max1 <= 32'hff7fffff;
                Max2 <= 32'hff7fffff;
                Max3 <= 32'hff7fffff;
                Max4 <= 32'hff7fffff;
                Max5 <= 32'hff7fffff;
                Max6 <= 32'hff7fffff;
                Max7 <= 32'hff7fffff;
            end
        end
    end
end

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
         U1_mp_cmp0 ( .a(cmp0a), .b(cmp0b), .zctr(1'b0), .aeqb(),
        .altb(), .agtb(), .unordered(),
        .z0(), .z1(cmp_out0), .status0(),
        .status1() );
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
         U1_mp_cmp1 ( .a(cmp1a), .b(cmp1b), .zctr(1'b0), .aeqb(),
        .altb(), .agtb(), .unordered(),
        .z0(), .z1(cmp_out1), .status0(),
        .status1() );
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
         U1_mp_cmp2 ( .a(cmp2a), .b(cmp2b), .zctr(1'b0), .aeqb(),
        .altb(), .agtb(), .unordered(),
        .z0(), .z1(cmp_out2), .status0(),
        .status1() );
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
         U1_mp_cmp3 ( .a(cmp3a), .b(cmp3b), .zctr(1'b0), .aeqb(),
        .altb(), .agtb(), .unordered(),
        .z0(), .z1(cmp_out3), .status0(),
        .status1() );

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    Umul_act ( .a(mul3), .b(mul4), .rnd(3'b0), .z(mul_out2), .status( ) );

DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
        Usub1 ( .a(sub1[0]), .b(sub2[0]), .rnd(3'b0),
        .op(sub1_op), .z(sub_out[0]), .status() );
DW_fp_addsub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
        Usub2 ( .a(sub1[1]), .b(sub2[1]), .rnd(3'b0),
        .op(1'b1), .z(sub_out[1]), .status() );

DW_fp_log2 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_ieee_compliance, inst_arch) 
    U1_log (.a(log_in), .z(log_out), .status() ); 
DW_fp_exp2 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) 
    U1_exp (.a(exp_in), .z(exp_out), .status() );

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pipe_cnt <= 0;
    end
    else begin
        pipe_cnt <= n_pipe_cnt;
    end
end

always @(*) begin
    if (cnt <= 69) begin
        n_pipe_cnt = 0;
    end
    else begin
        n_pipe_cnt = pipe_cnt + 1;
    end

end

always @(posedge clk) begin
    mul_out2_ff <= mul_out2;
    sub_out_ff[0] <= sub_out[0];
    sub_out_ff[1] <= sub_out[1];
    exp_out_ff <= exp_out;
    log_out_ff <= log_out;
end

always @(posedge clk) begin
    case (pipe_cnt)
        6'd5, 6'd15: pipe_reg <= log_out_ff;
        6'd23: pipe_reg <= (!Opt_reg)? exp_out : pipe_reg;
        6'd24: pipe_reg <= (Opt_reg)? exp_out : pipe_reg;
        6'd27: pipe_reg <= (!Opt_reg)? log_out : pipe_reg;
        6'd28: pipe_reg <= (Opt_reg)? log_out : pipe_reg;
        default: pipe_reg <= pipe_reg;
    endcase
end

always @(*) begin
    if (cnt >= 70) begin
        case (pipe_cnt)
            6'd0: begin
                mul3 = Max0;
                mul4 = FP_ln2_recip_n;
            end
            6'd1: begin
                mul3 = (Opt_reg)? Max0 : Max4;
                mul4 = (Opt_reg)? FP_ln2_recip_mul2 : FP_ln2_recip_n;
            end
            6'd2: begin
                mul3 = Max4;
                mul4 = FP_ln2_recip_mul2;
            end
            6'd3: begin
                mul3 = Max1;
                mul4 = FP_ln2_recip_mul2;
            end
            6'd4: begin
                mul3 = (Opt_reg)? Max5 : Max1;
                mul4 = (Opt_reg)? FP_ln2_recip_mul2 : FP_ln2_recip_n;
            end
            6'd5: begin
                mul3 = Max5;
                mul4 = FP_ln2_recip_n;
            end

            6'd10: begin //cnt == 80
                mul3 = Max2;
                mul4 = FP_ln2_recip_n;
            end
            6'd11: begin
                mul3 = (Opt_reg)? Max2 : Max6;
                mul4 = (Opt_reg)? FP_ln2_recip_mul2 : FP_ln2_recip_n;
            end
            6'd12: begin
                mul3 = Max6;
                mul4 = FP_ln2_recip_mul2;
            end
            6'd13: begin
                mul3 = Max3;
                mul4 = FP_ln2_recip_mul2;
            end
            6'd14: begin
                mul3 = (Opt_reg)? Max7 : Max3;
                mul4 = (Opt_reg)? FP_ln2_recip_mul2 : FP_ln2_recip_n;
            end
            6'd15: begin
                mul3 = Max7;
                mul4 = FP_ln2_recip_n;
            end

            6'd22: begin  //softmax
                mul3 = W_1;
                mul4 = FP_ln2_recip;
            end
            6'd23: begin
                mul3 = (Opt_reg)? W_1 : W_2;
                mul4 = FP_ln2_recip;
            end
            6'd24: begin
                mul3 = (Opt_reg)? W_2 : W_3;
                mul4 = FP_ln2_recip;
            end
            6'd25: begin
                mul3 = W_3;
                mul4 = FP_ln2_recip;
            end
            6'd27: begin
                mul3 = W_1;
                mul4 = FP_ln2_recip;
            end
            6'd28: begin
                mul3 = (Opt_reg)? W_1 : W_2;
                mul4 = FP_ln2_recip;
            end
            6'd29: begin
                mul3 = (Opt_reg)? W_2 : W_3;
                mul4 = FP_ln2_recip;
            end
            6'd30: begin
                mul3 = W_3;
                mul4 = FP_ln2_recip;
            end
            default: begin
                mul3 = FP_0;
                mul4 = FP_0;
            end
        endcase
    end
    else begin
        mul3 = FP_0;
        mul4 = FP_0;
    end
end

always @(*) begin
    if (cnt >= 70) begin
        case (pipe_cnt)
            6'd1, 6'd11: exp_in = mul_out2_ff;
            6'd2, 6'd12: exp_in = mul_out2_ff;
            6'd3, 6'd13: exp_in = mul_out2_ff;
            6'd4, 6'd14: exp_in = (Opt_reg)? mul_out2_ff : {~log_out_ff[31], log_out_ff[30:0]};
            6'd5, 6'd15: exp_in = mul_out2_ff;
            6'd6, 6'd16: exp_in = (Opt_reg)? sub_out_ff[1] : mul_out2_ff;
            6'd7, 6'd17: exp_in = (Opt_reg)? sub_out_ff[1] : {~pipe_reg[31], pipe_reg[30:0]};
            6'd8, 6'd18: exp_in = (Opt_reg)? sub_out_ff[0] : {~log_out_ff[31], log_out_ff[30:0]};
            6'd9, 6'd19: exp_in = (Opt_reg)? sub_out_ff[0] : {~log_out_ff[31], log_out_ff[30:0]};

            6'd23, 6'd24, 6'd25, 6'd26: exp_in = mul_out2_ff; //softmax
            6'd29, 6'd30, 6'd31, 6'd32: exp_in = sub_out_ff[0];
            default: exp_in = FP_0;
        endcase
    end
    else begin
        exp_in = FP_0;
    end
end

always @(*) begin
    if (cnt >= 70) begin
        case (pipe_cnt)
            6'd2, 6'd3, 6'd4, 6'd5, 6'd6, 
            6'd12, 6'd13, 6'd14, 6'd15, 6'd16: begin
                sub1[0] = exp_out_ff;
                sub2[0] = FP_1;
                sub1_op = 1'd0;
            end
            6'd7, 6'd17: begin
                sub1[0] = (Opt_reg)? FP_1 : exp_out_ff;
                sub2[0] = (Opt_reg)? log_out_ff : FP_1;
                sub1_op = Opt_reg;
            end
            6'd8, 6'd18: begin
                sub1[0] = FP_1;
                sub2[0] = log_out_ff;
                sub1_op = 1'd1;
            end
            6'd9, 6'd10, 6'd19, 6'd20: begin
                sub1[0] = FP_1;
                sub2[0] = exp_out_ff;
                sub1_op = 1'd1;
            end 

            6'd25: begin // softmax
                sub1[0] = pipe_reg;
                sub2[0] = exp_out_ff;
                sub1_op = 1'd0;
            end
            6'd26: begin
                sub1[0] = (Opt_reg)? pipe_reg : sub_out_ff[0];
                sub2[0] = exp_out_ff;
                sub1_op = 1'd0;
            end
            6'd27: begin
                sub1[0] = sub_out_ff[0];
                sub2[0] = exp_out_ff;
                sub1_op = 1'd0;
            end
            6'd28, 6'd29, 6'd30, 6'd31: begin
                sub1[0] = mul_out2_ff;
                sub2[0] = pipe_reg;
                sub1_op = 1'd1;
            end
            default: begin
                sub1[0] = FP_0;
                sub2[0] = FP_0;
                sub1_op = 0;
            end
        endcase
    end
    else begin
        sub1[0] = FP_0;
        sub2[0] = FP_0;
        sub1_op = 0;
    end
end

always @(*) begin
    if (cnt >= 70) begin
        case (pipe_cnt)
            6'd5, 6'd6, 6'd15, 6'd16: begin
                sub1[1] = FP_1;
                sub2[1] = log_out_ff;
            end
            6'd7, 6'd8, 6'd17, 6'd18: begin
                sub1[1] = FP_1;
                sub2[1] = exp_out_ff;
            end
            default: begin
                sub1[1] = FP_0;
                sub2[1] = FP_0;
            end
        endcase
    end
    else begin
        sub1[1] = FP_0;
        sub2[1] = FP_0;
    end
end

always @(*) begin
    log_in = sub_out_ff[0];
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 8; i = i + 1) begin
            act_out[i] <= FP_0;
        end
    end
    else begin
        if (pipe_cnt) begin
            case (pipe_cnt)
                6'd5: act_out[0] <= (Opt_reg)? act_out[0] : exp_out_ff;
                6'd8: begin
                    if (Opt_reg) begin
                        act_out[0] <= sub_out_ff[1];
                    end
                    else begin
                        act_out[4] <= exp_out_ff;
                    end
                end
                6'd9: begin
                    if (Opt_reg) begin
                        act_out[4] <= sub_out_ff[1];
                    end
                    else begin
                        act_out[1] <= exp_out_ff;
                    end
                end
                6'd10: begin
                    if (Opt_reg) begin
                        act_out[1] <= sub_out_ff[0];
                    end
                    else begin
                        act_out[5] <= exp_out_ff;
                    end
                end
                6'd11: act_out[5] <= (Opt_reg)? sub_out_ff[0] : act_out[5];

                6'd15: act_out[2] <= (Opt_reg)? act_out[2] : exp_out_ff;
                6'd18: begin
                    if (Opt_reg) begin
                        act_out[2] <= sub_out_ff[1];
                    end
                    else begin
                        act_out[6] <= exp_out_ff;
                    end
                end
                6'd19: begin
                    if (Opt_reg) begin
                        act_out[6] <= sub_out_ff[1];
                    end
                    else begin
                        act_out[3] <= exp_out_ff;
                    end
                end
                6'd20: begin
                    if (Opt_reg) begin
                        act_out[3] <= sub_out_ff[0];
                    end
                    else begin
                        act_out[7] <= exp_out_ff;
                    end
                end
                6'd21: act_out[7] <= (Opt_reg)? sub_out_ff[0] : act_out[7];
                default: act_out[0] <= act_out[0];
            endcase
        end
    end
end

always @(*) begin
    if ((cnt >= ((Opt_reg)? 101 : 100)) && (cnt <= ((Opt_reg)? 103 : 102))) begin
        out_valid = 1'b1;
    end
    else begin
        out_valid = 1'b0;
    end
end

assign out = (out_valid)? exp_out_ff : FP_0;

endmodule

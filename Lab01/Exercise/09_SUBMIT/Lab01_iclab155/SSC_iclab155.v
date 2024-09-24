//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Fall
//   Lab01 Exercise		: Snack Shopping Calculator
//   Author     		  : Yu-Hsiang Wang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SSC.v
//   Module Name : SSC
//   Release version : V1.0 (Release Date: 2024-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
//`include "shift_LUT.v"
module split_1_3 (
    l0,
    r0, r1, r2,
    a0, a1, a2, a3
);
    input [7:0] l0;
    input [7:0] r0, r1, r2;
    output reg [7:0] a0, a1, a2, a3;
    always @(*) begin
        if (l0 >= r0) begin
            {a0, a1, a2, a3} = {l0, r0, r1, r2};
        end
        else begin
            a0 = r0;
            if (l0 >= r1)
                {a1, a2, a3} = {l0, r1, r2};
            else begin
                a1 = r1;
                {a2, a3} = (l0 >= r2)? {l0, r2} : {r2, l0};
            end
        end
    end
    
endmodule

module split_2_2 (
    l0, l1,
    r0, r1,
    a0, a1, a2, a3
);
    input [7:0] l0, l1;
    input [7:0] r0, r1;
    output reg [7:0] a0, a1, a2, a3;
    
    always @(*) begin
        if (l0 >= r0) begin
            a0 = l0;
            if (l1 >= r0)
                {a1, a2, a3} = {l1, r0, r1};
            else begin
                a1 = r0;
                {a2, a3} = (l1 >= r1)? {l1, r1} : {r1, l1};
            end
        end
        else begin
            a0 = r0;
            if (l0 >= r1) begin
                a1 = l0;
                {a2, a3} = (l1 >= r1)? {l1, r1} : {r1, l1};
            end
            else
                {a1, a2, a3} = {r1, l0, l1};
        end
    end
endmodule

module merge_8(
    l0, l1, l2, l3,
    r0, r1, r2, r3,
    a0, a1, a2, a3, a4, a5, a6, a7 
);
    input [7:0] l0, l1, l2, l3;
    input [7:0] r0, r1, r2, r3;
    output reg [7:0] a0, a1, a2, a3, a4, a5, a6, a7;

    always @(*) begin
        if (l0 >= r0) begin
            a0 = l0;
            if (l1 >= r0) begin
                a1 = l1;
                if (l2 >= r0) begin
                    a2 = l2;
                    if (l3 >= r0)
                        {a3, a4, a5, a6, a7} = {l3, r0, r1, r2, r3};
                    else begin
                        a3 = r0;
                        if (l3 >= r1)
                            {a4, a5, a6, a7} = {l3, r1, r2, r3};
                        else begin
                            a4 = r1;
                            if (l3 >= r2)
                                {a5, a6, a7} = {l3, r2, r3};
                            else begin
                                a5 = r2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                        end
                    end
                end
                else begin //l0, l1, r0
                    a2 = r0;
                    if (l2 >= r1) begin
                        a3 = l2;
                        if (l3 >= r1)
                            {a4, a5, a6, a7} = {l3, r1, r2, r3};
                        else begin
                            a4 = r1;
                            if (l3 >= r2)
                                {a5, a6, a7} = {l3, r2, r3};
                            else begin
                                a5 = r2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end 
                        end
                    end
                    else begin //l0, l1, r0, r1
                        a3 = r1;
                        if (l2 >= r2) begin
                            a4 = l2;
                            if (l3 >= r2) 
                                {a5, a6, a7} = {l3, r2, r3};
                            else begin
                                a5 = r2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                        end
                        else begin
                            a4 = r2;
                            if (l2 >= r3) begin
                                a5 = l2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                            else
                                {a5, a6, a7} = {r3, l2, l3};
                        end
                    end
                end
            end
            else begin //l0, r0
                a1 = r0;
                if (l1 >= r1) begin
                    a2 = l1;
                    if (l2 >= r1) begin
                        a3 = l2;
                        if (l3 >= r1)
                            {a4, a5, a6, a7} = {l3, r1, r2, r3};
                        else begin
                            a4 = r1;
                            if (l3 >= r2) 
                                {a5, a6, a7} = {l3, r2, r3};
                            else begin
                                a5 = r2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                        end
                    end
                    else begin //l0, r0, l1, r1
                        a3 = r1;
                        if (l2 >= r2) begin
                            a4 = l2;
                            if (l3 >= r2)
                                {a5, a6, a7} = {l3, r2, r3};
                            else begin
                                a5 = r2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                        end
                        else begin
                            a4 = r2;
                            if (l2 >= r3) begin
                                a5 = l2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                            else
                                {a5, a6, a7} = {r3, l2, l3};
                        end
                    end
                end
                else begin //l0, r0, r1
                    a2 = r1;
                    if (l1 >= r2) begin
                        a3 = l1;
                        if (l2 >= r2) begin
                            a4 = l2;
                            if (l3 >= r2)
                                {a5, a6, a7} = {l3, r2, r3};
                            else begin
                                a5 = r2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                        end
                        else begin
                            a4 = r2;
                            if (l2 >= r3) begin
                                a5 = l2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                            else
                                {a5, a6, a7} = {r3, l2, l3};
                        end
                    end
                    else begin //l0, r0, r1, r2
                        a3 = r2;
                        if (l1 >= r3) begin
                            a4 = l1;
                            if (l2 >= r3) begin
                                a5 = l2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                            else
                                {a5, a6, a7} = {r3, l2, l3};
                        end
                        else
                            {a4, a5, a6, a7} = {r3, l1, l2, l3};
                    end
                end
            end
        end
        else begin
            a0 = r0;
            if (l0 >= r1) begin
                a1 = l0;
                if (l1 >= r1) begin
                    a2 = l1;
                    if (l2 >= r1) begin
                        a3 = l2;
                        if (l3 >= r1)
                            {a4, a5, a6, a7} = {l3, r1, r2, r3};
                        else begin
                            a4 = r1;
                            if (l3 >= r2)
                                {a5, a6, a7} = {l3, r2, r3};
                            else begin
                                a5 = r2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                        end
                    end
                    else begin //r0, l0, l1, r1
                        a3 = r1;
                        if (l2 >= r2) begin
                            a4 = l2;
                            if (l3 >= r2)
                                {a5, a6, a7} = {l3, r2, r3};
                            else begin
                                a5 = r2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                        end
                        else begin
                            a4 = r2;
                            if (l2 >= r3) begin
                                a5 = l2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                            else
                                {a5, a6, a7} = {r3, l2, l3};
                        end
                    end
                end
                else begin //r0, l0, r1
                    a2 = r1;
                    if (l1 >= r2) begin
                        a3 = l1;
                        if (l2 >= r2) begin
                            a4 = l2;
                            if (l3 >= r2)
                                {a5, a6, a7} = {l3, r2, r3};
                            else begin
                                a5 = r2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                        end
                        else begin
                            a4 = r2;
                            if (l2 >= r3) begin
                                a5 = l2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                            else
                                {a5, a6, a7} = {r3, l2, l3};
                        end
                    end
                    else begin // r0, l0, r1, r2
                        a3 = r2;
                        if (l1 >= r3) begin
                            a4 = l1;
                            if (l2 >= r3) begin
                                a5 = l2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                            else
                                {a5, a6, a7} = {r3, l2, l3};
                        end
                        else
                            {a4, a5, a6, a7} = {r3, l1, l2, l3};
                    end
                end
            end
            else begin
                a1 = r1;
                if (l0 >= r2) begin //r0, r1, l0
                    a2 = l0;
                    if (l1 >= r2) begin // r0, r1, l0, l1
                        a3 = l1;
                        if (l2 >= r2) begin
                            a4 = l2;
                            if (l3 >= r2)
                                {a5, a6, a7} = {l3, r2, r3};
                            else begin
                                a5 = r2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                        end
                        else begin
                            a4 = r2;
                            if (l2 >= r3) begin
                                a5 = l2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                            else
                                {a5, a6, a7} = {r3, l2, l3};
                        end
                    end
                    else begin //r0, r1, l0, r2
                        a3 = r2;
                        if (l1 >= r3) begin
                            a4 = l1;
                            if (l2 >= r3) begin
                                a5 = l2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                            else
                                {a5, a6, a7} = {r3, l2, l3};
                        end
                        else
                            {a4, a5, a6, a7} = {r3, l1, l2, l3};
                    end
                end
                else begin //r0, r1, r2
                    a2 = r2;
                    if (l0 >= r3) begin // r0, r1, r2, l0
                        a3 = l0;
                        if (l1 >= r3) begin
                            a4 = l1;
                            if (l2 >= r3) begin
                                a5 = l2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                            else
                                {a5, a6, a7} = {r3, l2, l3};
                        end
                        else
                            {a4, a5, a6, a7} = {r3, l1, l2, l3};
                    end
                    else begin
                        {a3, a4, a5, a6, a7} = {r3, l0, l1, l2, l3};
                    end
                end
            end
        end
    end
endmodule

module merge_4(
    l0, l1,
    r0, r1,
    a0, a1, a2, a3
);
    input [7:0] l0, l1;
    input [7:0] r0, r1;
    output reg [7:0] a0, a1, a2, a3;

    always @(*) begin
        if (l0 >= r0) begin
            a0 = l0;
            if (l1 >= r0) begin
                a1 = l1;
                a2 = r0;
                a3 = r1;
            end
            else begin
                a1 = r0;
                {a2, a3} = (l1 >= r1)? {l1, r1} : {r1, l1};
            end
        end
        else begin
            a0 = r0;
            if (l0 >= r1) begin
                a1 = l0;
                {a2, a3} = (l1 >= r1)? {l1, r1} : {r1, l1};
            end
            else begin
                a1 = r1;
                a2 = l0;
                a3 = l1;
            end
        end
    end

endmodule

module merge_sort_4(
    a0, a1, a2, a3,
    b0, b1, b2, b3
);
    input [7:0] a0, a1, a2, a3;
    output [7:0] b0, b1, b2, b3;

    wire [7:0] l0, l1;
    wire [7:0] r0, r1;

    assign {l0, l1} = (a0 >= a1)? {a0, a1} : {a1, a0};
    assign {r0, r1} = (a2 >= a3)? {a2, a3} : {a3, a2};

    merge_4 merge(
        l0, l1,
        r0, r1,
        b0, b1, b2, b3
    );

endmodule

module merge_sort(
    a0, a1, a2, a3, a4, a5, a6, a7,
    b0, b1, b2, b3, b4, b5, b6, b7
);

    input [7:0] a0, a1, a2, a3, a4, a5, a6, a7;
    output [7:0] b0, b1, b2, b3, b4, b5, b6, b7;

    wire [7:0] l0, l1, l2, l3;
    wire [7:0] r0, r1, r2, r3;

    merge_sort_4 sort_left(
        a0, a1, a2, a3,
        l0, l1, l2, l3
    );

    merge_sort_4 sort_right(
        a4, a5, a6, a7,
        r0, r1, r2, r3
    );

    merge_8 merge(
        l0, l1, l2, l3,
        r0, r1, r2, r3,
        b0, b1, b2, b3, b4, b5, b6, b7
    );

endmodule

module mod_LUT (
    input [7:0] dividend,
    output reg q
);
always @(*) begin
    case (dividend)
		0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140: q = 1;
		default: q = 0;
	endcase
end

endmodule

module SSC(
    // Input signals
    card_num,
    input_money,
    snack_num,
    price, 
    // Output signals
    out_valid,
    out_change
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [63:0] card_num;
input [8:0] input_money;
input [31:0] snack_num;
input [31:0] price;
output out_valid;
output reg [8:0] out_change;

//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment
//wire [3:0]  ctmp0, ctmp1, ctmp2, ctmp3, ctmp4, ctmp5, ctmp6, ctmp7;
wire [3:0] ctmp [0:7];
wire [7:0] valid_num;

wire [7:0]  mul [0:7];
/*wire [7:0]  t00, t01, t02, t03, t04, t05, t06, t07;
wire [7:0]  t10, t11, t12, t13, t14, t15, t16, t17;*/
wire [7:0]  t20, t27;/*t21, t22, t23, t24, t25, t26, t27;
wire [7:0]  t32, t34, t33, t35;
wire [7:0]  t41, t44, t43, t46;*/
wire [7:0]  t51, t52, t53, t54, t55, t56;

//bit[9] for checking if buying is done
wire [8:0] change0, change1, change2, change3, change4, change5, change6, change7;
wire [7:0] branch;

//================================================================
//    DESIGN
//================================================================
/*shift_LUT s0 (card_num[63:60], ctmp[0]);
shift_LUT s1 (card_num[55:52], ctmp[1]);
shift_LUT s2 (card_num[47:44], ctmp[2]);
shift_LUT s3 (card_num[39:36], ctmp[3]);
shift_LUT s4 (card_num[31:28], ctmp[4]);
shift_LUT s5 (card_num[23:20], ctmp[5]);
shift_LUT s6 (card_num[15:12], ctmp[6]);
shift_LUT s7 (card_num[7:4], ctmp[7]);*/

assign ctmp[0] = {card_num[63:60], 1'd0} - ((card_num[63:60] >= 4'd5)? 4'd9 : 4'd0);
assign ctmp[1] = {card_num[55:52], 1'd0} - ((card_num[55:52] >= 4'd5)? 4'd9 : 4'd0);
assign ctmp[2] = {card_num[47:44], 1'd0} - ((card_num[47:44] >= 4'd5)? 4'd9 : 4'd0);
assign ctmp[3] = {card_num[39:36], 1'd0} - ((card_num[39:36] >= 4'd5)? 4'd9 : 4'd0);
assign ctmp[4] = {card_num[31:28], 1'd0} - ((card_num[31:28] >= 4'd5)? 4'd9 : 4'd0);
assign ctmp[5] = {card_num[23:20], 1'd0} - ((card_num[23:20] >= 4'd5)? 4'd9 : 4'd0);
assign ctmp[6] = {card_num[15:12], 1'd0} - ((card_num[15:12] >= 4'd5)? 4'd9 : 4'd0);
assign ctmp[7] = {card_num[7:4], 1'd0} - ((card_num[7:4] >= 4'd5)? 4'd9 : 4'd0);


assign valid_num = (((card_num[59:56] + card_num[51:48]) + (card_num[43:40] + card_num[35:32])) +
                    ((card_num[27:24] + card_num[19:16]) + (card_num[11:8] + card_num[3:0]))) +
                   (((ctmp[0] + ctmp[1]) + (ctmp[2] + ctmp[3])) + ((ctmp[4] + ctmp[5]) + (ctmp[6] + ctmp[7])));
/*assign add0 = card_num[59:56] + card_num[51:48];
assign add1 = card_num[43:40] + card_num[35:32];
assign add2 = card_num[27:24] + card_num[19:16];
assign add3 = card_num[11:8] + card_num[3:0];
assign add4 = ctmp0 + ctmp1;
assign add5 = ctmp2 + ctmp3;
assign add6 = ctmp4 + ctmp5;
assign add7 = ctmp6 + ctmp7;

assign add20 = add0 + add1;
assign add21 = add2 + add3;
assign add22 = add4 + add5;
assign add23 = add6 + add7;

assign add30 = add20 + add21;
assign add31 = add22 + add23;

assign valid_num = add30 + add31;*/

mod_LUT mod (valid_num, out_valid);

/*assign add0 = card_num[59:56] + card_num[51:48];
assign add1 = card_num[43:40] + card_num[35:32];
assign add2 = card_num[27:24] + card_num[19:16];
assign add3 = card_num[11:8] + card_num[3:0];
assign add4 = ctmp0 + ctmp1;
assign add5 = ctmp2 + ctmp3;
assign add6 = ctmp4 + ctmp5;
assign add7 = ctmp6 + ctmp7;

assign add20 = ((add0 >= 5'd10)? add0 - 5'd10 : add0) + ((add1 >= 5'd10)? add1 - 5'd10 : add1);
assign add21 = ((add2 >= 5'd10)? add2 - 5'd10 : add2) + ((add3 >= 5'd10)? add3 - 5'd10 : add3);
assign add22 = ((add4 >= 5'd10)? add4 - 5'd10 : add4) + ((add5 >= 5'd10)? add5 - 5'd10 : add5);
assign add23 = ((add6 >= 5'd10)? add6 - 5'd10 : add6) + ((add7 >= 5'd10)? add7 - 5'd10 : add7);

assign add30 = ((add20 >= 5'd10)? add20 - 5'd10 : add20) + ((add21 >= 5'd10)? add21 - 5'd10 : add21);
assign add31 = ((add22 >= 5'd10)? add22 - 5'd10 : add22) + ((add23 >= 5'd10)? add23 - 5'd10 : add23);

assign valid_num = ((add30 >= 5'd10)? add30 - 5'd10 : add30) + ((add31 >= 5'd10)? add31 - 5'd10 : add31);

assign out_valid = (valid_num == 5'd10) || (valid_num == 5'd0);*/

/*assign out_valid = ((((valid_num == 8'd0) || (valid_num == 8'd10)) || ((valid_num == 8'd20) || (valid_num == 8'd30))) ||
        (((valid_num == 8'd40) || (valid_num == 8'd50)) || ((valid_num == 8'd60) || (valid_num == 8'd70)))) || ((((valid_num == 8'd80) ||
        (valid_num == 8'd90)) || ((valid_num == 8'd100) || (valid_num == 8'd110))) || (((valid_num == 8'd120) || (valid_num == 8'd130)) ||
        (valid_num == 8'd140)));*/

assign mul[0] = snack_num[31:28] * price[31:28];
assign mul[1] = snack_num[27:24] * price[27:24];
assign mul[2] = snack_num[23:20] * price[23:20];
assign mul[3] = snack_num[19:16] * price[19:16];
assign mul[4] = snack_num[15:12] * price[15:12];
assign mul[5] = snack_num[11:8] * price[11:8];
assign mul[6] = snack_num[7:4] * price[7:4];
assign mul[7] = snack_num[3:0] * price[3:0];
/*assign mul[0] = 8'd158;
assign mul[1] = 8'd34;
assign mul[2] = 8'd49;
assign mul[3] = 8'd133;
assign mul[4] = 8'd224;
assign mul[5] = 8'd200;
assign mul[6] = 8'd67;
assign mul[7] = 8'd187;*/

/*assign {t00, t02} = (mul[0] >= mul[2])? {mul[0], mul[2]} : {mul[2], mul[0]};
assign {t01, t03} = (mul[1] >= mul[3])? {mul[1], mul[3]} : {mul[3], mul[1]};
assign {t04, t06} = (mul[4] >= mul[6])? {mul[4], mul[6]} : {mul[6], mul[4]};
assign {t05, t07} = (mul[5] >= mul[7])? {mul[5], mul[7]} : {mul[7], mul[5]};

assign {t10, t14} = (t00 >= t04)? {t00, t04} : {t04, t00};
assign {t11, t15} = (t01 >= t05)? {t01, t05} : {t05, t01};
assign {t12, t16} = (t02 >= t06)? {t02, t06} : {t06, t02};
assign {t13, t17} = (t03 >= t07)? {t03, t07} : {t07, t03};

assign {t20, t21} = (t10 >= t11)? {t10, t11} : {t11, t10};
assign {t22, t23} = (t12 >= t13)? {t12, t13} : {t13, t12};
assign {t24, t25} = (t14 >= t15)? {t14, t15} : {t15, t14};
assign {t26, t27} = (t16 >= t17)? {t16, t17} : {t17, t16};

assign {t32, t34} = (t22 >= t24)? {t22, t24} : {t24, t22};
assign {t33, t35} = (t23 >= t25)? {t23, t25} : {t25, t23};

assign {t41, t44} = (t21 >= t34)? {t21, t34} : {t34, t21};
assign {t43, t46} = (t33 >= t26)? {t33, t26} : {t26, t33};

assign {t51, t52} = (t41 >= t32)? {t41, t32} : {t32, t41};
assign {t53, t54} = (t43 >= t44)? {t43, t44} : {t44, t43};
assign {t55, t56} = (t35 >= t46)? {t35, t46} : {t46, t35};*/

merge_sort sort (
        mul[0], mul[1], mul[2], mul[3], mul[4], mul[5], mul[6], mul[7],
        t20, t51, t52, t53, t54, t55, t56, t27
);

/*assign change0 = (input_money >= t20)? {1'd0, input_money - t20} : {1'd1, input_money};
assign change1 = (change0[9])? change0 : (change0[8:0] >= t51)? {1'd0, change0[8:0] - t51} : {1'd1, change0[8:0]};
assign change2 = (change1[9])? change1 : (change1[8:0] >= t52)? {1'd0, change1[8:0] - t52} : {1'd1, change1[8:0]};
assign change3 = (change2[9])? change2 : (change2[8:0] >= t53)? {1'd0, change2[8:0] - t53} : {1'd1, change2[8:0]};
assign change4 = (change3[9])? change3 : (change3[8:0] >= t54)? {1'd0, change3[8:0] - t54} : {1'd1, change3[8:0]};
assign change5 = (change4[9])? change4 : (change4[8:0] >= t55)? {1'd0, change4[8:0] - t55} : {1'd1, change4[8:0]};
assign change6 = (change5[9])? change5 : (change5[8:0] >= t56)? {1'd0, change5[8:0] - t56} : {1'd1, change5[8:0]};

assign out_change = (!out_valid)? input_money : 
        (change6[9])? change6[8:0] : (change6[8:0] >= t27)? change6[8:0] - t27 : change6[8:0];*/

/*assign change0 = {1'd1, input_money} - ((input_money >= t20)? t20 : 10'b1000000000);
assign change1 = (!change0[9])? change0 : change0 - ((change0[8:0] >= t51)? t51 : 10'b1000000000);
assign change2 = (!change1[9])? change1 : change1 - ((change1[8:0] >= t52)? t52 : 10'b1000000000);
assign change3 = (!change2[9])? change2 : change2 - ((change2[8:0] >= t53)? t53 : 10'b1000000000);
assign change4 = (!change3[9])? change3 : change3 - ((change3[8:0] >= t54)? t54 : 10'b1000000000);
assign change5 = (!change4[9])? change4 : change4 - ((change4[8:0] >= t55)? t55 : 10'b1000000000);
assign change6 = (!change5[9])? change5 : change5 - ((change5[8:0] >= t56)? t56 : 10'b1000000000);

assign out_change = (!out_valid)? input_money : 
        (!change6[9])? change6[8:0] : change6[8:0] - ((change6[8:0] >= t27)? t27 : 9'd0);*/

assign change0 = input_money - t20;
assign change1 = change0 - t51;
assign change2 = change1 - t52;
assign change3 = change2 - t53;
assign change4 = change3 - t54;
assign change5 = change4 - t55;
assign change6 = change5 - t56;
assign change7 = change6 - t27;

assign branch[7] = input_money <= change0;
assign branch[6] = branch[7] || (change0 <= change1);
assign branch[5] = branch[6] || (change1 <= change2);
assign branch[4] = branch[5] || (change2 <= change3);
assign branch[3] = branch[4] || (change3 <= change4);
assign branch[2] = branch[3] || (change4 <= change5);
assign branch[1] = branch[2] || (change5 <= change6);
assign branch[0] = branch[1] || (change6 <= change7);

always @(*) begin
    if (out_valid) begin
        case (branch)
            8'b01111111: out_change = change0;
            8'b00111111: out_change = change1;
            8'b00011111: out_change = change2;
            8'b00001111: out_change = change3;
            8'b00000111: out_change = change4;
            8'b00000011: out_change = change5;
            8'b00000001: out_change = change6;
            8'b00000000: out_change = change7;
            default: out_change = input_money;
        endcase
    end
    else
        out_change = input_money;
end

endmodule
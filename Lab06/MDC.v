//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2024/9
//		Version		: v1.0
//   	File Name   : MDC.v
//   	Module Name : MDC
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "HAMMING_IP.v"
//synopsys translate_on

module MDC(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_data, 
	in_mode,
    // Output signals
    out_valid, 
	out_data
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [8:0] in_mode;
input [14:0] in_data;

output reg out_valid;
output reg [206:0] out_data;

integer i;
reg [10:0] in_data_decode;
reg [4:0] in_mode_decode;
reg [4:0] cnt, n_cnt;
reg [1:0] mode;
reg signed [10:0] mul_11b_A [0:2];
reg signed [10:0] mul_11b_B [0:2];
reg signed [21:0] mul_11b_out [0:2];
reg signed [21:0] sub_22b_A [0:2];
reg signed [21:0] sub_22b_B [0:2];
reg signed [22:0] sub_22b_out [0:2];

reg signed [22:0] mul_23b_A [0:2];
reg signed [10:0] mul_23b_B [0:2];
reg signed [33:0] mul_23b_out [0:2];
reg signed [34:0] add_34b_A [0:2];
reg signed [33:0] add_34b_B [0:2];
reg signed [35:0] add_34b_out [0:2];

reg signed [35:0] mul_36b_A;
reg signed [10:0] mul_36b_B;
reg signed [46:0] mul_36b_out;
reg signed [48:0] add_47b_A;
reg signed [46:0] add_47b_B;
reg signed [48:0] add_47b_out;
reg [22:0] reg_2x2 [0:6];
reg [35:0] reg_3x3 [0:2];
reg signed [48:0] reg_4x4;
reg [10:0] in_data_ff;

HAMMING_IP #(.IP_BIT(11)) hamming_11(.IN_code(in_data), .OUT_code(in_data_decode));
HAMMING_IP #(.IP_BIT(5)) hamming_8(.IN_code(in_mode), .OUT_code(in_mode_decode));

always @(posedge clk) begin
    in_data_ff <= in_data_decode;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt <= 0; 
        out_valid <= 1'd0;
    end
    else begin
        cnt <= n_cnt;
        if (cnt == 5'd16) begin
            out_valid <= 1'd1;
        end
        else
            out_valid <= 1'd0;
    end
end

// always @(*) begin
//     if (cnt == 4'd15) begin
//         out_valid = 1;
//     end
//     else
//         out_valid = 0;
// end

always @(*) begin
    if (in_valid)
        n_cnt = cnt + 1;//(cnt <= 4'd14)? cnt + 1 : 0;
    else
        n_cnt = 0;
end

always @(posedge clk) begin
    mode <= (in_valid && !cnt)? {in_mode_decode[4], in_mode_decode[1]}  : mode;
    //$display("cnt = %d, mode = %d", cnt, mode);
end

always @(*) begin
    for (i = 0; i < 3; i = i + 1) begin
        mul_11b_out[i] = mul_11b_A[i] * mul_11b_B[i];
    end
end

always @(*) begin
    for (i = 0; i < 3; i = i + 1) begin
        mul_23b_out[i] = mul_23b_A[i] * mul_23b_B[i];
    end
end

reg [4:0] _cnt;
assign _cnt = cnt - 1;

always @(*) begin
    case (_cnt)
        5'd4: mul_11b_A[0] = reg_2x2[0][21:11]; //1*4
        5'd5: mul_11b_A[0] = reg_2x2[0][10:0]; //0*5
        5'd6: mul_11b_A[0] = reg_2x2[0][10:0]; //0*6
        5'd7: mul_11b_A[0] = reg_2x2[0][21:11]; //1*7
        5'd8: mul_11b_A[0] = reg_2x2[2][21:11]; //5*8
        5'd9: mul_11b_A[0] = reg_2x2[2][10:0]; //4*9
        5'd10: mul_11b_A[0] = reg_2x2[2][10:0]; //4*A
        5'd11: mul_11b_A[0] = reg_2x2[2][21:11]; //5*B

        //for 2x2
        5'd12: mul_11b_A[0] = reg_4x4[21:11]; //9*C
        5'd13: mul_11b_A[0] = reg_4x4[10:0]; //8*D
        5'd14: mul_11b_A[0] = reg_4x4[43:33]; //B*E
        5'd15: mul_11b_A[0] = reg_4x4[32:22]; //A*F
        default: mul_11b_A[0] = reg_4x4[32:22]; //A*F
    endcase
end

always @(*) begin
    case (_cnt)
        5'd4: mul_11b_A[1] = reg_2x2[1][10:0]; //2*4
        5'd5: mul_11b_A[1] = reg_2x2[1][10:0]; //2*5
        5'd6: mul_11b_A[1] = reg_2x2[0][21:11]; //1*6
        5'd7: mul_11b_A[1] = reg_2x2[1][10:0]; //2*7
        5'd8: mul_11b_A[1] = reg_2x2[1][21:11]; //6*8
        5'd9: mul_11b_A[1] = reg_2x2[1][21:11]; //6*9
        5'd10: mul_11b_A[1] = reg_2x2[2][21:11]; //5*A
        5'd11: mul_11b_A[1] = reg_2x2[1][21:11]; //6*B

        //for 2x2
        5'd13: mul_11b_A[1] = reg_4x4[32:22]; //A*D
        5'd14: mul_11b_A[1] = reg_4x4[21:11]; //9*E
        default: mul_11b_A[1] = reg_4x4[21:11]; //9*E
    endcase
end

always @(*) begin
    case (_cnt)
        5'd4: mul_11b_A[2] = reg_2x2[1][21:11]; //3*4
        5'd5: mul_11b_A[2] = reg_2x2[1][21:11]; //3*5
        5'd6: mul_11b_A[2] = reg_2x2[1][21:11]; //3*6
        5'd7: mul_11b_A[2] = reg_2x2[0][10:0]; //0*7
        5'd9: mul_11b_A[2] = reg_2x2[1][10:0]; //7*9
        5'd10: mul_11b_A[2] = reg_2x2[1][10:0]; //7*A
        default: mul_11b_A[2] = reg_2x2[1][10:0]; //7*A
    endcase
end

always @(*) begin
    mul_11b_B[0] = in_data_ff;
    mul_11b_B[1] = in_data_ff;
    mul_11b_B[2] = in_data_ff;
end

always @(*) begin
    for (i = 0; i < 3; i = i + 1) begin
        mul_23b_A[i] = 0;
    end
    case (_cnt)
        4'd8: begin
            mul_23b_A[0] = reg_2x2[4]; //1256
            mul_23b_A[1] = reg_4x4[45:23]; //1735
            mul_23b_A[2] = sub_22b_out[1]; //2367
        end
        4'd9: begin
            mul_23b_A[0] = (mode[1])? reg_2x2[6] : reg_4x4[22:0]; //0246
            mul_23b_A[1] = reg_2x2[0]; //2367
            mul_23b_A[2] = reg_2x2[5]; //0347
        end
        4'd10: begin
            mul_23b_A[0] = reg_2x2[3]; //0145
            mul_23b_A[1] = (mode[1])? reg_2x2[0] : reg_4x4[45:23]; //1735
            mul_23b_A[2] = reg_2x2[5]; //0347
        end
        4'd11: begin
            mul_23b_A[0] = reg_2x2[4]; //1256
            mul_23b_A[1] = (mode[1])? reg_2x2[6] : reg_4x4[22:0]; //0624
            mul_23b_A[2] = reg_2x2[3]; //0145
        end

        //for 3x3
        4'd12: mul_23b_A[0] = reg_2x2[0]; //569A
        4'd13: begin
            mul_23b_A[0] = reg_2x2[5]; //468A
            mul_23b_A[1] = reg_2x2[3]; //67AB
        end
        4'd14: begin
            mul_23b_A[0] = reg_2x2[6]; //4589
            mul_23b_A[1] = reg_2x2[4]; //579B
        end
        4'd15: mul_23b_A[0] = reg_2x2[0]; //569A
        default: begin
            for (i = 0; i < 3; i = i + 1) begin
                mul_23b_A[i] = 0;
            end
        end 
    endcase
end

always @(*) begin
    for (i = 0; i < 3; i = i + 1) begin
        mul_23b_B[i] = in_data_ff;
    end
end

always @(*) begin
    case (_cnt)
        4'd12: mul_36b_A = reg_4x4[35:0];
        4'd13: mul_36b_A = reg_3x3[2];
        4'd14: mul_36b_A = reg_3x3[1];
        4'd15: mul_36b_A = reg_3x3[0];
        default: mul_36b_A = reg_3x3[0];
    endcase
end

always @(*) begin
    mul_36b_B = in_data_ff;
    mul_36b_out = mul_36b_A * mul_36b_B;
end

always @(*) begin
    case (_cnt)
        5'd5: {sub_22b_A[0], sub_22b_B[0]} = {mul_11b_out[0], reg_2x2[4][21:0]}; //5*0 - 4*1
        5'd6: {sub_22b_A[0], sub_22b_B[0]} = {mul_11b_out[0], reg_2x2[5][21:0]}; //6*0 - 4*2
        5'd7: {sub_22b_A[0], sub_22b_B[0]} = {mul_11b_out[0], reg_3x3[1][21:0]}; //7*1 - 5*3
        5'd9: begin
            if(mode)
                {sub_22b_A[0], sub_22b_B[0]} = {mul_11b_out[0], reg_2x2[6][21:0]}; //9*4 - 8*5
            else
                {sub_22b_A[0], sub_22b_B[0]} = {mul_11b_out[0], reg_3x3[0][21:0]}; //9*4 - 8*5
        end
        5'd10: begin
            if(mode)
                {sub_22b_A[0], sub_22b_B[0]} = {mul_11b_out[1], reg_2x2[0][21:0]}; //A*5 - 9*6
            else
                {sub_22b_A[0], sub_22b_B[0]} = {mul_11b_out[1], reg_3x3[1][21:0]}; //A*5 - 9*6
        end
        5'd11: begin
            if(mode == 2'd1)
                {sub_22b_A[0], sub_22b_B[0]} = {mul_11b_out[1], reg_2x2[3][21:0]}; //B*6 - A*7
            else
                {sub_22b_A[0], sub_22b_B[0]} = {mul_11b_out[1], reg_3x3[2][21:0]}; //B*6 - A*7
        end
        5'd13: {sub_22b_A[0], sub_22b_B[0]} = {mul_11b_out[0], reg_2x2[1][21:0]}; //D*8 - C*9
        5'd14: {sub_22b_A[0], sub_22b_B[0]} = {mul_11b_out[1], reg_2x2[2][21:0]}; //E*9 - D*A
        5'd15: {sub_22b_A[0], sub_22b_B[0]} = {mul_11b_out[0], reg_2x2[5][21:0]}; //F*A - E*B
        default: {sub_22b_A[0], sub_22b_B[0]} = {mul_11b_out[0], reg_2x2[5][21:0]};
    endcase
    sub_22b_out[0] = sub_22b_A[0] - sub_22b_B[0];
end

always @(*) begin
    case (_cnt)
        5'd6: {sub_22b_A[1], sub_22b_B[1]} = {mul_11b_out[1], reg_3x3[0][21:0]}; //6*1 - 5*2
        5'd7: {sub_22b_A[1], sub_22b_B[1]} = {mul_11b_out[2], reg_2x2[6][21:0]}; //7*0 - 4*3
        5'd8: {sub_22b_A[1], sub_22b_B[1]} = {reg_2x2[0][21:0], reg_3x3[2][21:0]}; //7*2 - 6*3
        5'd10: {sub_22b_A[1], sub_22b_B[1]} = {mul_11b_out[0], reg_2x2[5][21:0]}; //A*4 - 8*6
        5'd11: {sub_22b_A[1], sub_22b_B[1]} = {mul_11b_out[0], reg_4x4[21:0]}; //B*5 - 9*7
        default: {sub_22b_A[1], sub_22b_B[1]} = {mul_11b_out[0], reg_4x4[21:0]};
    endcase
    sub_22b_out[1] = sub_22b_A[1] - sub_22b_B[1];
end

always @(*) begin
    case (_cnt)
        4'd9: {add_34b_A[0], add_34b_B[0]} = {reg_3x3[0][33], reg_3x3[0][33:0], -(mul_23b_out[0])}; //8*(1256) - 9*(0246)
        4'd10: {add_34b_A[0], add_34b_B[0]} = {reg_3x3[0][34:0], mul_23b_out[0]}; //8*(1256) - 9*(0246) + A*(0145)
        4'd11: {add_34b_A[0], add_34b_B[0]} = {reg_3x3[2][34:0], mul_23b_out[1]}; //8*(2367) - A*(0347) + B*(0624)

        4'd13: {add_34b_A[0], add_34b_B[0]} = {reg_3x3[2][33], reg_3x3[2][33:0], -(mul_23b_out[0])}; //C*(569A) - D*(468A)
        4'd14: {add_34b_A[0], add_34b_B[0]} = {reg_3x3[2][34:0], mul_23b_out[0]}; //C*(569A) - D*(468A) + E*(4589)
        default: {add_34b_A[0], add_34b_B[0]} = {reg_3x3[2][34:0], mul_23b_out[0]};
    endcase
    add_34b_out[0] = add_34b_A[0] + add_34b_B[0];
end

always @(*) begin
    case (_cnt)
        4'd9: {add_34b_A[1], add_34b_B[1]} = {reg_4x4[33], reg_4x4[33:0], -(mul_23b_out[2])}; //8*(1735) - 9*(0347)
        4'd10: {add_34b_A[1], add_34b_B[1]} = {reg_3x3[2][33], reg_3x3[2][33:0], -(mul_23b_out[2])}; //8*(2367) - A*(0347)
        4'd11: {add_34b_A[1], add_34b_B[1]} = {reg_4x4[34:0], mul_23b_out[2]}; //8*(1735) - 9*(0347) + B*(0145)

        4'd14: {add_34b_A[1], add_34b_B[1]} = {reg_4x4[33], reg_4x4[33:0], -(mul_23b_out[1])}; //D*(67AB) - E*(5798)
        4'd15: {add_34b_A[1], add_34b_B[1]} = {reg_4x4[34:0], mul_23b_out[0]}; //D*(67AB) - E*(5798) + F*(569A)
        default: {add_34b_A[1], add_34b_B[1]} = {reg_4x4[34:0], mul_23b_out[0]};
    endcase
    add_34b_out[1] = add_34b_A[1] + add_34b_B[1];
end

always @(*) begin
    case (_cnt)
        4'd10: {add_34b_A[2], add_34b_B[2]} = {reg_3x3[1][33], reg_3x3[1][33:0], -(mul_23b_out[1])}; //9*(2367) - A*(1735)
        4'd11: {add_34b_A[2], add_34b_B[2]} = {reg_3x3[1][34:0], mul_23b_out[0]}; //9*(2367) - A*(1735) + B*(1256)
        default: {add_34b_A[2], add_34b_B[2]} = {reg_3x3[1][34:0], mul_23b_out[0]};
    endcase
    add_34b_out[2] = add_34b_A[2] + add_34b_B[2];
end

always @(*) begin
    case (_cnt)
        4'd13, 4'd15: {add_47b_A, add_47b_B} = {reg_4x4, mul_36b_out};
        4'd14: {add_47b_A, add_47b_B} = {reg_4x4, -(mul_36b_out)};
        default: {add_47b_A, add_47b_B} = {reg_4x4, -(mul_36b_out)};
    endcase
    add_47b_out = add_47b_A + add_47b_B;
end

always @(posedge clk) begin
    case (_cnt[3:0])
        4'd0: reg_2x2[0][10:0] <= in_data_ff;
        4'd1: reg_2x2[0][21:11] <= in_data_ff;
        4'd2: reg_2x2[1][10:0] <= in_data_ff;
        4'd3: reg_2x2[1][21:11] <= in_data_ff;
        4'd4: begin
            reg_2x2[2][10:0] <= in_data_ff;

            reg_2x2[4][21:0] <= mul_11b_out[0];  //1*4
            reg_2x2[5][21:0] <= mul_11b_out[1];  //2*4
            reg_2x2[6][21:0] <= mul_11b_out[2];  //3*4
        end
        4'd5: begin
            reg_2x2[2][21:11] <= in_data_ff;

            reg_3x3[0][21:0] <= mul_11b_out[1]; //2*5
            reg_3x3[1][21:0] <= mul_11b_out[2]; //3*5

            reg_2x2[3] <= sub_22b_out[0]; // 5*0 - 4*1
        end
        4'd6: begin
            reg_2x2[1][21:11] <= in_data_ff;

            reg_3x3[2][21:0] <= mul_11b_out[2]; //6*3

            reg_2x2[4] <= sub_22b_out[1]; //6*1 - 5*2
            reg_4x4[22:0] <= sub_22b_out[0]; //6*0 - 4*2
            // $display("0246 = %d", sub_22b_out[0]);
        end
        4'd7: begin
            reg_2x2[1][10:0] <= in_data_ff;

            reg_2x2[0][21:0] <= mul_11b_out[1]; //7*2

            reg_2x2[5] <= sub_22b_out[1]; //7*0 - 4*3
            reg_4x4[45:23] <= sub_22b_out[0]; //7*1 - 5*3
            //$display("0145 = %d", reg_2x2[3]);
        end
        4'd8: begin
            reg_2x2[0] <= sub_22b_out[1]; //7*2 - 6*3
            // $display("2367_orig = %d", sub_22b_out[1]);
            // $display("1256_orig = %d", reg_2x2[4]);
            if (mode[1] && mode[0]) begin
                //reg_2x2[6][21:0] <= mul_11b_out[0]; //8*5
                reg_2x2[6] <= reg_4x4[22:0]; //6*0 - 4*2
                reg_3x3[1][22:0] <= reg_4x4[45:23]; //7*1 - 5*3
                //reg_2x2[0] <= reg_4x4[45:23]; //7*1 - 5*3

                reg_3x3[0][33:0] <= mul_23b_out[0]; //8*(1256)
                reg_3x3[2][33:0] <= mul_23b_out[2]; //8*(2367)
                reg_4x4[33:0] <= mul_23b_out[1]; //8*(1735)
                // $display("8*(1256) = %d", mul_23b_out[0]);
            end
            else if (mode[0]) begin
                reg_2x2[6][21:0] <= mul_11b_out[0]; //8*5
                reg_2x2[5][21:0] <= mul_11b_out[1]; //8*6
                reg_3x3[0][33:0] <= mul_23b_out[0]; //8*(1256)
            end
            else begin
                reg_4x4[10:0] <= in_data_ff;
                reg_3x3[0][21:0] <= mul_11b_out[0]; //8*5
            end
        end
        4'd9: begin
            if (mode[1] && mode[0]) begin
                // reg_2x2[6] <= sub_22b_out[0];//9*4 - 8*5
                // reg_2x2[0][21:0] <= mul_11b_out[1];//9*6
                reg_2x2[0] <= reg_3x3[1][22:0];
                reg_3x3[0] <= add_34b_out[0]; //8*(1256) - 9*(0246)
                reg_3x3[1][33:0] <= mul_23b_out[1]; //9*(2367)
                reg_4x4[34:0] <= add_34b_out[1]; //8*(1735) - 9*(0347)
                // $display("2367 = %d", reg_3x3[1][22:0]);
                // $display("9*2367 = %d", mul_23b_out[1]);
                // $display("0246 = %d", reg_2x2[6]);
                // $display("8*(1256) - 9*(0246) = %d", add_34b_out[0]);
            end
            else if (mode[0]) begin
                reg_2x2[6] <= sub_22b_out[0]; //9*4 - 8*5
                reg_4x4[21:0] <= mul_11b_out[2]; //9*7
                reg_2x2[0][21:0] <= mul_11b_out[1]; //9*6

                reg_3x3[0] <= add_34b_out[0]; //8*(1256) - 9*(0246)
                reg_3x3[1][33:0] <= mul_23b_out[1]; //9*(2367)
                // $display("8-9 = %d", add_34b_out[0]);

            end
            else begin
                reg_4x4[21:11] <= in_data_ff;
                reg_3x3[0][22:0] <= sub_22b_out[0]; //8*5 - 9*4
                reg_3x3[1][21:0] <= mul_11b_out[1]; //9*6
            end   
        end
        4'd10: begin
            if (mode[1] && mode[0]) begin
                reg_2x2[0] <= sub_22b_out[0];//A*5 - 9*6 
                reg_2x2[2][21:0] <= mul_11b_out[2];//A*7

                reg_3x3[0] <= add_34b_out[0]; //8*(1256) - 9*(0246) + A*(0145)
                reg_3x3[1] <= add_34b_out[2]; //9*(2367) - A*(1735)
                reg_3x3[2] <= add_34b_out[1]; //8*(2367) - A*(0347)
                // $display("9*(2367) - A*(1735) = %d", add_34b_out[2]);
                // $display("8*(1256) - 9*(0246) + A*(0145) = %d", add_34b_out[0]);
            end
            else if (mode[0]) begin
                reg_2x2[5] <= sub_22b_out[1]; //A*4 - 8*6
                reg_2x2[3][21:0] <= mul_11b_out[2]; //A*7
                reg_2x2[0] <= sub_22b_out[0]; //A*5 - 9*6

                reg_3x3[0] <= add_34b_out[0]; //8*(1256) - 9*(0246) + A*(0145)
                reg_3x3[1] <= add_34b_out[2]; //9*(2367) - A*(1735)
                // $display("89A = %d", add_34b_out[0]);
            end
            else begin
                reg_4x4[32:22] <= in_data_ff;
                reg_3x3[1][22:0] <= sub_22b_out[0]; //A*5 - 9*6
                reg_3x3[2][21:0] <= mul_11b_out[2]; //A*7
                // $display("A*7_orig = %d", mul_11b_out[2]);
            end
        end
        4'd11: begin
            if (mode[1] && mode[0]) begin
                reg_3x3[2] <= add_34b_out[0]; //8*(2367) - A*(0347) + B*(0624)
                reg_3x3[1] <= add_34b_out[1]; //8*(1735) - 9*(0347) + B*(0145)
                reg_4x4[35:0] <= add_34b_out[2]; //9*(2367) - A*(1735) + B*(1256)
                // $display("B*(1256) = %d", mul_23b_out[0]);
                // $display("9*(2367) - A*(1735) + B*(1256) = %d", add_34b_out[2]);
                // $display("8*(2367) - A*(0347) + B*(0624) = %d", add_34b_out[0]);
                // $display("8*(1735) - 9*(0347) + B*(0145) = %d", add_34b_out[1]);
            end
            else if (mode[0]) begin
                reg_2x2[3] <= sub_22b_out[0]; //B*6 - A*7
                reg_2x2[4] <= sub_22b_out[1]; //B*5 - 9*7

                reg_3x3[1] <= add_34b_out[2]; //9*(2367) - A*(1735) + B*(1256)
                // $display("9AB = %d", add_34b_out[2]);
            end
            else begin
                reg_4x4[43:33] <= in_data_ff;
                reg_3x3[2][22:0] <= sub_22b_out[0]; //B*6 - A*7
                // $display("B*6 = %d", mul_11b_out[1]);
                // $display("A*7 = %d", reg_2x2[2][21:0]);
                // $display("B*6 - A*7 = %d", sub_22b_out[0]);
            end  
            
        end
        4'd12: begin
            if (mode[1] && mode[0]) begin
                reg_4x4 <= -(mul_36b_out); //C * rightup3x3
            end
            else if (mode[0]) begin
                reg_3x3[2][33:0] <= mul_23b_out[0]; //C*(569A)
            end
            else begin
                reg_2x2[1][21:0] <= mul_11b_out[0]; //C*9
            end  
        end
        4'd13: begin
            if (mode[1] && mode[0]) begin
                reg_4x4 <= add_47b_out; //C * rightup3x3 - D*(8AB)
                // $display("mul_36b_A = %d, mul_36b_B = %d", mul_36b_A, mul_36b_B);
                // $display("add_47b_out = %d", add_47b_out);
                // $display("")
            end
            else if (mode[0]) begin
                reg_3x3[2] <= add_34b_out[0]; //C*(569A) + D*(468A)
                reg_4x4[33:0] <= mul_23b_out[1];//D*(67AB)
                // $display("D*(67AB) = %d", add_23b_out[1]);
            end
            else begin
                reg_2x2[1] <= sub_22b_out[0]; //D*8 - C*9
                reg_2x2[2][21:0] <= mul_11b_out[1];//D*A
            end  
        end
        4'd14: begin
            if (mode[1] && mode[0]) begin
                reg_4x4 <= add_47b_out; //C * rightup3x3 - D*(8AB) + E*(89B)
            end
            else if (mode[0]) begin
                reg_3x3[2] <= add_34b_out[0]; //C*(569A) + D*(468A) + E*(4589)
                reg_4x4[35:0] <= add_34b_out[1];//D*(67AB) + E*(579B)
                // $display("CDE = %d", add_34b_out[0]);
                // $display("D+E = %d", add_34b_out[1]);
            end
            else begin
                reg_2x2[5][21:0] <= mul_11b_out[0];//E*B
                reg_2x2[2] <= sub_22b_out[0];//E*9 - D*A
            end  
        end
        4'd15: begin
            if (mode[1] && mode[0]) begin
                reg_4x4 <= add_47b_out; //C * rightup3x3 - D*(8AB) + E*(89B) - leftup3x3
                // $display("add_47b_out = %d", add_47b_out);
            end
            else if (mode[0]) begin
                reg_4x4[35:0] <= add_34b_out[1];//D*(67AB) + E*(579B) + F*(5698)
                // $display("DEF = %d", add_34b_out[1]);
            end
            else begin
                reg_2x2[5] <= sub_22b_out[0];//F*A - E*B
            end  
        end
        default: begin
            for (i = 0; i < 7; i = i + 1) begin
                reg_2x2[i] <= reg_2x2[i];
            end
        end
    endcase
end
//reg [206:0] temp_out;
always @(out_valid) begin
    out_data = 0;
    if (out_valid) begin
        case (mode)
            2'd0: out_data = {reg_2x2[3], reg_2x2[4], reg_2x2[0], reg_3x3[0][22:0], reg_3x3[1][22:0], reg_3x3[2][22:0], reg_2x2[1], reg_2x2[2], reg_2x2[5]};
            2'd1: out_data = {3'd0, {15{reg_3x3[0][35]}}, reg_3x3[0], {15{reg_3x3[1][35]}}, reg_3x3[1], {15{reg_3x3[2][35]}}, reg_3x3[2], {15{reg_4x4[35]}}, reg_4x4[35:0]};
            2'd3: out_data = {{158{reg_4x4[48]}}, reg_4x4};
            default: out_data = {{158{reg_4x4[48]}}, reg_4x4}; 
        endcase
    end
    else begin
        out_data = 0;
    end
end
//assign out_data = ()? temp_out : 0;
endmodule
/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: SA
// FILE NAME: SA.v
// VERSRION: 1.0
// DATE: Nov 06, 2024
// AUTHOR: Yen-Ning Tung, NYCU AIG
// CODE TYPE: RTL or Behavioral Level (Verilog)
// DESCRIPTION: 2024 Fall IC Lab / Exersise Lab08 / SA
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on


module SA(
    //Input signals
    clk,
    rst_n,
    cg_en,
    in_valid,
    T,
    in_data,
    w_Q,
    w_K,
    w_V,

    //Output signals
    out_valid,
    out_data
    );

input clk;
input rst_n;
input in_valid;
input cg_en;
input [3:0] T;
input signed [7:0] in_data;
input signed [7:0] w_Q;
input signed [7:0] w_K;
input signed [7:0] w_V;

output reg out_valid;
output reg signed [63:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
parameter read = 3'd0, compute = 3'd1, finish = 3'd2;
integer i;

//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [2:0] cs, ns;
reg [8:0] cnt, cnt_bound;
reg [7:0] compute_cnt;
reg [5:0] compute_cnt_8bit;
reg [5:0] compute_cnt_8bit_lastrow;
reg [7:0] QK_compute_cnt;
reg [5:0] out_cnt;
reg [3:0] T_tmp;
reg [1:0] T_type;
reg table_gate;

reg signed [7:0] X_data [0:63];
reg signed [7:0] K_data [0:63];
reg signed [7:0] Q_data [0:63];
reg signed [7:0] V_data [0:63];
reg signed [18:0] XK_data [0:63];
reg signed [18:0] XQ_data [0:63];
reg signed [18:0] XV_data [0:63];
reg signed [39:0] QK_data [0:63];

reg signed [39:0] pixelA_in [0:7];
reg signed [18:0] pixelB_in [0:7];
reg signed [61:0] partial_in [0:7];
reg signed [61:0] partial_out [0:7];
reg signed [61:0] partial_out_wire [0:7];
reg signed [7:0] pixelA_8bit_in [0:63];
reg signed [7:0] pixelB_8bit_in [0:63];
reg signed [18:0] partial_8bit_in [0:63];
reg signed [18:0] partial_8bit_out [0:63];
reg signed [18:0] partial_8bit_out_wire [0:63];
reg signed [40:0] div_in;
reg signed [39:0] div_out;

reg input_sleep_T_in;
reg input_clk_T_in;

reg input_sleep_div_in;
reg gated_clk_div_in;

reg input_sleep_X_in[0:63];
reg gated_clk_X_in[0:63];
reg sleep_cond_X_in[0:63];

reg input_sleep_K_in[0:63];
reg gated_clk_K_in[0:63];
reg sleep_cond_K_in[0:63];

reg input_sleep_Q_in[0:63];
reg gated_clk_Q_in[0:63];
reg sleep_cond_Q_in[0:63];

reg input_sleep_V_in[0:63];
reg gated_clk_V_in[0:63];
reg sleep_cond_V_in[0:63];

reg input_sleep_XK_in[0:63];
reg gated_clk_XK_in[0:63];
reg sleep_cond_XK_in[0:63];

reg input_sleep_XQ_in[0:63];
reg gated_clk_XQ_in[0:63];
reg sleep_cond_XQ_in[0:63];

reg input_sleep_XV_in[0:63];
reg gated_clk_XV_in[0:63];
reg sleep_cond_XV_in[0:63];

reg input_sleep_QK_in[0:63];
reg gated_clk_QK_in[0:63];
reg sleep_cond_QK_in[0:63];

reg input_sleep_pe_in[0:7];
reg gated_clk_pe_in[0:7];
reg sleep_cond_pe_in[0:63];

reg input_sleep_pe_8bit_in[0:63];
reg gated_clk_pe_8bit_in[0:63];
reg sleep_cond_pe_8bit_in[0:63];
//==============================================//
//                 GATED_OR                     //
//==============================================//
genvar k;

assign table_gate = (cnt)? 1 : 0;

always @*
    input_sleep_T_in = cnt && cg_en;
GATED_OR GATED_T_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_T_in),.RST_N(rst_n),.CLOCK_GATED(gated_clk_T_in));

generate
    for(k=0; k<64; k=k+1)begin: Gate_or_X
        always @*begin
            sleep_cond_X_in[k] = cnt == k;
            input_sleep_X_in[k] = !(sleep_cond_X_in[k]) && cg_en;
        end
         GATED_OR GATED_X_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_X_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_X_in[k]));
    end
endgenerate

generate
    for(k=0; k<64; k=k+1)begin: Input_register_X
        always@(posedge gated_clk_X_in[k] or negedge rst_n)begin
            if (!rst_n) begin
                X_data[k] <= 0;
            end
            else if (sleep_cond_X_in[k])
                X_data[k] <= in_data;
        end
    end
endgenerate

generate
    for(k=0; k<64; k=k+1)begin: Gate_or_Q
        always @*begin
            sleep_cond_Q_in[k] = (cnt[5:0] == k) && (cnt[7:6] == 2'd0);
            input_sleep_Q_in[k] = !(sleep_cond_Q_in[k]) && cg_en;
        end
         GATED_OR GATED_Q_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_Q_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_Q_in[k]));
    end
endgenerate

generate
    for(k=0; k<64; k=k+1)begin: Input_register_Q
        always@(posedge gated_clk_Q_in[k])begin
			if (sleep_cond_Q_in[k])
            	Q_data[k] <= w_Q;
        end
    end
endgenerate

generate
    for(k=0; k<64; k=k+1)begin: Gate_or_K
        always @*begin
            sleep_cond_K_in[k] = (cnt[5:0] == k) && (cnt[7:6] == 2'd1);
            input_sleep_K_in[k] = !(sleep_cond_K_in[k]) && cg_en;
        end
         GATED_OR GATED_K_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_K_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_K_in[k]));
    end
endgenerate

generate
    for(k=0; k<64; k=k+1)begin: Input_register_K
        always@(posedge gated_clk_K_in[k])begin
			if (sleep_cond_K_in[k])
            	K_data[k] <= w_K;
        end
    end
endgenerate

generate
    for(k=0; k<64; k=k+1)begin: Gate_or_V
        always @*begin
            sleep_cond_V_in[k] = (cnt[5:0] == k) && (cnt[7:6] == 2'd2);
            input_sleep_V_in[k] = !(sleep_cond_V_in[k]) && cg_en;
        end
         GATED_OR GATED_V_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_V_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_V_in[k]));
    end
endgenerate

generate
    for(k=0; k<64; k=k+1)begin: Input_register_V
        always@(posedge gated_clk_V_in[k])begin
			if (sleep_cond_V_in[k])
            	V_data[k] <= w_V;
        end
    end
endgenerate

generate
    for(k=0; k<56; k=k+8)begin: Gate_or_XQ1
        always @*begin
            sleep_cond_XQ_in[k] = compute_cnt_8bit == 6'd8;
            input_sleep_XQ_in[k] = !(sleep_cond_XQ_in[k]) && cg_en;
        end
         GATED_OR GATED_XQ_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XQ_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XQ_in[k]));
    end
endgenerate

// generate
//     for(k=0; k<56; k=k+8)begin: Input_register_XQ1
//         always@(posedge gated_clk_XQ_in[k])begin
// 			if (sleep_cond_XQ_in[k])
//             	XQ_data[k] <= partial_8bit_out_wire[k+7];
//         end
//     end
// endgenerate

generate
    for(k=1; k<56; k=k+8)begin: Gate_or_XQ2
        always @*begin
            sleep_cond_XQ_in[k] = compute_cnt_8bit == 6'd9;
            input_sleep_XQ_in[k] = !(sleep_cond_XQ_in[k]) && cg_en;
        end
         GATED_OR GATED_XQ_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XQ_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XQ_in[k]));
    end
endgenerate

// generate
//     for(k=1; k<56; k=k+8)begin: Input_register_XQ2
//         always@(posedge gated_clk_XQ_in[k])begin
// 			if (sleep_cond_XQ_in[k])
//             	XQ_data[k] <= partial_8bit_out_wire[k+6];
//         end
//     end
// endgenerate

generate
    for(k=2; k<56; k=k+8)begin: Gate_or_XQ3
        always @*begin
            sleep_cond_XQ_in[k] = compute_cnt_8bit == 6'd10;
            input_sleep_XQ_in[k] = !(sleep_cond_XQ_in[k]) && cg_en;
        end
         GATED_OR GATED_XQ_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XQ_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XQ_in[k]));
    end
endgenerate

// generate
//     for(k=2; k<56; k=k+8)begin: Input_register_XQ3
//         always@(posedge gated_clk_XQ_in[k])begin
// 			if (sleep_cond_XQ_in[k])
//             	XQ_data[k] <= partial_8bit_out_wire[k+5];
//         end
//     end
// endgenerate

generate
    for(k=3; k<56; k=k+8)begin: Gate_or_XQ4
        always @*begin
            sleep_cond_XQ_in[k] = compute_cnt_8bit == 6'd11;
            input_sleep_XQ_in[k] = !(sleep_cond_XQ_in[k]) && cg_en;
        end
         GATED_OR GATED_XQ_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XQ_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XQ_in[k]));
    end
endgenerate

// generate
//     for(k=3; k<56; k=k+8)begin: Input_register_XQ4
//         always@(posedge gated_clk_XQ_in[k])begin
// 			if (sleep_cond_XQ_in[k])
//             	XQ_data[k] <= partial_8bit_out_wire[k+4];
//         end
//     end
// endgenerate

generate
    for(k=4; k<56; k=k+8)begin: Gate_or_XQ5
        always @*begin
            sleep_cond_XQ_in[k] = compute_cnt_8bit == 6'd12;
            input_sleep_XQ_in[k] = !(sleep_cond_XQ_in[k]) && cg_en;
        end
         GATED_OR GATED_XQ_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XQ_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XQ_in[k]));
    end
endgenerate

// generate
//     for(k=4; k<56; k=k+8)begin: Input_register_XQ5
//         always@(posedge gated_clk_XQ_in[k])begin
// 			if (sleep_cond_XQ_in[k])
//             	XQ_data[k] <= partial_8bit_out_wire[k+3];
//         end
//     end
// endgenerate

generate
    for(k=5; k<56; k=k+8)begin: Gate_or_XQ6
        always @*begin
            sleep_cond_XQ_in[k] = compute_cnt_8bit == 6'd13;
            input_sleep_XQ_in[k] = !(sleep_cond_XQ_in[k]) && cg_en;
        end
         GATED_OR GATED_XQ_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XQ_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XQ_in[k]));
    end
endgenerate

// generate
//     for(k=5; k<56; k=k+8)begin: Input_register_XQ6
//         always@(posedge gated_clk_XQ_in[k])begin
// 			if (sleep_cond_XQ_in[k])
//             	XQ_data[k] <= partial_8bit_out_wire[k+2];
//         end
//     end
// endgenerate

generate
    for(k=6; k<56; k=k+8)begin: Gate_or_XQ7
        always @*begin
            sleep_cond_XQ_in[k] = compute_cnt_8bit == 6'd14;
            input_sleep_XQ_in[k] = !(sleep_cond_XQ_in[k]) && cg_en;
        end
         GATED_OR GATED_XQ_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XQ_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XQ_in[k]));
    end
endgenerate

// generate
//     for(k=6; k<56; k=k+8)begin: Input_register_XQ7
//         always@(posedge gated_clk_XQ_in[k])begin
// 			if (sleep_cond_XQ_in[k])
//             	XQ_data[k] <= partial_8bit_out_wire[k+1];
//         end
//     end
// endgenerate

generate
    for(k=7; k<56; k=k+8)begin: Gate_or_XQ8
        always @*begin
            sleep_cond_XQ_in[k] = compute_cnt_8bit == 6'd15;
            input_sleep_XQ_in[k] = !(sleep_cond_XQ_in[k]) && cg_en;
        end
         GATED_OR GATED_XQ_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XQ_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XQ_in[k]));
    end
endgenerate

// generate
//     for(k=7; k<56; k=k+8)begin: Input_register_XQ8
//         always@(posedge gated_clk_XQ_in[k])begin
// 			if (sleep_cond_XQ_in[k])
//             	XQ_data[k] <= partial_8bit_out_wire[k];
//         end
//     end
// endgenerate

generate
    for(k=0; k<56; k=k+8)begin: Gate_or_XK1
        always @*begin
            sleep_cond_XK_in[k] = compute_cnt_8bit == 6'd24;
            input_sleep_XK_in[k] = !(sleep_cond_XK_in[k]) && cg_en;
        end
         GATED_OR GATED_XK_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XK_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XK_in[k]));
    end
endgenerate

generate
    for(k=0; k<56; k=k+8)begin: Input_register_XK1
        always@(posedge gated_clk_XK_in[k])begin
			if (sleep_cond_XK_in[k])
            	XK_data[k] <= partial_8bit_out_wire[k+7];
        end
    end
endgenerate

generate
    for(k=1; k<56; k=k+8)begin: Gate_or_XK2
        always @*begin
            sleep_cond_XK_in[k] = compute_cnt_8bit == 6'd25;
            input_sleep_XK_in[k] = !(sleep_cond_XK_in[k]) && cg_en;
        end
         GATED_OR GATED_XK_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XK_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XK_in[k]));
    end
endgenerate

generate
    for(k=1; k<56; k=k+8)begin: Input_register_XK2
        always@(posedge gated_clk_XK_in[k])begin
            if (sleep_cond_XK_in[k])
            	XK_data[k] <= partial_8bit_out_wire[k+6];
        end
    end
endgenerate

generate
    for(k=2; k<56; k=k+8)begin: Gate_or_XK3
        always @*begin
            sleep_cond_XK_in[k] = compute_cnt_8bit == 6'd26;
            input_sleep_XK_in[k] = !(sleep_cond_XK_in[k]) && cg_en;
        end
         GATED_OR GATED_XK_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XK_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XK_in[k]));
    end
endgenerate

generate
    for(k=2; k<56; k=k+8)begin: Input_register_XK3
        always@(posedge gated_clk_XK_in[k])begin
            if (sleep_cond_XK_in[k])
            	XK_data[k] <= partial_8bit_out_wire[k+5];
        end
    end
endgenerate

generate
    for(k=3; k<56; k=k+8)begin: Gate_or_XK4
        always @*begin
            sleep_cond_XK_in[k] = compute_cnt_8bit == 6'd27;
            input_sleep_XK_in[k] = !(sleep_cond_XK_in[k]) && cg_en;
        end
         GATED_OR GATED_XK_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XK_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XK_in[k]));
    end
endgenerate

generate
    for(k=3; k<56; k=k+8)begin: Input_register_XK4
        always@(posedge gated_clk_XK_in[k])begin
            if (sleep_cond_XK_in[k])
            	XK_data[k] <= partial_8bit_out_wire[k+4];
        end
    end
endgenerate

generate
    for(k=4; k<56; k=k+8)begin: Gate_or_XK5
        always @*begin
            sleep_cond_XK_in[k] = compute_cnt_8bit == 6'd28;
            input_sleep_XK_in[k] = !(sleep_cond_XK_in[k]) && cg_en;
        end
         GATED_OR GATED_XK_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XK_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XK_in[k]));
    end
endgenerate

generate
    for(k=4; k<56; k=k+8)begin: Input_register_XK5
        always@(posedge gated_clk_XK_in[k])begin
            if (sleep_cond_XK_in[k])
            	XK_data[k] <= partial_8bit_out_wire[k+3];
        end
    end
endgenerate

generate
    for(k=5; k<56; k=k+8)begin: Gate_or_XK6
        always @*begin
            sleep_cond_XK_in[k] = compute_cnt_8bit == 6'd29;
            input_sleep_XK_in[k] = !(sleep_cond_XK_in[k]) && cg_en;
        end
         GATED_OR GATED_XK_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XK_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XK_in[k]));
    end
endgenerate

generate
    for(k=5; k<56; k=k+8)begin: Input_register_XK6
        always@(posedge gated_clk_XK_in[k])begin
            if (sleep_cond_XK_in[k])
            	XK_data[k] <= partial_8bit_out_wire[k+2];
        end
    end
endgenerate

generate
    for(k=6; k<56; k=k+8)begin: Gate_or_XK7
        always @*begin
            sleep_cond_XK_in[k] = compute_cnt_8bit == 6'd30;
            input_sleep_XK_in[k] = !(sleep_cond_XK_in[k]) && cg_en;
        end
         GATED_OR GATED_XK_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XK_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XK_in[k]));
    end
endgenerate

generate
    for(k=6; k<56; k=k+8)begin: Input_register_XK7
        always@(posedge gated_clk_XK_in[k])begin
            if (sleep_cond_XK_in[k])
            	XK_data[k] <= partial_8bit_out_wire[k+1];
        end
    end
endgenerate

generate
    for(k=7; k<56; k=k+8)begin: Gate_or_XK8
        always @*begin
            sleep_cond_XK_in[k] = compute_cnt_8bit == 6'd31;
            input_sleep_XK_in[k] = !(sleep_cond_XK_in[k]) && cg_en;
        end
         GATED_OR GATED_XK_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XK_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XK_in[k]));
    end
endgenerate

generate
    for(k=7; k<56; k=k+8)begin: Input_register_XK8
        always@(posedge gated_clk_XK_in[k])begin
            if (sleep_cond_XK_in[k])
            	XK_data[k] <= partial_8bit_out_wire[k];
        end
    end
endgenerate

generate
    for(k=0; k<56; k=k+8)begin: Gate_or_XV1
        always @*begin
            sleep_cond_XV_in[k] = compute_cnt_8bit == 6'd40;
            input_sleep_XV_in[k] = !(sleep_cond_XV_in[k]) && cg_en;
        end
         GATED_OR GATED_XV_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XV_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XV_in[k]));
    end
endgenerate

generate
    for(k=0; k<56; k=k+8)begin: Input_register_XV1
        always@(posedge gated_clk_XV_in[k])begin
            if (sleep_cond_XV_in[k])
            	XV_data[k] <= partial_8bit_out_wire[k+7];
        end
    end
endgenerate

generate
    for(k=1; k<56; k=k+8)begin: Gate_or_XV2
        always @*begin
            sleep_cond_XV_in[k] = compute_cnt_8bit == 6'd41;
            input_sleep_XV_in[k] = !(sleep_cond_XV_in[k]) && cg_en;
        end
         GATED_OR GATED_XV_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XV_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XV_in[k]));
    end
endgenerate

generate
    for(k=1; k<56; k=k+8)begin: Input_register_XV2
        always@(posedge gated_clk_XV_in[k])begin
            if (sleep_cond_XV_in[k])
            	XV_data[k] <= partial_8bit_out_wire[k+6];
        end
    end
endgenerate

generate
    for(k=2; k<56; k=k+8)begin: Gate_or_XV3
        always @*begin
            sleep_cond_XV_in[k] = compute_cnt_8bit == 6'd42;
            input_sleep_XV_in[k] = !(sleep_cond_XV_in[k]) && cg_en;
        end
         GATED_OR GATED_XV_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XV_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XV_in[k]));
    end
endgenerate

generate
    for(k=2; k<56; k=k+8)begin: Input_register_XV3
        always@(posedge gated_clk_XV_in[k])begin
            if (sleep_cond_XV_in[k])
            	XV_data[k] <= partial_8bit_out_wire[k+5];
        end
    end
endgenerate

generate
    for(k=3; k<56; k=k+8)begin: Gate_or_XV4
        always @*begin
            sleep_cond_XV_in[k] = compute_cnt_8bit == 6'd43;
            input_sleep_XV_in[k] = !(sleep_cond_XV_in[k]) && cg_en;
        end
         GATED_OR GATED_XV_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XV_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XV_in[k]));
    end
endgenerate

generate
    for(k=3; k<56; k=k+8)begin: Input_register_XV4
        always@(posedge gated_clk_XV_in[k])begin
            if (sleep_cond_XV_in[k])
            	XV_data[k] <= partial_8bit_out_wire[k+4];
        end
    end
endgenerate

generate
    for(k=4; k<56; k=k+8)begin: Gate_or_XV5
        always @*begin
            sleep_cond_XV_in[k] = compute_cnt_8bit == 6'd44;
            input_sleep_XV_in[k] = !(sleep_cond_XV_in[k]) && cg_en;
        end
         GATED_OR GATED_XV_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XV_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XV_in[k]));
    end
endgenerate

generate
    for(k=4; k<56; k=k+8)begin: Input_register_XV5
        always@(posedge gated_clk_XV_in[k])begin
            if (sleep_cond_XV_in[k])
            	XV_data[k] <= partial_8bit_out_wire[k+3];
        end
    end
endgenerate

generate
    for(k=5; k<56; k=k+8)begin: Gate_or_XV6
        always @*begin
            sleep_cond_XV_in[k] = compute_cnt_8bit == 6'd45;
            input_sleep_XV_in[k] = !(sleep_cond_XV_in[k]) && cg_en;
        end
         GATED_OR GATED_XV_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XV_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XV_in[k]));
    end
endgenerate

generate
    for(k=5; k<56; k=k+8)begin: Input_register_XV6
        always@(posedge gated_clk_XV_in[k])begin
            if (sleep_cond_XV_in[k])
            	XV_data[k] <= partial_8bit_out_wire[k+2];
        end
    end
endgenerate

generate
    for(k=6; k<56; k=k+8)begin: Gate_or_XV7
        always @*begin
            sleep_cond_XV_in[k] = compute_cnt_8bit == 6'd46;
            input_sleep_XV_in[k] = !(sleep_cond_XV_in[k]) && cg_en;
        end
            GATED_OR GATED_XV_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XV_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XV_in[k]));
    end
endgenerate

generate
    for(k=6; k<56; k=k+8)begin: Input_register_XV7
        always@(posedge gated_clk_XV_in[k])begin
            if (sleep_cond_XV_in[k])
            	XV_data[k] <= partial_8bit_out_wire[k+1];
        end
    end
endgenerate

generate
    for(k=7; k<56; k=k+8)begin: Gate_or_XV8
        always @*begin
            sleep_cond_XV_in[k] = compute_cnt_8bit == 6'd47;
            input_sleep_XV_in[k] = !(sleep_cond_XV_in[k]) && cg_en;
        end
         GATED_OR GATED_XV_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XV_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XV_in[k]));
    end
endgenerate

generate
    for(k=7; k<56; k=k+8)begin: Input_register_XV8
        always@(posedge gated_clk_XV_in[k])begin
            if (sleep_cond_XV_in[k])
            	XV_data[k] <= partial_8bit_out_wire[k];
        end
    end
endgenerate

generate
    for(k=56; k<64; k=k+1)begin: Gate_or_XQ9
        always @*begin
            sleep_cond_XQ_in[k] = cnt == 63+k%8;
            input_sleep_XQ_in[k] = !(sleep_cond_XQ_in[k]) && cg_en;
        end
         GATED_OR GATED_XQ_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XQ_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XQ_in[k]));
    end
endgenerate

// generate
//     for(k=56; k<64; k=k+1)begin: Input_register_XQ9
//         always@(posedge gated_clk_XQ_in[k])begin
//             if (sleep_cond_XQ_in[k])
//             	XQ_data[k] <= partial_8bit_out_wire[63];
//         end
//     end
// endgenerate

generate
    for(k=56; k<64; k=k+1)begin: Gate_or_XK9
        always @*begin
            sleep_cond_XK_in[k] = cnt == 127+k%8;
            input_sleep_XK_in[k] = !(sleep_cond_XK_in[k]) && cg_en;
        end
         GATED_OR GATED_XK_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XK_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XK_in[k]));
    end
endgenerate

generate
    for(k=56; k<64; k=k+1)begin: Input_register_XK9
        always@(posedge gated_clk_XK_in[k])begin
            if (sleep_cond_XK_in[k])
            	XK_data[k] <= partial_8bit_out_wire[63];
        end
    end
endgenerate

generate
    for(k=56; k<64; k=k+1)begin: Gate_or_XV9
        always @*begin
            sleep_cond_XV_in[k] = cnt == 191+k%8;
            input_sleep_XV_in[k] = !(sleep_cond_XV_in[k]) && cg_en;
        end
         GATED_OR GATED_XV_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_XV_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_XV_in[k]));
    end
endgenerate

generate
    for(k=56; k<64; k=k+1)begin: Input_register_XV9
        always@(posedge gated_clk_XV_in[k])begin
            if (sleep_cond_XV_in[k])
            	XV_data[k] <= partial_8bit_out_wire[63];
        end
    end
endgenerate

generate
    for(k=0; k<64; k=k+1)begin: Gate_or_QK
        always @*begin
            sleep_cond_QK_in[k] = k == (QK_compute_cnt - 7'd8);
            input_sleep_QK_in[k] = !(sleep_cond_QK_in[k] || sleep_cond_XQ_in[k]) && cg_en;
        end
         GATED_OR GATED_QK_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_QK_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_QK_in[k]));
    end
endgenerate

generate
    for(k=0; k<64; k=k+1)begin: Input_register_QK
        always@(posedge gated_clk_QK_in[k])begin
            if (sleep_cond_QK_in[k])
            	QK_data[k] <= div_out;
            else if (sleep_cond_XQ_in[k])
                QK_data[k] <= partial_8bit_out_wire[(k/8)*8+7];
        end
    end
endgenerate

generate
    for(k=0; k<8; k=k+1)begin: Gate_or_pe
        always @*begin
            //sleep_cond_pe_in[k] = cnt >= (121+k) && cnt <= (248+k);
            input_sleep_pe_in[k] = !(cnt >= (121+k) && cnt <= (248+k))&& cg_en;
        end
         GATED_OR GATED_pe_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_pe_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_pe_in[k]));
    end
endgenerate

generate
    for(k=0; k<56; k=k+1)begin: Gate_or_pe_8bit
        always @(*)begin
            //sleep_cond_pe_8bit_in[k] = compute_cnt_8bit[3:0] >= 1 && compute_cnt_8bit[3:0] <= (8 + k % 8);
            input_sleep_pe_8bit_in[k] = !(compute_cnt_8bit[3:0] >= 1 && compute_cnt_8bit[3:0] <= (8 + k % 8))&& cg_en;
        end
         GATED_OR GATED_pe_8bit_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_pe_8bit_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_pe_8bit_in[k]));
    end
endgenerate

generate
    for(k=56; k<64; k=k+1)begin: Gate_or_pe_8bit_2
        always @(*)begin
            //input_sleep_pe_8bit_in[k] = compute_cnt_8bit_lastrow[3:0] >= k % 8 || compute_cnt_8bit_lastrow[3:0] <= 8 + k % 8;
            input_sleep_pe_8bit_in[k] = !(compute_cnt_8bit_lastrow[3:0] >= k % 8 || compute_cnt_8bit_lastrow[3:0] <= 8 + k % 8)&& cg_en;
        end
         GATED_OR GATED_pe_8bit_in(.CLOCK(clk),.SLEEP_CTRL(input_sleep_pe_8bit_in[k]),.RST_N(rst_n),.CLOCK_GATED(gated_clk_pe_8bit_in[k]));
    end
endgenerate
//==============================================//
//                  design                      //
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cs <= 0;
    else
        cs <= ns; 
end

always @(*) begin
    case (cs)
        read: ns = (cnt == 192)? compute : read;
        compute: ns = compute;
        default: ns = read;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt <= 0;
    end
    else begin
        if (cnt || in_valid) begin
            cnt <= (cnt == cnt_bound)? 0 : cnt + 1;
        end
    end
end

always @(*) begin
    case (T_type)
        2'd0: cnt_bound = 200;
        2'd1: cnt_bound = 224;
        2'd2: cnt_bound = 256;
        default: cnt_bound = 256;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 0;
    end
    else begin
        if (cnt >= 192) begin
            out_valid <= (cnt == cnt_bound)? 0 : 1;
        end
    end
end

assign out_data = (out_valid)? {partial_out[7][61], partial_out[7][61], partial_out[7]} : 0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        compute_cnt_8bit <= 0;
    end
    else begin
        if (cnt == cnt_bound) begin
            compute_cnt_8bit <= 0;
        end
        else if (cnt[5:0] >= 48) begin
            compute_cnt_8bit <= compute_cnt_8bit + 1;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        compute_cnt_8bit_lastrow <= 0;
    end
    else begin
        if (cnt == cnt_bound) begin
            compute_cnt_8bit_lastrow <= 0;
        end
        else if (cnt[5:0] >= 56 || (cnt[7:6] && cnt[5:0] <= 7)) begin
            compute_cnt_8bit_lastrow <= compute_cnt_8bit_lastrow + 1;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        QK_compute_cnt <= 0;
    end
    else begin
        if (cnt >= 121 && cnt <= 184) begin
            case (T_type)
                2'd0: QK_compute_cnt <= (QK_compute_cnt <= 7'd15)? QK_compute_cnt + 1 : 7'd64; 
                2'd1: QK_compute_cnt <= (QK_compute_cnt <= 7'd39)? QK_compute_cnt + 1 : 7'd64;
                2'd2: QK_compute_cnt <= QK_compute_cnt + 1;
            endcase
        end
        else if (cnt >= 185) begin
            if (cnt == cnt_bound) begin
                QK_compute_cnt <= 0;
            end
            else 
                QK_compute_cnt <= QK_compute_cnt + 1;
        end
    end
end

always @(*) begin
    if (QK_compute_cnt >= 7'd8 && QK_compute_cnt <= 7'd71) begin
        div_in = (partial_out[7][40])? 0 : partial_out[7];
    end
    else 
        div_in = 0;
end

assign div_out = div_in / 3;

always @(posedge clk) begin
    T_tmp <= T;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        T_type <= 2'd3;
    end
    else begin
        if (in_valid && !cnt) begin
            case (T)
                4'd1: T_type <= 2'd0;
                4'd4: T_type <= 2'd1;
                4'd8: T_type <= 2'd2; 
                default: T_type <= 2'd3;
            endcase
        end
    end
end

always @(*) begin
    case (compute_cnt_8bit[5:4])
        2'd0: begin
            case (compute_cnt_8bit[3:0])
                4'd1: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[0];
                4'd2: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[1];
                4'd3: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[2];
                4'd4: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[3];
                4'd5: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[4];
                4'd6: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[5];
                4'd7: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[6];
                4'd8: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[7];
                default: for (i = 0; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        2'd1: begin
            case (compute_cnt_8bit[3:0])
                4'd1: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[0];
                4'd2: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[1];
                4'd3: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[2];
                4'd4: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[3];
                4'd5: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[4];
                4'd6: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[5];
                4'd7: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[6];
                4'd8: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[7];
                default: for (i = 0; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        2'd2: begin
            case (compute_cnt_8bit[3:0])
                4'd1: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[0];
                4'd2: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[1];
                4'd3: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[2];
                4'd4: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[3];
                4'd5: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[4];
                4'd6: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[5];
                4'd7: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[6];
                4'd8: for (i = 0; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[7];
                default: for (i = 0; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        default: begin
            for (i = 0; i < 56; i = i + 8)
                pixelA_8bit_in[i] = 0;
        end
    endcase
end

always @(*) begin
    case (compute_cnt_8bit[5:4])
        2'd0: begin
            case (compute_cnt_8bit[3:0])
                4'd2: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[8];
                4'd3: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[9];
                4'd4: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[10];
                4'd5: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[11];
                4'd6: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[12];
                4'd7: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[13];
                4'd8: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[14];
                4'd9: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[15];
                default: for (i = 1; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        2'd1: begin
            case (compute_cnt_8bit[3:0])
                4'd2: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[8];
                4'd3: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[9];
                4'd4: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[10];
                4'd5: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[11];
                4'd6: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[12];
                4'd7: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[13];
                4'd8: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[14];
                4'd9: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[15];
                default: for (i = 1; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        2'd2: begin
            case (compute_cnt_8bit[3:0])
                4'd2: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[8];
                4'd3: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[9];
                4'd4: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[10];
                4'd5: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[11];
                4'd6: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[12];
                4'd7: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[13];
                4'd8: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[14];
                4'd9: for (i = 1; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[15];
                default: for (i = 1; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        default: begin
            for (i = 1; i < 56; i = i + 8)
                pixelA_8bit_in[i] = 0;
        end
    endcase
end

always @(*) begin
    case (compute_cnt_8bit[5:4])
        2'd0: begin
            case (compute_cnt_8bit[3:0])
                4'd3: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[16];
                4'd4: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[17];
                4'd5: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[18];
                4'd6: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[19];
                4'd7: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[20];
                4'd8: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[21];
                4'd9: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[22];
                4'd10: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[23];
                default: for (i = 2; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        2'd1: begin
            case (compute_cnt_8bit[3:0])
                4'd3: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[16];
                4'd4: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[17];
                4'd5: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[18];
                4'd6: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[19];
                4'd7: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[20];
                4'd8: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[21];
                4'd9: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[22];
                4'd10: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[23];
                default: for (i = 2; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        2'd2: begin
            case (compute_cnt_8bit[3:0])
                4'd3: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[16];
                4'd4: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[17];
                4'd5: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[18];
                4'd6: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[19];
                4'd7: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[20];
                4'd8: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[21];
                4'd9: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[22];
                4'd10: for (i = 2; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[23];
                default: for (i = 2; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        default: begin
            for (i = 2; i < 56; i = i + 8)
                pixelA_8bit_in[i] = 0;
        end
    endcase
end

always @(*) begin
    case (compute_cnt_8bit[5:4])
        2'd0: begin
            case (compute_cnt_8bit[3:0])
                4'd4: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[24];
                4'd5: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[25];
                4'd6: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[26];
                4'd7: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[27];
                4'd8: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[28];
                4'd9: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[29];
                4'd10: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[30];
                4'd11: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[31];
                default: for (i = 3; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        2'd1: begin
            case (compute_cnt_8bit[3:0])
                4'd4: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[24];
                4'd5: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[25];
                4'd6: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[26];
                4'd7: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[27];
                4'd8: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[28];
                4'd9: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[29];
                4'd10: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[30];
                4'd11: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[31];
                default: for (i = 3; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        2'd2: begin
            case (compute_cnt_8bit[3:0])
                4'd4: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[24];
                4'd5: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[25];
                4'd6: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[26];
                4'd7: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[27];
                4'd8: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[28];
                4'd9: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[29];
                4'd10: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[30];
                4'd11: for (i = 3; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[31];
                default: for (i = 3; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        default: begin
            for (i = 3; i < 56; i = i + 8)
                pixelA_8bit_in[i] = 0;
        end
    endcase
end

always @(*) begin
    case (compute_cnt_8bit[5:4])
        2'd0: begin
            case (compute_cnt_8bit[3:0])
                4'd5: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[32];
                4'd6: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[33];
                4'd7: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[34];
                4'd8: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[35];
                4'd9: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[36];
                4'd10: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[37];
                4'd11: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[38];
                4'd12: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[39];
                default: for (i = 4; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        2'd1: begin
            case (compute_cnt_8bit[3:0])
                4'd5: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[32];
                4'd6: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[33];
                4'd7: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[34];
                4'd8: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[35];
                4'd9: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[36];
                4'd10: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[37];
                4'd11: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[38];
                4'd12: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[39];
                default: for (i = 4; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        2'd2: begin
            case (compute_cnt_8bit[3:0])
                4'd5: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[32];
                4'd6: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[33];
                4'd7: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[34];
                4'd8: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[35];
                4'd9: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[36];
                4'd10: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[37];
                4'd11: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[38];
                4'd12: for (i = 4; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[39];
                default: for (i = 4; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        default: begin
            for (i = 4; i < 56; i = i + 8)
                pixelA_8bit_in[i] = 0;
        end
    endcase
end

always @(*) begin
    case (compute_cnt_8bit[5:4])
        2'd0: begin
            case (compute_cnt_8bit[3:0])
                4'd6: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[40];
                4'd7: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[41];
                4'd8: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[42];
                4'd9: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[43];
                4'd10: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[44];
                4'd11: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[45];
                4'd12: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[46];
                4'd13: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[47];
                default: for (i = 5; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        2'd1: begin
            case (compute_cnt_8bit[3:0])
                4'd6: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[40];
                4'd7: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[41];
                4'd8: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[42];
                4'd9: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[43];
                4'd10: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[44];
                4'd11: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[45];
                4'd12: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[46];
                4'd13: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[47];
                default: for (i = 5; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        2'd2: begin
            case (compute_cnt_8bit[3:0])
                4'd6: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[40];
                4'd7: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[41];
                4'd8: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[42];
                4'd9: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[43];
                4'd10: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[44];
                4'd11: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[45];
                4'd12: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[46];
                4'd13: for (i = 5; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[47];
                default: for (i = 5; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        default: begin
            for (i = 5; i < 56; i = i + 8)
                pixelA_8bit_in[i] = 0;
        end
    endcase
end

always @(*) begin
    case (compute_cnt_8bit[5:4])
        2'd0: begin
            case (compute_cnt_8bit[3:0])
                4'd7: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[48];
                4'd8: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[49];
                4'd9: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[50];
                4'd10: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[51];
                4'd11: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[52];
                4'd12: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[53];
                4'd13: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[54];
                4'd14: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = Q_data[55];
                default: for (i = 6; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        2'd1: begin
            case (compute_cnt_8bit[3:0])
                4'd7: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[48];
                4'd8: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[49];
                4'd9: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[50];
                4'd10: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[51];
                4'd11: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[52];
                4'd12: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[53];
                4'd13: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[54];
                4'd14: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = K_data[55];
                default: for (i = 6; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        2'd2: begin
            case (compute_cnt_8bit[3:0])
                4'd7: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[48];
                4'd8: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[49];
                4'd9: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[50];
                4'd10: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[51];
                4'd11: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[52];
                4'd12: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[53];
                4'd13: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[54];
                4'd14: for (i = 6; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = V_data[55];
                default: for (i = 6; i < 56; i = i + 8)
                            pixelA_8bit_in[i] = 0;
            endcase
        end
        default: begin
            for (i = 6; i < 56; i = i + 8)
                pixelA_8bit_in[i] = 0;
        end
    endcase
end

always @(*) begin
    if (compute_cnt_8bit[3:0] >= 4'd8) begin
        case (compute_cnt_8bit[5:4])
            2'd0: for (i = 7; i < 56; i = i + 8)
                     pixelA_8bit_in[i] = w_Q;
            2'd1: for (i = 7; i < 56; i = i + 8)
                     pixelA_8bit_in[i] = w_K;
            2'd2: for (i = 7; i < 56; i = i + 8)
                     pixelA_8bit_in[i] = w_V;
            default: for (i = 7; i < 56; i = i + 8)
                        pixelA_8bit_in[i] = 0;
        endcase
    end
    else begin
        for (i = 7; i < 56; i = i + 8)
            pixelA_8bit_in[i] = 0;
    end
end

always @(*) begin
    if ((cnt[5:0] >= 6'd56) && T_type[1]) begin
        case (cnt[7:6])
            2'd0: begin
                case (cnt[2:0])
                    3'd0: pixelA_8bit_in[56] = Q_data[0]; 
                    3'd1: pixelA_8bit_in[56] = Q_data[1];
                    3'd2: pixelA_8bit_in[56] = Q_data[2];
                    3'd3: pixelA_8bit_in[56] = Q_data[3];
                    3'd4: pixelA_8bit_in[56] = Q_data[4];
                    3'd5: pixelA_8bit_in[56] = Q_data[5];
                    3'd6: pixelA_8bit_in[56] = Q_data[6];
                    3'd7: pixelA_8bit_in[56] = Q_data[7];
                    default: pixelA_8bit_in[56] = 0; 
                endcase
            end
            2'd1: begin
                case (cnt[2:0])
                    3'd0: pixelA_8bit_in[56] = K_data[0]; 
                    3'd1: pixelA_8bit_in[56] = K_data[1];
                    3'd2: pixelA_8bit_in[56] = K_data[2];
                    3'd3: pixelA_8bit_in[56] = K_data[3];
                    3'd4: pixelA_8bit_in[56] = K_data[4];
                    3'd5: pixelA_8bit_in[56] = K_data[5];
                    3'd6: pixelA_8bit_in[56] = K_data[6];
                    3'd7: pixelA_8bit_in[56] = K_data[7];
                    default: pixelA_8bit_in[56] = 0; 
                endcase
            end
            2'd2: begin
                case (cnt[2:0])
                    3'd0: pixelA_8bit_in[56] = V_data[0]; 
                    3'd1: pixelA_8bit_in[56] = V_data[1];
                    3'd2: pixelA_8bit_in[56] = V_data[2];
                    3'd3: pixelA_8bit_in[56] = V_data[3];
                    3'd4: pixelA_8bit_in[56] = V_data[4];
                    3'd5: pixelA_8bit_in[56] = V_data[5];
                    3'd6: pixelA_8bit_in[56] = V_data[6];
                    3'd7: pixelA_8bit_in[56] = V_data[7];
                    default: pixelA_8bit_in[56] = 0; 
                endcase
            end
            default: pixelA_8bit_in[56] = 0; 
        endcase
    end
    else begin
        pixelA_8bit_in[56] = 0;
    end
end

always @(*) begin
    if (compute_cnt_8bit_lastrow[3:0] <= 4'd8 && T_type[1]) begin
        case (compute_cnt_8bit_lastrow[5:4])
            2'd0: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd1: pixelA_8bit_in[57] = Q_data[8];
                    'd2: pixelA_8bit_in[57] = Q_data[9];
                    'd3: pixelA_8bit_in[57] = Q_data[10];
                    'd4: pixelA_8bit_in[57] = Q_data[11];
                    'd5: pixelA_8bit_in[57] = Q_data[12];
                    'd6: pixelA_8bit_in[57] = Q_data[13];
                    'd7: pixelA_8bit_in[57] = Q_data[14];
                    'd8: pixelA_8bit_in[57] = Q_data[15]; 
                    default: pixelA_8bit_in[57] = 0; 
                endcase
            end
            2'd1: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd1: pixelA_8bit_in[57] = K_data[8];
                    'd2: pixelA_8bit_in[57] = K_data[9];
                    'd3: pixelA_8bit_in[57] = K_data[10];
                    'd4: pixelA_8bit_in[57] = K_data[11];
                    'd5: pixelA_8bit_in[57] = K_data[12];
                    'd6: pixelA_8bit_in[57] = K_data[13];
                    'd7: pixelA_8bit_in[57] = K_data[14];
                    'd8: pixelA_8bit_in[57] = K_data[15]; 
                    default: pixelA_8bit_in[57] = 0; 
                endcase
            end
            2'd2: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd1: pixelA_8bit_in[57] = V_data[8];
                    'd2: pixelA_8bit_in[57] = V_data[9];
                    'd3: pixelA_8bit_in[57] = V_data[10];
                    'd4: pixelA_8bit_in[57] = V_data[11];
                    'd5: pixelA_8bit_in[57] = V_data[12];
                    'd6: pixelA_8bit_in[57] = V_data[13];
                    'd7: pixelA_8bit_in[57] = V_data[14];
                    'd8: pixelA_8bit_in[57] = V_data[15]; 
                    default: pixelA_8bit_in[57] = 0; 
                endcase
            end
            default: pixelA_8bit_in[57] = 0; 
        endcase
    end
    else begin
        pixelA_8bit_in[57] = 0;
    end
end

always @(*) begin
    if (compute_cnt_8bit_lastrow[3:0] <= 4'd9 && T_type[1]) begin
        case (compute_cnt_8bit_lastrow[5:4])
            2'd0: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd2: pixelA_8bit_in[58] = Q_data[16];
                    'd3: pixelA_8bit_in[58] = Q_data[17];
                    'd4: pixelA_8bit_in[58] = Q_data[18];
                    'd5: pixelA_8bit_in[58] = Q_data[19];
                    'd6: pixelA_8bit_in[58] = Q_data[20];
                    'd7: pixelA_8bit_in[58] = Q_data[21];
                    'd8: pixelA_8bit_in[58] = Q_data[22]; 
                    'd9: pixelA_8bit_in[58] = Q_data[23];
                    default: pixelA_8bit_in[58] = 0; 
                endcase
            end
            2'd1: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd2: pixelA_8bit_in[58] = K_data[16];
                    'd3: pixelA_8bit_in[58] = K_data[17];
                    'd4: pixelA_8bit_in[58] = K_data[18];
                    'd5: pixelA_8bit_in[58] = K_data[19];
                    'd6: pixelA_8bit_in[58] = K_data[20];
                    'd7: pixelA_8bit_in[58] = K_data[21];
                    'd8: pixelA_8bit_in[58] = K_data[22]; 
                    'd9: pixelA_8bit_in[58] = K_data[23];
                    default: pixelA_8bit_in[58] = 0; 
                endcase
            end
            2'd2: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd2: pixelA_8bit_in[58] = V_data[16];
                    'd3: pixelA_8bit_in[58] = V_data[17];
                    'd4: pixelA_8bit_in[58] = V_data[18];
                    'd5: pixelA_8bit_in[58] = V_data[19];
                    'd6: pixelA_8bit_in[58] = V_data[20];
                    'd7: pixelA_8bit_in[58] = V_data[21];
                    'd8: pixelA_8bit_in[58] = V_data[22]; 
                    'd9: pixelA_8bit_in[58] = V_data[23];
                    default: pixelA_8bit_in[58] = 0; 
                endcase
            end
            default: pixelA_8bit_in[58] = 0; 
        endcase
    end
    else begin
        pixelA_8bit_in[58] = 0;
    end
end

always @(*) begin
    if (compute_cnt_8bit_lastrow[3:0] <= 4'd10 && T_type[1]) begin
        case (compute_cnt_8bit_lastrow[5:4])
            2'd0: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd3: pixelA_8bit_in[59] = Q_data[24];
                    'd4: pixelA_8bit_in[59] = Q_data[25];
                    'd5: pixelA_8bit_in[59] = Q_data[26];
                    'd6: pixelA_8bit_in[59] = Q_data[27];
                    'd7: pixelA_8bit_in[59] = Q_data[28];
                    'd8: pixelA_8bit_in[59] = Q_data[29]; 
                    'd9: pixelA_8bit_in[59] = Q_data[30];
                    'd10: pixelA_8bit_in[59] = Q_data[31];
                    default: pixelA_8bit_in[59] = 0; 
                endcase
            end
            2'd1: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd3: pixelA_8bit_in[59] = K_data[24];
                    'd4: pixelA_8bit_in[59] = K_data[25];
                    'd5: pixelA_8bit_in[59] = K_data[26];
                    'd6: pixelA_8bit_in[59] = K_data[27];
                    'd7: pixelA_8bit_in[59] = K_data[28];
                    'd8: pixelA_8bit_in[59] = K_data[29]; 
                    'd9: pixelA_8bit_in[59] = K_data[30];
                    'd10: pixelA_8bit_in[59] = K_data[31];
                    default: pixelA_8bit_in[59] = 0; 
                endcase
            end
            2'd2: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd3: pixelA_8bit_in[59] = V_data[24]; 
                    'd4: pixelA_8bit_in[59] = V_data[25];
                    'd5: pixelA_8bit_in[59] = V_data[26];
                    'd6: pixelA_8bit_in[59] = V_data[27];
                    'd7: pixelA_8bit_in[59] = V_data[28];
                    'd8: pixelA_8bit_in[59] = V_data[29];
                    'd9: pixelA_8bit_in[59] = V_data[30];
                    'd10: pixelA_8bit_in[59] = V_data[31];
                    default: pixelA_8bit_in[59] = 0; 
                endcase
            end
            default: pixelA_8bit_in[59] = 0; 
        endcase
    end
    else begin
        pixelA_8bit_in[59] = 0;
    end
end

always @(*) begin
    if (compute_cnt_8bit_lastrow[3:0] <= 4'd11 && T_type[1]) begin
        case (compute_cnt_8bit_lastrow[5:4])
            2'd0: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd4: pixelA_8bit_in[60] = Q_data[32];
                    'd5: pixelA_8bit_in[60] = Q_data[33];
                    'd6: pixelA_8bit_in[60] = Q_data[34];
                    'd7: pixelA_8bit_in[60] = Q_data[35];
                    'd8: pixelA_8bit_in[60] = Q_data[36]; 
                    'd9: pixelA_8bit_in[60] = Q_data[37];
                    'd10: pixelA_8bit_in[60] = Q_data[38];
                    'd11: pixelA_8bit_in[60] = Q_data[39];
                    default: pixelA_8bit_in[60] = 0; 
                endcase
            end
            2'd1: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd4: pixelA_8bit_in[60] = K_data[32];
                    'd5: pixelA_8bit_in[60] = K_data[33];
                    'd6: pixelA_8bit_in[60] = K_data[34];
                    'd7: pixelA_8bit_in[60] = K_data[35];
                    'd8: pixelA_8bit_in[60] = K_data[36]; 
                    'd9: pixelA_8bit_in[60] = K_data[37];
                    'd10: pixelA_8bit_in[60] = K_data[38];
                    'd11: pixelA_8bit_in[60] = K_data[39];
                    default: pixelA_8bit_in[60] = 0; 
                endcase
            end
            2'd2: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd4: pixelA_8bit_in[60] = V_data[32];
                    'd5: pixelA_8bit_in[60] = V_data[33];
                    'd6: pixelA_8bit_in[60] = V_data[34];
                    'd7: pixelA_8bit_in[60] = V_data[35];
                    'd8: pixelA_8bit_in[60] = V_data[36]; 
                    'd9: pixelA_8bit_in[60] = V_data[37];
                    'd10: pixelA_8bit_in[60] = V_data[38];
                    'd11: pixelA_8bit_in[60] = V_data[39];
                    default: pixelA_8bit_in[60] = 0; 
                endcase
            end
            default: pixelA_8bit_in[60] = 0; 
        endcase
    end
    else begin
        pixelA_8bit_in[60] = 0;
    end
end

always @(*) begin
    if (compute_cnt_8bit_lastrow[3:0] <= 4'd12 && T_type[1]) begin
        case (compute_cnt_8bit_lastrow[5:4])
            2'd0: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd5: pixelA_8bit_in[61] = Q_data[40];
                    'd6: pixelA_8bit_in[61] = Q_data[41];
                    'd7: pixelA_8bit_in[61] = Q_data[42];
                    'd8: pixelA_8bit_in[61] = Q_data[43]; 
                    'd9: pixelA_8bit_in[61] = Q_data[44];
                    'd10: pixelA_8bit_in[61] = Q_data[45];
                    'd11: pixelA_8bit_in[61] = Q_data[46];
                    'd12: pixelA_8bit_in[61] = Q_data[47];
                    default: pixelA_8bit_in[61] = 0; 
                endcase
            end
            2'd1: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd5: pixelA_8bit_in[61] = K_data[40];
                    'd6: pixelA_8bit_in[61] = K_data[41];
                    'd7: pixelA_8bit_in[61] = K_data[42];
                    'd8: pixelA_8bit_in[61] = K_data[43]; 
                    'd9: pixelA_8bit_in[61] = K_data[44];
                    'd10: pixelA_8bit_in[61] = K_data[45];
                    'd11: pixelA_8bit_in[61] = K_data[46];
                    'd12: pixelA_8bit_in[61] = K_data[47];
                    default: pixelA_8bit_in[61] = 0; 
                endcase
            end
            2'd2: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd5: pixelA_8bit_in[61] = V_data[40];
                    'd6: pixelA_8bit_in[61] = V_data[41];
                    'd7: pixelA_8bit_in[61] = V_data[42];
                    'd8: pixelA_8bit_in[61] = V_data[43]; 
                    'd9: pixelA_8bit_in[61] = V_data[44];
                    'd10: pixelA_8bit_in[61] = V_data[45];
                    'd11: pixelA_8bit_in[61] = V_data[46];
                    'd12: pixelA_8bit_in[61] = V_data[47];
                    default: pixelA_8bit_in[61] = 0; 
                endcase
            end
            default: pixelA_8bit_in[61] = 0; 
        endcase
    end
    else begin
        pixelA_8bit_in[61] = 0;
    end
end

always @(*) begin
    if (compute_cnt_8bit_lastrow[3:0] <= 4'd13 && T_type[1]) begin
        case (compute_cnt_8bit_lastrow[5:4])
            2'd0: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd6: pixelA_8bit_in[62] = Q_data[48];
                    'd7: pixelA_8bit_in[62] = Q_data[49];
                    'd8: pixelA_8bit_in[62] = Q_data[50]; 
                    'd9: pixelA_8bit_in[62] = Q_data[51];
                    'd10: pixelA_8bit_in[62] = Q_data[52];
                    'd11: pixelA_8bit_in[62] = Q_data[53];
                    'd12: pixelA_8bit_in[62] = Q_data[54];
                    'd13: pixelA_8bit_in[62] = Q_data[55];
                    default: pixelA_8bit_in[62] = 0; 
                endcase
            end
            2'd1: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd6: pixelA_8bit_in[62] = K_data[48];
                    'd7: pixelA_8bit_in[62] = K_data[49];
                    'd8: pixelA_8bit_in[62] = K_data[50]; 
                    'd9: pixelA_8bit_in[62] = K_data[51];
                    'd10: pixelA_8bit_in[62] = K_data[52];
                    'd11: pixelA_8bit_in[62] = K_data[53];
                    'd12: pixelA_8bit_in[62] = K_data[54];
                    'd13: pixelA_8bit_in[62] = K_data[55];
                    default: pixelA_8bit_in[62] = 0; 
                endcase
            end
            2'd2: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd6: pixelA_8bit_in[62] = V_data[48];
                    'd7: pixelA_8bit_in[62] = V_data[49];
                    'd8: pixelA_8bit_in[62] = V_data[50]; 
                    'd9: pixelA_8bit_in[62] = V_data[51];
                    'd10: pixelA_8bit_in[62] = V_data[52];
                    'd11: pixelA_8bit_in[62] = V_data[53];
                    'd12: pixelA_8bit_in[62] = V_data[54];
                    'd13: pixelA_8bit_in[62] = V_data[55];
                    default: pixelA_8bit_in[62] = 0; 
                endcase
            end
            default: pixelA_8bit_in[62] = 0; 
        endcase
    end
    else begin
        pixelA_8bit_in[62] = 0;
    end
end

always @(*) begin
    if (compute_cnt_8bit_lastrow[3:0] <= 4'd14 && T_type[1]) begin
        case (compute_cnt_8bit_lastrow[5:4])
            2'd0: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd7: pixelA_8bit_in[63] = Q_data[56];
                    'd8: pixelA_8bit_in[63] = Q_data[57]; 
                    'd9: pixelA_8bit_in[63] = Q_data[58];
                    'd10: pixelA_8bit_in[63] = Q_data[59];
                    'd11: pixelA_8bit_in[63] = Q_data[60];
                    'd12: pixelA_8bit_in[63] = Q_data[61];
                    'd13: pixelA_8bit_in[63] = Q_data[62];
                    'd14: pixelA_8bit_in[63] = Q_data[63];
                    default: pixelA_8bit_in[63] = 0; 
                endcase
            end
            2'd1: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd7: pixelA_8bit_in[63] = K_data[56];
                    'd8: pixelA_8bit_in[63] = K_data[57]; 
                    'd9: pixelA_8bit_in[63] = K_data[58];
                    'd10: pixelA_8bit_in[63] = K_data[59];
                    'd11: pixelA_8bit_in[63] = K_data[60];
                    'd12: pixelA_8bit_in[63] = K_data[61];
                    'd13: pixelA_8bit_in[63] = K_data[62];
                    'd14: pixelA_8bit_in[63] = K_data[63];
                    default: pixelA_8bit_in[63] = 0; 
                endcase
            end
            2'd2: begin
                case (compute_cnt_8bit_lastrow[3:0])
                    'd7: pixelA_8bit_in[63] = V_data[56];
                    'd8: pixelA_8bit_in[63] = V_data[57]; 
                    'd9: pixelA_8bit_in[63] = V_data[58];
                    'd10: pixelA_8bit_in[63] = V_data[59];
                    'd11: pixelA_8bit_in[63] = V_data[60];
                    'd12: pixelA_8bit_in[63] = V_data[61];
                    'd13: pixelA_8bit_in[63] = V_data[62];
                    'd14: pixelA_8bit_in[63] = V_data[63];
                    default: pixelA_8bit_in[63] = 0; 
                endcase
            end
            default: pixelA_8bit_in[63] = 0; 
        endcase
    end
    else begin
        pixelA_8bit_in[63] = 0;
    end
end

always @(*) begin
    for (i = 0; i < 56; i = i + 1) begin
        pixelB_8bit_in[i] = 0;
    end
    if (compute_cnt_8bit[3:0] || compute_cnt_8bit_lastrow[3:0]) begin
        case (T_type)
            2'd0: begin
                for (i = 0; i < 8; i = i + 1)
                    pixelB_8bit_in[i] = X_data[i];
            end
            2'd1: begin
                for (i = 0; i < 8; i = i + 1)
                    pixelB_8bit_in[i] = X_data[i];
                for (i = 8; i < 16; i = i + 1)
                    pixelB_8bit_in[i] = X_data[i];
                for (i = 16; i < 24; i = i + 1)
                    pixelB_8bit_in[i] = X_data[i];
                for (i = 24; i < 32; i = i + 1)
                    pixelB_8bit_in[i] = X_data[i];
            end
            2'd2: begin
                for (i = 0; i < 56; i = i + 1) begin
                    pixelB_8bit_in[i] = X_data[i];
                end
            end
            default: begin
                for (i = 0; i < 56; i = i + 1) begin
                    pixelB_8bit_in[i] = 0;
                end
            end 
        endcase
    end
    else begin
        for (i = 0; i < 56; i = i + 1) begin
            pixelB_8bit_in[i] = 0;
        end
    end
end

always @(*) begin
    if (T_type[1]) begin
        for (i = 56; i < 64; i = i + 1) begin
            if (i == cnt)
                pixelB_8bit_in[i] = in_data;
            else
                pixelB_8bit_in[i] = X_data[i];
        end
    end
    else begin
        for (i = 56; i < 64; i = i + 1) begin
            pixelB_8bit_in[i] = 0;
        end
    end
end

always @(*) begin
    //if (cnt) begin
    if (compute_cnt_8bit[3:0]) begin
        for (i = 0; i < 56; i = i + 8) begin
            partial_8bit_in[i] = 0;
        end
        for (i = 1; i < 56; i = i + 8) begin
            partial_8bit_in[i] = partial_8bit_out[i-1];
        end
        for (i = 2; i < 56; i = i + 8) begin
            partial_8bit_in[i] = partial_8bit_out[i-1];
        end
        for (i = 3; i < 56; i = i + 8) begin
            partial_8bit_in[i] = partial_8bit_out[i-1];
        end
        for (i = 4; i < 56; i = i + 8) begin
            partial_8bit_in[i] = partial_8bit_out[i-1];
        end
        for (i = 5; i < 56; i = i + 8) begin
            partial_8bit_in[i] = partial_8bit_out[i-1];
        end
        for (i = 6; i < 56; i = i + 8) begin
            partial_8bit_in[i] = partial_8bit_out[i-1];
        end
        for (i = 7; i < 56; i = i + 8) begin
            partial_8bit_in[i] = partial_8bit_out[i-1];
        end
    end
    else begin
        for (i = 0; i < 56; i = i + 1) begin
            partial_8bit_in[i] = 0;
        end
    end
end

always @(*) begin
    partial_8bit_in[56] = 0;
    if (compute_cnt_8bit[3] || compute_cnt_8bit_lastrow[3:0]) begin
        for (i = 57; i < 64; i = i + 1) begin
            partial_8bit_in[i] = partial_8bit_out[i-1];
        end
    end
    else begin
        for (i = 57; i < 64; i = i + 1) begin
            partial_8bit_in[i] = 0;
        end
    end
end

always @(*) begin
    if (cnt >= 121)
        pixelA_in[0] = QK_data[{QK_compute_cnt[5:3], 3'd0}];
    else
        pixelA_in[0] = 0;
end

always @(*) begin
    if (cnt >= 122) begin
        case (QK_compute_cnt[5:0])
            6'd1, 6'd2, 6'd3, 6'd4, 6'd5, 6'd6, 6'd7, 6'd8: pixelA_in[1] = QK_data[1];
            6'd9, 6'd10, 6'd11, 6'd12, 6'd13, 6'd14, 6'd15, 6'd16: pixelA_in[1] = QK_data[9];
            6'd17, 6'd18, 6'd19, 6'd20, 6'd21, 6'd22, 6'd23, 6'd24: pixelA_in[1] = QK_data[17];
            6'd25, 6'd26, 6'd27, 6'd28, 6'd29, 6'd30, 6'd31, 6'd32: pixelA_in[1] = QK_data[25];
            6'd33, 6'd34, 6'd35, 6'd36, 6'd37, 6'd38, 6'd39, 6'd40: pixelA_in[1] = QK_data[33];
            6'd41, 6'd42, 6'd43, 6'd44, 6'd45, 6'd46, 6'd47, 6'd48: pixelA_in[1] = QK_data[41];
            6'd49, 6'd50, 6'd51, 6'd52, 6'd53, 6'd54, 6'd55, 6'd56: pixelA_in[1] = QK_data[49];
            6'd57, 6'd58, 6'd59, 6'd60, 6'd61, 6'd62, 6'd63, 6'd0: pixelA_in[1] = QK_data[57];
            default: pixelA_in[1] = 0;
        endcase
    end
    else begin
        pixelA_in[1] = 0;
    end
end

always @(*) begin
    if (cnt >= 123) begin
        case (QK_compute_cnt[5:0])
            6'd2, 6'd3, 6'd4, 6'd5, 6'd6, 6'd7, 6'd8, 6'd9: pixelA_in[2] = QK_data[2];
            6'd10, 6'd11, 6'd12, 6'd13, 6'd14, 6'd15, 6'd16, 6'd17: pixelA_in[2] = QK_data[10];
            6'd18, 6'd19, 6'd20, 6'd21, 6'd22, 6'd23, 6'd24, 6'd25: pixelA_in[2] = QK_data[18];
            6'd26, 6'd27, 6'd28, 6'd29, 6'd30, 6'd31, 6'd32, 6'd33: pixelA_in[2] = QK_data[26];
            6'd34, 6'd35, 6'd36, 6'd37, 6'd38, 6'd39, 6'd40, 6'd41: pixelA_in[2] = QK_data[34];
            6'd42, 6'd43, 6'd44, 6'd45, 6'd46, 6'd47, 6'd48, 6'd49: pixelA_in[2] = QK_data[42];
            6'd50, 6'd51, 6'd52, 6'd53, 6'd54, 6'd55, 6'd56, 6'd57: pixelA_in[2] = QK_data[50];
            6'd58, 6'd59, 6'd60, 6'd61, 6'd62, 6'd63, 6'd0, 6'd1: pixelA_in[2] = QK_data[58];
            default: pixelA_in[2] = 0;
        endcase
    end
    else begin
        pixelA_in[2] = 0;
    end
end

always @(*) begin
    if (cnt >= 124) begin
        case (QK_compute_cnt[5:0])
            6'd3, 6'd4, 6'd5, 6'd6, 6'd7, 6'd8, 6'd9, 6'd10: pixelA_in[3] = QK_data[3];
            6'd11, 6'd12, 6'd13, 6'd14, 6'd15, 6'd16, 6'd17, 6'd18: pixelA_in[3] = QK_data[11];
            6'd19, 6'd20, 6'd21, 6'd22, 6'd23, 6'd24, 6'd25, 6'd26: pixelA_in[3] = QK_data[19];
            6'd27, 6'd28, 6'd29, 6'd30, 6'd31, 6'd32, 6'd33, 6'd34: pixelA_in[3] = QK_data[27];
            6'd35, 6'd36, 6'd37, 6'd38, 6'd39, 6'd40, 6'd41, 6'd42: pixelA_in[3] = QK_data[35];
            6'd43, 6'd44, 6'd45, 6'd46, 6'd47, 6'd48, 6'd49, 6'd50: pixelA_in[3] = QK_data[43];
            6'd51, 6'd52, 6'd53, 6'd54, 6'd55, 6'd56, 6'd57, 6'd58: pixelA_in[3] = QK_data[51];
            6'd59, 6'd60, 6'd61, 6'd62, 6'd63, 6'd0, 6'd1, 6'd2: pixelA_in[3] = QK_data[59];
            default: pixelA_in[3] = 0;
        endcase
    end
    else begin
        pixelA_in[3] = 0;
    end
end

always @(*) begin
    if (cnt >= 125) begin
        case (QK_compute_cnt[5:0])
            6'd4, 6'd5, 6'd6, 6'd7, 6'd8, 6'd9, 6'd10, 6'd11: pixelA_in[4] = QK_data[4];
            6'd12, 6'd13, 6'd14, 6'd15, 6'd16, 6'd17, 6'd18, 6'd19: pixelA_in[4] = QK_data[12];
            6'd20, 6'd21, 6'd22, 6'd23, 6'd24, 6'd25, 6'd26, 6'd27: pixelA_in[4] = QK_data[20];
            6'd28, 6'd29, 6'd30, 6'd31, 6'd32, 6'd33, 6'd34, 6'd35: pixelA_in[4] = QK_data[28];
            6'd36, 6'd37, 6'd38, 6'd39, 6'd40, 6'd41, 6'd42, 6'd43: pixelA_in[4] = QK_data[36];
            6'd44, 6'd45, 6'd46, 6'd47, 6'd48, 6'd49, 6'd50, 6'd51: pixelA_in[4] = QK_data[44];
            6'd52, 6'd53, 6'd54, 6'd55, 6'd56, 6'd57, 6'd58, 6'd59: pixelA_in[4] = QK_data[52];
            6'd60, 6'd61, 6'd62, 6'd63, 6'd0, 6'd1, 6'd2, 6'd3: pixelA_in[4] = QK_data[60];
            default: pixelA_in[4] = 0;
        endcase
    end
    else begin
        pixelA_in[4] = 0;
    end
end

always @(*) begin
    if (cnt >= 126) begin
        case (QK_compute_cnt[5:0])
            6'd5, 6'd6, 6'd7, 6'd8, 6'd9, 6'd10, 6'd11, 6'd12: pixelA_in[5] = QK_data[5];
            6'd13, 6'd14, 6'd15, 6'd16, 6'd17, 6'd18, 6'd19, 6'd20: pixelA_in[5] = QK_data[13];
            6'd21, 6'd22, 6'd23, 6'd24, 6'd25, 6'd26, 6'd27, 6'd28: pixelA_in[5] = QK_data[21];
            6'd29, 6'd30, 6'd31, 6'd32, 6'd33, 6'd34, 6'd35, 6'd36: pixelA_in[5] = QK_data[29];
            6'd37, 6'd38, 6'd39, 6'd40, 6'd41, 6'd42, 6'd43, 6'd44: pixelA_in[5] = QK_data[37];
            6'd45, 6'd46, 6'd47, 6'd48, 6'd49, 6'd50, 6'd51, 6'd52: pixelA_in[5] = QK_data[45];
            6'd53, 6'd54, 6'd55, 6'd56, 6'd57, 6'd58, 6'd59, 6'd60: pixelA_in[5] = QK_data[53];
            6'd61, 6'd62, 6'd63, 6'd0, 6'd1, 6'd2, 6'd3, 6'd4: pixelA_in[5] = QK_data[61];
            default: pixelA_in[5] = 0;
        endcase
    end
    else begin
        pixelA_in[5] = 0;
    end
end

always @(*) begin
    if (cnt >= 127) begin
        case (QK_compute_cnt[5:0])
            6'd6, 6'd7, 6'd8, 6'd9, 6'd10, 6'd11, 6'd12, 6'd13: pixelA_in[6] = QK_data[6];
            6'd14, 6'd15, 6'd16, 6'd17, 6'd18, 6'd19, 6'd20, 6'd21: pixelA_in[6] = QK_data[14];
            6'd22, 6'd23, 6'd24, 6'd25, 6'd26, 6'd27, 6'd28, 6'd29: pixelA_in[6] = QK_data[22];
            6'd30, 6'd31, 6'd32, 6'd33, 6'd34, 6'd35, 6'd36, 6'd37: pixelA_in[6] = QK_data[30];
            6'd38, 6'd39, 6'd40, 6'd41, 6'd42, 6'd43, 6'd44, 6'd45: pixelA_in[6] = QK_data[38];
            6'd46, 6'd47, 6'd48, 6'd49, 6'd50, 6'd51, 6'd52, 6'd53: pixelA_in[6] = QK_data[46];
            6'd54, 6'd55, 6'd56, 6'd57, 6'd58, 6'd59, 6'd60, 6'd61: pixelA_in[6] = QK_data[54];
            6'd62, 6'd63, 6'd0, 6'd1, 6'd2, 6'd3, 6'd4, 6'd5: pixelA_in[6] = QK_data[62];
            default: pixelA_in[6] = 0;
        endcase
    end
    else begin
        pixelA_in[6] = 0;
    end
end

always @(*) begin
    if (cnt >= 128) begin
        case (QK_compute_cnt[5:0])
            6'd7, 6'd8, 6'd9, 6'd10, 6'd11, 6'd12, 6'd13, 6'd14: pixelA_in[7] = QK_data[7];
            6'd15, 6'd16, 6'd17, 6'd18, 6'd19, 6'd20, 6'd21, 6'd22: pixelA_in[7] = QK_data[15];
            6'd23, 6'd24, 6'd25, 6'd26, 6'd27, 6'd28, 6'd29, 6'd30: pixelA_in[7] = QK_data[23];
            6'd31, 6'd32, 6'd33, 6'd34, 6'd35, 6'd36, 6'd37, 6'd38: pixelA_in[7] = QK_data[31];
            6'd39, 6'd40, 6'd41, 6'd42, 6'd43, 6'd44, 6'd45, 6'd46: pixelA_in[7] = QK_data[39];
            6'd47, 6'd48, 6'd49, 6'd50, 6'd51, 6'd52, 6'd53, 6'd54: pixelA_in[7] = QK_data[47];
            6'd55, 6'd56, 6'd57, 6'd58, 6'd59, 6'd60, 6'd61, 6'd62: pixelA_in[7] = QK_data[55];
            6'd63, 6'd0, 6'd1, 6'd2, 6'd3, 6'd4, 6'd5, 6'd6: pixelA_in[7] = QK_data[63];
            default: pixelA_in[7] = 0;
        endcase
    end
    else begin
        pixelA_in[7] = 0;
    end
end

always @(*) begin
    if (QK_compute_cnt <= 7'd63) begin
        pixelB_in[0] = XK_data[{QK_compute_cnt[2:0], 3'd0}];
    end
    else begin
        pixelB_in[0] = XV_data[QK_compute_cnt[2:0]];
    end
end

always @(*) begin
    if (QK_compute_cnt >= 7'd1 && QK_compute_cnt <= 7'd64) begin
        case (QK_compute_cnt[2:0])
            3'd0: pixelB_in[1] = XK_data[57];
            3'd1: pixelB_in[1] = XK_data[1];
            3'd2: pixelB_in[1] = XK_data[9];
            3'd3: pixelB_in[1] = XK_data[17];
            3'd4: pixelB_in[1] = XK_data[25];
            3'd5: pixelB_in[1] = XK_data[33];
            3'd6: pixelB_in[1] = XK_data[41];
            3'd7: pixelB_in[1] = XK_data[49];
            default: pixelB_in[1] = 0;
        endcase
    end
    else if (QK_compute_cnt[7] ^ QK_compute_cnt[6]) begin
        case (QK_compute_cnt[2:0])
            3'd0: pixelB_in[1] = XV_data[15];
            3'd1: pixelB_in[1] = XV_data[8];
            3'd2: pixelB_in[1] = XV_data[9];
            3'd3: pixelB_in[1] = XV_data[10];
            3'd4: pixelB_in[1] = XV_data[11];
            3'd5: pixelB_in[1] = XV_data[12];
            3'd6: pixelB_in[1] = XV_data[13];
            3'd7: pixelB_in[1] = XV_data[14];
            default: pixelB_in[1] = 0;
        endcase
    end
    else begin
        pixelB_in[1] = 0;
    end
end

always @(*) begin
    if (QK_compute_cnt >= 7'd2 && QK_compute_cnt <= 7'd65) begin
        case (QK_compute_cnt[2:0])
            3'd0: pixelB_in[2] = XK_data[50];
            3'd1: pixelB_in[2] = XK_data[58];
            3'd2: pixelB_in[2] = XK_data[2];
            3'd3: pixelB_in[2] = XK_data[10];
            3'd4: pixelB_in[2] = XK_data[18];
            3'd5: pixelB_in[2] = XK_data[26];
            3'd6: pixelB_in[2] = XK_data[34];
            3'd7: pixelB_in[2] = XK_data[42];
            default: pixelB_in[2] = 0;
        endcase
    end
    else if (QK_compute_cnt[7] ^ QK_compute_cnt[6]) begin
        case (QK_compute_cnt[2:0])
            3'd0: pixelB_in[2] = XV_data[22];
            3'd1: pixelB_in[2] = XV_data[23];
            3'd2: pixelB_in[2] = XV_data[16];
            3'd3: pixelB_in[2] = XV_data[17];
            3'd4: pixelB_in[2] = XV_data[18];
            3'd5: pixelB_in[2] = XV_data[19];
            3'd6: pixelB_in[2] = XV_data[20];
            3'd7: pixelB_in[2] = XV_data[21];
            default: pixelB_in[2] = 0;
        endcase
    end
    else begin
        pixelB_in[2] = 0;
    end
end

always @(*) begin
    if (QK_compute_cnt >= 7'd3 && QK_compute_cnt <= 7'd66) begin
        case (QK_compute_cnt[2:0])
            3'd0: pixelB_in[3] = XK_data[43];
            3'd1: pixelB_in[3] = XK_data[51];
            3'd2: pixelB_in[3] = XK_data[59];
            3'd3: pixelB_in[3] = XK_data[3];
            3'd4: pixelB_in[3] = XK_data[11];
            3'd5: pixelB_in[3] = XK_data[19];
            3'd6: pixelB_in[3] = XK_data[27];
            3'd7: pixelB_in[3] = XK_data[35];
            default: pixelB_in[3] = 0;
        endcase
    end
    else if (QK_compute_cnt[7] ^ QK_compute_cnt[6]) begin
        case (QK_compute_cnt[2:0])
            3'd0: pixelB_in[3] = XV_data[29];
            3'd1: pixelB_in[3] = XV_data[30];
            3'd2: pixelB_in[3] = XV_data[31];
            3'd3: pixelB_in[3] = XV_data[24];
            3'd4: pixelB_in[3] = XV_data[25];
            3'd5: pixelB_in[3] = XV_data[26];
            3'd6: pixelB_in[3] = XV_data[27];
            3'd7: pixelB_in[3] = XV_data[28];
            default: pixelB_in[3] = 0;
        endcase
    end
    else begin
        pixelB_in[3] = 0;
    end
end

always @(*) begin
    if (QK_compute_cnt >= 7'd4 && QK_compute_cnt <= 7'd67) begin
        case (QK_compute_cnt[2:0])
            3'd0: pixelB_in[4] = XK_data[36];
            3'd1: pixelB_in[4] = XK_data[44];
            3'd2: pixelB_in[4] = XK_data[52];
            3'd3: pixelB_in[4] = XK_data[60];
            3'd4: pixelB_in[4] = XK_data[4];
            3'd5: pixelB_in[4] = XK_data[12];
            3'd6: pixelB_in[4] = XK_data[20];
            3'd7: pixelB_in[4] = XK_data[28];
            default: pixelB_in[4] = 0;
        endcase
    end
    else if (QK_compute_cnt[7] ^ QK_compute_cnt[6]) begin
        case (QK_compute_cnt[2:0])
            3'd0: pixelB_in[4] = XV_data[36];
            3'd1: pixelB_in[4] = XV_data[37];
            3'd2: pixelB_in[4] = XV_data[38];
            3'd3: pixelB_in[4] = XV_data[39];
            3'd4: pixelB_in[4] = XV_data[32];
            3'd5: pixelB_in[4] = XV_data[33];
            3'd6: pixelB_in[4] = XV_data[34];
            3'd7: pixelB_in[4] = XV_data[35];
            default: pixelB_in[4] = 0;
        endcase
    end
    else begin
        pixelB_in[4] = 0;
    end
end

always @(*) begin
    if (QK_compute_cnt >= 7'd5 && QK_compute_cnt <= 7'd68) begin
        case (QK_compute_cnt[2:0])
            3'd0: pixelB_in[5] = XK_data[29];
            3'd1: pixelB_in[5] = XK_data[37];
            3'd2: pixelB_in[5] = XK_data[45];
            3'd3: pixelB_in[5] = XK_data[53];
            3'd4: pixelB_in[5] = XK_data[61];
            3'd5: pixelB_in[5] = XK_data[5];
            3'd6: pixelB_in[5] = XK_data[13];
            3'd7: pixelB_in[5] = XK_data[21];
            default: pixelB_in[5] = 0;
        endcase
    end
    else if (QK_compute_cnt[7] ^ QK_compute_cnt[6]) begin
        case (QK_compute_cnt[2:0])
            3'd0: pixelB_in[5] = XV_data[43];
            3'd1: pixelB_in[5] = XV_data[44];
            3'd2: pixelB_in[5] = XV_data[45];
            3'd3: pixelB_in[5] = XV_data[46];
            3'd4: pixelB_in[5] = XV_data[47];
            3'd5: pixelB_in[5] = XV_data[40];
            3'd6: pixelB_in[5] = XV_data[41];
            3'd7: pixelB_in[5] = XV_data[42];
            default: pixelB_in[5] = 0;
        endcase
    end
    else begin
        pixelB_in[5] = 0;
    end
end

always @(*) begin
    if (QK_compute_cnt >= 7'd6 && QK_compute_cnt <= 7'd69) begin
        case (QK_compute_cnt[2:0])
            3'd0: pixelB_in[6] = XK_data[22];
            3'd1: pixelB_in[6] = XK_data[30];
            3'd2: pixelB_in[6] = XK_data[38];
            3'd3: pixelB_in[6] = XK_data[46];
            3'd4: pixelB_in[6] = XK_data[54];
            3'd5: pixelB_in[6] = XK_data[62];
            3'd6: pixelB_in[6] = XK_data[6];
            3'd7: pixelB_in[6] = XK_data[14];
            default: pixelB_in[6] = 0;
        endcase
    end
    else if (QK_compute_cnt[7] ^ QK_compute_cnt[6]) begin
        case (QK_compute_cnt[2:0])
            3'd0: pixelB_in[6] = XV_data[50];
            3'd1: pixelB_in[6] = XV_data[51];
            3'd2: pixelB_in[6] = XV_data[52];
            3'd3: pixelB_in[6] = XV_data[53];
            3'd4: pixelB_in[6] = XV_data[54];
            3'd5: pixelB_in[6] = XV_data[55];
            3'd6: pixelB_in[6] = XV_data[48];
            3'd7: pixelB_in[6] = XV_data[49];
            default: pixelB_in[6] = 0;
        endcase
    end
    else begin
        pixelB_in[6] = 0;
    end
end

always @(*) begin
    if (QK_compute_cnt >= 7'd7 && QK_compute_cnt <= 7'd70) begin
        case (QK_compute_cnt[2:0])
            3'd0: pixelB_in[7] = XK_data[15];
            3'd1: pixelB_in[7] = XK_data[23];
            3'd2: pixelB_in[7] = XK_data[31];
            3'd3: pixelB_in[7] = XK_data[39];
            3'd4: pixelB_in[7] = XK_data[47];
            3'd5: pixelB_in[7] = XK_data[55];
            3'd6: pixelB_in[7] = XK_data[63];
            3'd7: pixelB_in[7] = XK_data[7];
            default: pixelB_in[7] = 0;
        endcase
    end
    else if (QK_compute_cnt[7] ^ QK_compute_cnt[6]) begin
        case (QK_compute_cnt[2:0])
            3'd0: pixelB_in[7] = XV_data[57];
            3'd1: pixelB_in[7] = XV_data[58];
            3'd2: pixelB_in[7] = XV_data[59];
            3'd3: pixelB_in[7] = XV_data[60];
            3'd4: pixelB_in[7] = XV_data[61];
            3'd5: pixelB_in[7] = XV_data[62];
            3'd6: pixelB_in[7] = XV_data[63];
            3'd7: pixelB_in[7] = XV_data[56];
            default: pixelB_in[7] = 0;
        endcase
    end
    else begin
        pixelB_in[7] = 0;
    end
end

assign partial_in[0] = 0;
assign partial_in[1] = (cnt >= 122 && cnt <= 249)? partial_out[0] : 0;
assign partial_in[2] = (cnt >= 123 && cnt <= 250)? partial_out[1] : 0;
assign partial_in[3] = (cnt >= 124 && cnt <= 251)? partial_out[2] : 0;
assign partial_in[4] = (cnt >= 125 && cnt <= 252)? partial_out[3] : 0;
assign partial_in[5] = (cnt >= 126 && cnt <= 253)? partial_out[4] : 0;
assign partial_in[6] = (cnt >= 127 && cnt <= 254)? partial_out[5] : 0;
assign partial_in[7] = (cnt >= 128 && cnt <= 255)? partial_out[6] : 0;

generate
    for(k=0; k<8; k=k+1)begin: PE_0
        PE u_0(.clk(clk), .pixelA(pixelA_in[k]), .pixelB(pixelB_in[k]), .partial_in(partial_in[k]), .partial_out(partial_out[k]), .partial_out_wire(partial_out_wire[k]));
    end
endgenerate

generate
    for(k=0; k<64; k=k+1)begin: PE_1
        PE_8bit u_0(.clk(clk), .pixelA(pixelA_8bit_in[k]), .pixelB(pixelB_8bit_in[k]), .partial_in(partial_8bit_in[k]), .partial_out(partial_8bit_out[k]), .partial_out_wire(partial_8bit_out_wire[k]));
    end
endgenerate

endmodule

module PE(
    clk,
    pixelA,
    pixelB,
    partial_in,
    partial_out,
    partial_out_wire
);

input clk;
input signed [39:0]pixelA;
input signed [18:0]pixelB;
input signed [61:0]partial_in;
output reg signed[61:0]partial_out, partial_out_wire;
reg signed [58:0] temp;

always @(*) begin
    temp = pixelA * pixelB;
    partial_out_wire = temp + partial_in;
end

always @(posedge clk) begin
    partial_out <= partial_out_wire;
end

endmodule

module PE_8bit(
    clk,
    pixelA,
    pixelB,
    partial_in,
    partial_out,
    partial_out_wire
);

input clk;
input signed [7:0]pixelA;
input signed [7:0]pixelB;
input signed [18:0]partial_in;
output reg signed[18:0]partial_out, partial_out_wire;
reg signed [15:0] temp;

always @(*) begin
    temp = pixelA * pixelB;
    partial_out_wire = temp + partial_in;
end

always @(posedge clk) begin
    partial_out <= partial_out_wire;
end

endmodule
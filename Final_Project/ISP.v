module ISP(
    // Input Signals
    input clk,
    input rst_n,
    input in_valid,
    input [3:0] in_pic_no,
    input [1:0] in_mode,
    input [1:0] in_ratio_mode,

    // Output Signals
    output reg out_valid,
    output reg [7:0] out_data,
    
    // DRAM Signals
    // axi write address channel
    // src master
    output reg [3:0]  awid_s_inf,
    output reg [31:0] awaddr_s_inf,
    output reg [2:0]  awsize_s_inf,
    output reg [1:0]  awburst_s_inf,
    output reg [7:0]  awlen_s_inf,
    output reg        awvalid_s_inf,
    // src slave
    input         awready_s_inf,
    // -----------------------------
  
    // axi write data channel 
    // src master
    output reg [127:0] wdata_s_inf,
    output reg         wlast_s_inf,
    output reg         wvalid_s_inf,
    // src slave
    input          wready_s_inf,
  
    // axi write response channel 
    // src slave
    input [3:0]    bid_s_inf,
    input [1:0]    bresp_s_inf,
    input          bvalid_s_inf,
    // src master 
    output reg     bready_s_inf,
    // -----------------------------
  
    // axi read address channel 
    // src master
    output reg [3:0]   arid_s_inf,
    output reg [31:0]  araddr_s_inf,
    output reg [7:0]   arlen_s_inf,
    output reg [2:0]   arsize_s_inf,
    output reg [1:0]   arburst_s_inf,
    output reg         arvalid_s_inf,
    // src slave
    input          arready_s_inf,
    // -----------------------------
  
    // axi read data channel 
    // slave
    input [3:0]    rid_s_inf,
    input [127:0]  rdata_s_inf,
    input [1:0]    rresp_s_inf,
    input          rlast_s_inf,
    input          rvalid_s_inf,
    // master
    output reg         rready_s_inf
    
);

// Your Design
integer i;
parameter idle = 3'd0, wait_DRAM = 3'd1, read_DRAM = 3'd2, skip_compute = 3'd3;

reg [2:0]   cs, ns;
reg [15:0]  img_addr;
reg [7:0]   img_addr_base;
reg [7:0]   n_img_addr_base;
reg [1:0]   reg_mode;
reg [1:0]   reg_ratio_mode;
reg [3:0]   reg_pic_no;
reg [7:0]   cnt;
reg [1:0]   wait_cnt;
reg [5:0]   compute_cnt;
reg [7:0]   focus_table [0:35];
reg [127:0] in_buf;
reg [5:0]   min_cnt1, min_cnt2, min_cnt3, min_cnt4;
reg [7:0]   sub1, sub2, sub3, sub4;
reg [7:0]   diff1, diff2;
reg [8:0]   diff_sum;
reg [13:0]  focus1;
reg [12:0]  focus2;
reg [11:0]  focus2_t1, focus2_t2;
reg [9:0]   focus3;
reg [8:0]   focus3_t1, focus3_t2;
reg [1:0]   focus_ans [0:15];

reg [6:0]   addA_L1 [0:7];
reg [6:0]   addB_L1 [0:7];
reg [7:0]   add_out_L1 [0:7];
reg [7:0]   addA_L2 [0:3];
reg [7:0]   addB_L2 [0:3];
reg [8:0]   add_out_L2 [0:3];
reg [8:0]   addA_L3 [0:1];
reg [8:0]   addB_L3 [0:1];
reg [9:0]   add_out_L3 [0:1];
reg [10:0]  add_out_L4;
reg [17:0]  exposure_temp;
reg [7:0]   exposure_ans [0:15];
reg [15:0]  focus_computed;
reg [15:0]  all_zero;
reg [1:0]   add_type;

reg [7:0]   min [0:2];
reg [7:0]   max [0:2];
reg [7:0]   minmax_avg [0:15];
//---------------------------//
//         AXI4 Port         //
//---------------------------//

assign awid_s_inf = 0;
assign awsize_s_inf = (cs != idle)? 3'b100 : 0;
assign awburst_s_inf = (cs != idle)? 2'b01 : 0;
assign awlen_s_inf = (cs != idle)? 191 : 0;
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         awsize_s_inf <= 0;
//         awburst_s_inf <= 0;
//         awlen_s_inf <= 0;
//     end begin
//         awsize_s_inf <= (ns != idle)? 3'b100 : 0;
//         awburst_s_inf <= (ns != idle)? 2'b01 : 0;
//         awlen_s_inf <= (ns != idle)? 191 : 0;
//     end
// end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        awvalid_s_inf <= 0;
        // awaddr_s_inf <= 0;
    end
    else if (cs == wait_DRAM && reg_ratio_mode != 2'd2 && reg_mode[0] && !wait_cnt[1]) begin
        //awvalid_s_inf <= (cs == wait_DRAM && reg_ratio_mode != 2'd2 && reg_mode[0] && !wait_cnt[1])? 1 : 0;
        awvalid_s_inf <= 1;
        // awaddr_s_inf <= {16'd1, n_img_addr_base, 8'd0};
    end
    else begin
        awvalid_s_inf <= 0;
        // awaddr_s_inf <= 0;
    end
end
assign awaddr_s_inf = (awvalid_s_inf)? {16'd1, img_addr_base, 8'd0} : 0;

assign arid_s_inf = 0;
assign arlen_s_inf = (cs != idle)? 191 : 0;
assign arsize_s_inf = (cs != idle)? 3'b100 : 0;
assign arburst_s_inf = (cs != idle)? 2'b01 : 0;
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         arlen_s_inf <= 0;
//         arsize_s_inf <= 0;
//         arburst_s_inf <= 0;
//     end
//     else begin
//         arlen_s_inf <= (ns != idle)? 191 : 0;
//         arsize_s_inf <= (ns != idle)? 3'b100 : 0;
//         arburst_s_inf <= (ns != idle)? 2'b01 : 0;
//     end
// end

assign arvalid_s_inf = (cs == wait_DRAM && !wait_cnt[1])? 1 : 0;
assign bready_s_inf = (cs == read_DRAM)? 1 : 0;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wvalid_s_inf <= 0;
        wlast_s_inf <= 0;
        wdata_s_inf <= 0;
        // arvalid_s_inf <= 0;
        // bready_s_inf <= 0;
    end
    else begin
        wvalid_s_inf <= (cs == read_DRAM && cnt != 4)? 1 : 0;
        wlast_s_inf <= (cs == read_DRAM && cnt == 195)? 1 : 0; 
        wdata_s_inf <= (cs != idle)? in_buf : 0;
        // arvalid_s_inf <= (ns == wait_DRAM && !wait_cnt)? 1 : 0;
        // bready_s_inf <= (ns == wait_DRAM)? 1 : 0;
    end
end
assign araddr_s_inf = (cs == wait_DRAM)? {16'd1, img_addr_base, 8'd0} : 0;
assign rready_s_inf = (cnt >= 3)? 1 : 0;
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         araddr_s_inf <= 0;
//         rready_s_inf <= 0;
//     end
//     else begin
//         araddr_s_inf <= (ns == wait_DRAM)? {16'd1, n_img_addr_base, 8'd0} : 0;
//         rready_s_inf <= (cnt >= 2)? 1 : 0;
//     end
// end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 0;
        out_data <= 0;
    end
    else begin
        if ((cs == read_DRAM && cnt == 208) || cs == skip_compute) begin
            out_valid <= 1;
            case (reg_mode)
                2'd0: out_data <= focus_ans[reg_pic_no];
                2'd1: out_data <= exposure_ans[reg_pic_no];
                2'd2: out_data <= minmax_avg[reg_pic_no]; 
            endcase
            // out_data <= (reg_mode)? exposure_ans[reg_pic_no] : focus_ans[reg_pic_no];
        end
        else begin
            out_valid <= 0;
            out_data <= 0;
        end
    end
end

// always @(*) begin
//     out_data = (!out_valid)? 0 : (reg_mode)? exposure_ans[reg_pic_no] : focus_ans[reg_pic_no];
// end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cs <= idle;
    end
    else begin
        cs <= ns;
    end
end

always @(*) begin
    case (cs)
        idle: begin
            if (in_valid) begin
                if (in_mode[0]) begin
                    if (all_zero[in_pic_no] || (focus_computed[in_pic_no] && in_ratio_mode == 2'd2))
                        ns = skip_compute;
                    else
                        ns = wait_DRAM;
                end
                else begin
                    if (all_zero[in_pic_no] || focus_computed[in_pic_no])
                        ns = skip_compute;
                    else
                        ns = wait_DRAM;
                end
            end
            else
                ns = idle;
        end
        wait_DRAM: ns = (rvalid_s_inf)? read_DRAM : wait_DRAM;
        read_DRAM: ns = (cnt == 208)? idle : read_DRAM;
        skip_compute: ns = idle;
        default: ns = idle;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        focus_computed <= 0;
    end
    else begin
        if (cs == wait_DRAM) begin
            focus_computed[reg_pic_no] <= 1;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        all_zero <= 0;
    end
    else begin
        case (cs)
            wait_DRAM: all_zero[reg_pic_no] <= 1;
            read_DRAM: begin
                if (cnt <= 195 && in_buf) begin
                    all_zero[reg_pic_no] <= 0;
                end
            end
        endcase
    end
end

always @(posedge clk) begin
    if (in_valid) begin
        reg_pic_no <= in_pic_no;
        // $display("pic_no = %d", in_pic_no);
        // if (in_mode) begin
        //     $display("ratio mode = %d", in_ratio_mode);
        // end
        // else
        //     $display("focus mode");
        img_addr_base <= n_img_addr_base;
        // case (in_pic_no)
        //     4'd0: img_addr_base <= 0;
        //     4'd1: img_addr_base <= 8'h0C;
        //     4'd2: img_addr_base <= 8'h18;
        //     4'd3: img_addr_base <= 8'h24;
        //     4'd4: img_addr_base <= 8'h30;
        //     4'd5: img_addr_base <= 8'h3C;
        //     4'd6: img_addr_base <= 8'h48;
        //     4'd7: img_addr_base <= 8'h54;
        //     4'd8: img_addr_base <= 8'h60;
        //     4'd9: img_addr_base <= 8'h6C;
        //     4'd10: img_addr_base <= 8'h78;
        //     4'd11: img_addr_base <= 8'h84;
        //     4'd12: img_addr_base <= 8'h90;
        //     4'd13: img_addr_base <= 8'h9C;
        //     4'd14: img_addr_base <= 8'hA8;
        //     4'd15: img_addr_base <= 8'hB4;
        // endcase
    end
end

always @(*) begin
    if (in_valid) begin
        case (in_pic_no)
            4'd0: n_img_addr_base = 0;
            4'd1: n_img_addr_base = 8'h0C;
            4'd2: n_img_addr_base = 8'h18;
            4'd3: n_img_addr_base = 8'h24;
            4'd4: n_img_addr_base = 8'h30;
            4'd5: n_img_addr_base = 8'h3C;
            4'd6: n_img_addr_base = 8'h48;
            4'd7: n_img_addr_base = 8'h54;
            4'd8: n_img_addr_base = 8'h60;
            4'd9: n_img_addr_base = 8'h6C;
            4'd10: n_img_addr_base = 8'h78;
            4'd11: n_img_addr_base = 8'h84;
            4'd12: n_img_addr_base = 8'h90;
            4'd13: n_img_addr_base = 8'h9C;
            4'd14: n_img_addr_base = 8'hA8;
            4'd15: n_img_addr_base = 8'hB4;
        endcase
    end
    else
        n_img_addr_base = 0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        reg_mode <= 0;
    end
    else begin
        if (in_valid) begin
            reg_mode <= in_mode;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        reg_ratio_mode <= 0;
    end
    else begin
        if (in_valid && in_mode == 2'd1) begin
            reg_ratio_mode <= in_ratio_mode;
        end
        else if(!reg_mode[0])begin
            reg_ratio_mode <= 2'd2;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt <= 0;
    end
    else begin
        case (cs)
            read_DRAM: cnt <= cnt + 1; 
            default: cnt <= 0;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wait_cnt <= 0;
    end
    else begin
        case (cs)
            idle: wait_cnt <= 0;
            wait_DRAM: wait_cnt <= (!wait_cnt[1])? wait_cnt + 1 : wait_cnt;
        endcase
    end
end

always @(posedge clk) begin
    if (in_valid) begin
        img_addr <= {img_addr_base, 8'd0};
    end
    else if (rvalid_s_inf) begin
        img_addr <= img_addr + 4;
    end
end

always @(posedge clk) begin
    if (cs == read_DRAM) begin
        case (reg_ratio_mode)
            2'd0: begin
                for (i = 0; i < 128; i = i + 8) begin
                    in_buf[(127-i)-:8] <= rdata_s_inf[(127-i)-:8] >> 2;
                end
            end
            2'd1: begin
                for (i = 0; i < 128; i = i + 8) begin
                    in_buf[(127-i)-:8] <= {1'd0, rdata_s_inf[(127-i)-:7]};
                end
            end
            2'd2: in_buf <= rdata_s_inf;
            2'd3: begin
                for (i = 0; i < 128; i = i + 8) begin
                    if (rdata_s_inf[(127-i)-:8] >= 8'd128)
                        in_buf[(127-i)-:8] <= 8'b11111111;
                    else
                        in_buf[(127-i)-:8] <= {rdata_s_inf[(126-i)-:7], 1'd0};
                end
            end
        endcase
    end
    else
        in_buf <= 0;
end

//---------------------------//
//         Min Max Avg       //
//---------------------------//
reg [7:0] min_cmp_L1 [0:7];
reg [7:0] max_cmp_L1 [0:7];
reg [7:0] min_cmp_L2 [0:3];
reg [7:0] max_cmp_L2 [0:3];
reg [7:0] min_cmp_L3 [0:1];
reg [7:0] max_cmp_L3 [0:1];
reg [7:0] min_cmp_L4;
reg [7:0] max_cmp_L4;

always @(*) begin
    for (i = 0; i < 128; i = i + 16) begin
        if (in_buf[(i+7)-:8] >= in_buf[(i+15)-:8]) begin
            max_cmp_L1[i/16] = in_buf[(i+7)-:8];
            min_cmp_L1[i/16] = in_buf[(i+15)-:8];
        end
        else begin
            max_cmp_L1[i/16] = in_buf[(i+15)-:8];
            min_cmp_L1[i/16] = in_buf[(i+7)-:8];
        end
    end
end

always @(posedge clk) begin
    for (i = 0; i < 4; i = i + 1) begin
        max_cmp_L2[i] <= (max_cmp_L1[2*i] >= max_cmp_L1[2*i+1])? max_cmp_L1[2*i] : max_cmp_L1[2*i+1];
        min_cmp_L2[i] <= (min_cmp_L1[2*i] >= min_cmp_L1[2*i+1])? min_cmp_L1[2*i+1] : min_cmp_L1[2*i];
    end
end

always @(*) begin
    for (i = 0; i < 2; i = i + 1) begin
        max_cmp_L3[i] = (max_cmp_L2[2*i] >= max_cmp_L2[2*i+1])? max_cmp_L2[2*i] : max_cmp_L2[2*i+1];
        min_cmp_L3[i] = (min_cmp_L2[2*i] >= min_cmp_L2[2*i+1])? min_cmp_L2[2*i+1] : min_cmp_L2[2*i];
    end
end

always @(posedge clk) begin
    max_cmp_L4 <= (max_cmp_L3[0] >= max_cmp_L3[1])? max_cmp_L3[0] : max_cmp_L3[1];
    min_cmp_L4 <= (min_cmp_L3[0] >= min_cmp_L3[1])? min_cmp_L3[1] : min_cmp_L3[0];
end

always @(posedge clk) begin
    if (!cnt) begin
        min[0] <= 255;
        max[0] <= 0;
    end
    else if (cnt >= 6 && cnt <= 69) begin
        max[0] <= (max[0] >= max_cmp_L4)? max[0] : max_cmp_L4;
        min[0] <= (min[0] >= min_cmp_L4)? min_cmp_L4 : min[0];
    end
end

always @(posedge clk) begin
    if (!cnt) begin
        min[1] <= 255;
        max[1] <= 0;
    end
    else if (cnt >= 70 && cnt <= 133) begin
        max[1] <= (max[1] >= max_cmp_L4)? max[1] : max_cmp_L4;
        min[1] <= (min[1] >= min_cmp_L4)? min_cmp_L4 : min[1];
    end
end

always @(posedge clk) begin
    if (!cnt) begin
        min[2] <= 255;
        max[2] <= 0;
    end
    else if (cnt >= 134 && cnt <= 197) begin
        max[2] <= (max[2] >= max_cmp_L4)? max[2] : max_cmp_L4;
        min[2] <= (min[2] >= min_cmp_L4)? min_cmp_L4 : min[2];
        // if (reg_pic_no == 7) begin
        //     $display("min value = %d", min_cmp_L4);
        // end
    end
end

reg [16:0] max_sum, min_sum;
reg [9:0] minus_temp1;
assign minus_temp1 = max_sum[16:7] - 2'd3;
always @(posedge clk) begin
    case (compute_cnt)
        'd35: max_sum <= max[0] + max[1];
        'd36: max_sum <= max_sum + max[2];  
        'd37, 'd38, 'd39, 'd40, 'd41, 'd42, 'd43, 'd44: begin
            if (minus_temp1[9]) begin
                max_sum <= max_sum << 1;
            end
            else begin
                max_sum <= {minus_temp1[8:0], max_sum[6:0], 1'd1};
            end
        end
    endcase
end

reg [9:0] minus_temp2;
assign minus_temp2 = min_sum[16:7] - 2'd3;
always @(posedge clk) begin
    case (compute_cnt)
        'd35: min_sum <= min[0] + min[1];
        'd36: begin
            min_sum <= min_sum + min[2];  
            // if (reg_pic_no == 7) begin
            //     $display("min = %d, %d, %d", min[0], min[1], min[2]);
            // end
        end
        'd37, 'd38, 'd39, 'd40, 'd41, 'd42, 'd43, 'd44: begin
            if (minus_temp2[9]) begin
                min_sum <= min_sum << 1;
            end
            else begin
                min_sum <= {minus_temp2[8:0], min_sum[6:0], 1'd1};
            end
        end
    endcase
end

reg [8:0] minmax_sum;
assign minmax_sum = max_sum[7:0] + min_sum[7:0];
always @(posedge clk) begin
    if (compute_cnt == 45) begin
        // $display("pic_no = %d", reg_pic_no);
        // $display("myans: max = %d, min = %d", max_sum[7:0], min_sum[7:0]);
        minmax_avg[reg_pic_no] <= minmax_sum[8:1];
    end
end

//---------------------------//
//         Auto Focus        //
//---------------------------//

always @(posedge clk) begin
    case (cnt[5:0])
        6'd0: begin
            if (!cnt[7:6]) begin
                for (i = 0; i < 36; i = i + 1) begin
                    focus_table[i] <= 0;
                end
            end
        end
        6'd30: begin
            focus_table[0] <= focus_table[0] + ((add_type[0])? in_buf[111:106] : in_buf[111:105]);
            focus_table[1] <= focus_table[1] + ((add_type[0])? in_buf[119:114] : in_buf[119:113]);
            focus_table[2] <= focus_table[2] + ((add_type[0])? in_buf[127:122] : in_buf[127:121]);
        end
        6'd31: begin
            focus_table[3] <= focus_table[3] + ((add_type[0])? in_buf[7:2] : in_buf[7:1]);
            focus_table[4] <= focus_table[4] + ((add_type[0])? in_buf[15:10] : in_buf[15:9]);
            focus_table[5] <= focus_table[5] + ((add_type[0])? in_buf[23:18] : in_buf[23:17]);
        end
        6'd32: begin
            focus_table[6] <= focus_table[6] + ((add_type[0])? in_buf[111:106] : in_buf[111:105]);
            focus_table[7] <= focus_table[7] + ((add_type[0])? in_buf[119:114] : in_buf[119:113]);
            focus_table[8] <= focus_table[8] + ((add_type[0])? in_buf[127:122] : in_buf[127:121]);
        end
        6'd33: begin
            focus_table[9] <= focus_table[9] + ((add_type[0])? in_buf[7:2] : in_buf[7:1]);
            focus_table[10] <= focus_table[10] + ((add_type[0])? in_buf[15:10] : in_buf[15:9]);
            focus_table[11] <= focus_table[11] + ((add_type[0])? in_buf[23:18] : in_buf[23:17]);
        end
        6'd34: begin
            focus_table[12] <= focus_table[12] + ((add_type[0])? in_buf[111:106] : in_buf[111:105]);
            focus_table[13] <= focus_table[13] + ((add_type[0])? in_buf[119:114] : in_buf[119:113]);
            focus_table[14] <= focus_table[14] + ((add_type[0])? in_buf[127:122] : in_buf[127:121]);
        end
        6'd35: begin
            focus_table[15] <= focus_table[15] + ((add_type[0])? in_buf[7:2] : in_buf[7:1]);
            focus_table[16] <= focus_table[16] + ((add_type[0])? in_buf[15:10] : in_buf[15:9]);
            focus_table[17] <= focus_table[17] + ((add_type[0])? in_buf[23:18] : in_buf[23:17]);
        end
        6'd36: begin
            focus_table[18] <= focus_table[18] + ((add_type[0])? in_buf[111:106] : in_buf[111:105]);
            focus_table[19] <= focus_table[19] + ((add_type[0])? in_buf[119:114] : in_buf[119:113]);
            focus_table[20] <= focus_table[20] + ((add_type[0])? in_buf[127:122] : in_buf[127:121]);
        end
        6'd37: begin
            focus_table[21] <= focus_table[21] + ((add_type[0])? in_buf[7:2] : in_buf[7:1]);
            focus_table[22] <= focus_table[22] + ((add_type[0])? in_buf[15:10] : in_buf[15:9]);
            focus_table[23] <= focus_table[23] + ((add_type[0])? in_buf[23:18] : in_buf[23:17]);
        end
        6'd38: begin
            focus_table[24] <= focus_table[24] + ((add_type[0])? in_buf[111:106] : in_buf[111:105]);
            focus_table[25] <= focus_table[25] + ((add_type[0])? in_buf[119:114] : in_buf[119:113]);
            focus_table[26] <= focus_table[26] + ((add_type[0])? in_buf[127:122] : in_buf[127:121]);
        end
        6'd39: begin
            focus_table[27] <= focus_table[27] + ((add_type[0])? in_buf[7:2] : in_buf[7:1]);
            focus_table[28] <= focus_table[28] + ((add_type[0])? in_buf[15:10] : in_buf[15:9]);
            focus_table[29] <= focus_table[29] + ((add_type[0])? in_buf[23:18] : in_buf[23:17]);
        end
        6'd40: begin
            focus_table[30] <= focus_table[30] + ((add_type[0])? in_buf[111:106] : in_buf[111:105]);
            focus_table[31] <= focus_table[31] + ((add_type[0])? in_buf[119:114] : in_buf[119:113]);
            focus_table[32] <= focus_table[32] + ((add_type[0])? in_buf[127:122] : in_buf[127:121]);
        end
        6'd41: begin
            focus_table[33] <= focus_table[33] + ((add_type[0])? in_buf[7:2] : in_buf[7:1]);
            focus_table[34] <= focus_table[34] + ((add_type[0])? in_buf[15:10] : in_buf[15:9]);
            focus_table[35] <= focus_table[35] + ((add_type[0])? in_buf[23:18] : in_buf[23:17]);
        end
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        min_cnt1 <= 0;
    end
    else if (cnt[5:0] >= 34) begin
        case (min_cnt1)
            6'd0: min_cnt1 <= 1;
            6'd1: min_cnt1 <= 2;
            6'd2: min_cnt1 <= 3;
            6'd3: min_cnt1 <= 4;
            6'd4: min_cnt1 <= 6;
            6'd6: min_cnt1 <= 7;
            6'd7: min_cnt1 <= 8;
            6'd8: min_cnt1 <= 9;
            6'd9: min_cnt1 <= 10;
            6'd10: min_cnt1 <= 12;
            6'd12: min_cnt1 <= 13;
            6'd13: min_cnt1 <= 14;
            6'd14: min_cnt1 <= 15;
            6'd15: min_cnt1 <= 16;
            6'd16: min_cnt1 <= 18;
            6'd18: min_cnt1 <= 19;
            6'd19: min_cnt1 <= 20;
            6'd20: min_cnt1 <= 21;
            6'd21: min_cnt1 <= 22;
            6'd22: min_cnt1 <= 24;
            6'd24: min_cnt1 <= 25;
            6'd25: min_cnt1 <= 26;
            6'd26: min_cnt1 <= 27;
            6'd27: min_cnt1 <= 28;
            6'd28: min_cnt1 <= 30;
            6'd30: min_cnt1 <= 31;
            6'd31: min_cnt1 <= 32;
            6'd32: min_cnt1 <= 33;
            6'd33: min_cnt1 <= 34;
            6'd34: min_cnt1 <= 0;
        endcase
    end
    else if (!cnt)
        min_cnt1 <= 0;
end

always @(posedge clk) begin
    if (!cnt)
        min_cnt2 <= 1;
    else if (cnt[5:0] >= 34) begin
        case (min_cnt2)
            6'd1: min_cnt2 <= 2;
            6'd2: min_cnt2 <= 3;
            6'd3: min_cnt2 <= 4;
            6'd4: min_cnt2 <= 5;
            6'd5: min_cnt2 <= 7;
            6'd7: min_cnt2 <= 8;
            6'd8: min_cnt2 <= 9;
            6'd9: min_cnt2 <= 10;
            6'd10: min_cnt2 <= 11;
            6'd11: min_cnt2 <= 13;
            6'd13: min_cnt2 <= 14;
            6'd14: min_cnt2 <= 15;
            6'd15: min_cnt2 <= 16;
            6'd16: min_cnt2 <= 17;
            6'd17: min_cnt2 <= 19;
            6'd19: min_cnt2 <= 20;
            6'd20: min_cnt2 <= 21;
            6'd21: min_cnt2 <= 22;
            6'd22: min_cnt2 <= 23;
            6'd23: min_cnt2 <= 25;
            6'd25: min_cnt2 <= 26;
            6'd26: min_cnt2 <= 27;
            6'd27: min_cnt2 <= 28;
            6'd28: min_cnt2 <= 29;
            6'd29: min_cnt2 <= 31;
            6'd31: min_cnt2 <= 32;
            6'd32: min_cnt2 <= 33;
            6'd33: min_cnt2 <= 34;
            6'd34: min_cnt2 <= 35;
            6'd35: min_cnt2 <= 1;
        endcase
    end
end

always @(posedge clk) begin
    if (cnt[5:0] >= 34) begin
        if (min_cnt3 == 29) 
            min_cnt3 <= 0;
        else
            min_cnt3 <= min_cnt3 + 1;
    end
    else if (!cnt)
        min_cnt3 <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        min_cnt4 <= 6;
    end
    else begin
        if (cnt[5:0] >= 34) begin
            if (min_cnt4 == 35) 
                min_cnt4 <= 6;
            else
                min_cnt4 <= min_cnt4 + 1;
        end
        else if (!cnt)
            min_cnt4 <= 6;
    end
end

always @(posedge clk) begin
    sub1 <= focus_table[min_cnt1];  //compute_cnt 0~29
    sub2 <= focus_table[min_cnt2];
    sub3 <= focus_table[min_cnt3];
    sub4 <= focus_table[min_cnt4];
end

always @(posedge clk) begin
    diff1 <= (sub2 >= sub1)? (sub2 - sub1) : (sub1 - sub2);       //compute_cnt 1~30
    diff2 <= (sub4 >= sub3)? (sub4 - sub3) : (sub3 - sub4);
    //diff_sum <= diff1 + diff2;       //compute_cnt 2~31
end

always @(posedge clk) begin
    if (cnt >= 162)
        compute_cnt <= compute_cnt + 1;
    else
        compute_cnt <= 0;
end

// always @(posedge clk) begin
//     if (compute_cnt[5:0] >= 3 && compute_cnt[5:0] <= 32)
//         focus1 <= focus1 + diff_sum;
//     else
//         focus1 <= 0;
// end

reg [12:0] focus1_t1, focus1_t2;

always @(posedge clk) begin
    if (compute_cnt >= 2) begin
        focus1_t1 <= focus1_t1 + diff1;
    end
    else
        focus1_t1 <= 0;
end

always @(posedge clk) begin
    if (compute_cnt >= 2) begin
        focus1_t2 <= focus1_t2 + diff2;
    end
    else
        focus1_t2 <= 0;
end

always @(posedge clk) begin
    if (compute_cnt == 32) begin
        focus1 <= focus1_t1 + focus1_t2;
    end
end

always @(posedge clk) begin
    case (compute_cnt[4:0])
        5'd0: focus2_t1 <= 0;
        5'd8, 5'd9, 5'd10,
        5'd13, 5'd14, 5'd15,
        5'd18, 5'd19, 5'd20, 
        5'd23, 5'd24, 5'd25: focus2_t1 <= focus2_t1 + diff1;
    endcase
end

always @(posedge clk) begin
    case (compute_cnt[4:0])
        5'd0: focus2_t2 <= 0;
        5'd9, 5'd10, 5'd11, 5'd12,
        5'd15, 5'd16, 5'd17, 5'd18,
        5'd21, 5'd22, 5'd23, 5'd24: focus2_t2 <= focus2_t2 + diff2;
    endcase
end

always @(posedge clk) begin
    if (compute_cnt == 26) begin
        focus2 <= focus2_t1 + focus2_t2;
    end
    else if (compute_cnt == 27) begin
        focus2 <= {4'd0, focus2[12:4]};
    end
end

always @(posedge clk) begin
    case (compute_cnt[4:0])
        5'd0: focus3_t1 <= 0;
        5'd14, 5'd19: focus3_t1 <= focus3_t1 + diff1;
    endcase
end

always @(posedge clk) begin
    case (compute_cnt[4:0])
        5'd0: focus3_t2 <= 0;
        5'd16, 5'd17: focus3_t2 <= focus3_t2 + diff2;
    endcase
end

always @(posedge clk) begin
    if (compute_cnt == 20) begin
        focus3 <= focus3_t1 + focus3_t2;
    end
    else if (compute_cnt == 21) begin
        focus3 <= {2'd0, focus3[9:2]};
    end
end

reg [19:0] dividend;
reg [8:0]  quotient;
reg [11:0] minus_temp;
assign minus_temp = dividend[19:8] - 4'd9;

always @(posedge clk) begin
    if (compute_cnt == 33) begin
        dividend <= {8'd0, focus1[13:2]};
        //quotient <= 0;
        //$display("dividend = %d", focus1[13:2]);
    end
    else begin
        if (minus_temp[11]) begin
            dividend <= dividend << 1;
            //quotient <= {quotient[7:0], 1'd0};
        end
        else begin
            dividend <= {minus_temp[10:0], dividend[7:0], 1'd1};
            //quotient <= {quotient[7:0], 1'd1};
        end
    end
end

reg [1:0] temp_index;
always @(*) begin
    if (focus3[7:0] >= focus2[8:0]) begin
        if (focus2[8:0] >= dividend[8:0]) begin
            temp_index = 2'd0;
        end
        else begin
            if (focus3[7:0] >= dividend[8:0])
                temp_index = 2'd0;
            else
                temp_index = 2'd2;
        end
    end
    else begin
        if (focus3[7:0] >= dividend[8:0]) begin
            temp_index = 2'd1;
        end
        else begin
            if (focus2[8:0] >= dividend[8:0])
                temp_index = 2'd1;
            else
                temp_index = 2'd2;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 16; i = i + 1) begin
            focus_ans[i] <= 0;
        end 
    end
    else begin
        if (compute_cnt == 43) begin
            //$display("quotient = %d", quotient);
            focus_ans[reg_pic_no] <= temp_index;
        end
    end
end

//---------------------------//
//        Auto Exposure      //
//---------------------------//

always @(posedge clk) begin
    if ((cnt >= 4 && cnt <= 67) || (cnt >= 132 && cnt <= 195))
        add_type <= 2'd1;
    else if (cnt >= 68 && cnt <= 131)
        add_type <= 2'd2;
    else
        add_type <= 0;
end

always @(posedge clk) begin
    case (add_type)
        2'd1: for (i = 0; i < 8; i = i + 1)
                add_out_L1[i] <= in_buf[(127-16*i)-:6] + in_buf[(119-16*i)-:6];
        2'd2: for (i = 0; i < 8; i = i + 1)
                add_out_L1[i] <= in_buf[(127-16*i)-:7] + in_buf[(119-16*i)-:7];
        default: for (i = 0; i < 8; i = i + 1)
                add_out_L1[i] <= 0;
    endcase
end

always @(*) begin
    for (i = 0; i < 4; i = i + 1) begin
        addA_L2[i] = add_out_L1[i*2];
        addB_L2[i] = add_out_L1[i*2+1];
    end
end

always @(posedge clk) begin
    for (i = 0; i < 4; i = i + 1) begin
        add_out_L2[i] <= addA_L2[i] + addB_L2[i];
    end
end

always @(*) begin
    for (i = 0; i < 2; i = i + 1) begin
        addA_L3[i] = add_out_L2[i*2];
        addB_L3[i] = add_out_L2[i*2+1];
    end
end

always @(posedge clk) begin
    for (i = 0; i < 2; i = i + 1) begin
        add_out_L3[i] <= addA_L3[i] + addB_L3[i];
    end
end

always @(posedge clk) begin
    add_out_L4 <= add_out_L3[0] + add_out_L3[1];
end

always @(posedge clk) begin
    if (cs == read_DRAM) begin
        exposure_temp <= exposure_temp + add_out_L4;
    end
    else if (cs == wait_DRAM) begin
        exposure_temp <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 16; i = i + 1) begin
            exposure_ans[i] <= 0;
        end
    end
    else if (cnt == 200) begin
        exposure_ans[reg_pic_no] <= exposure_temp[17:10];
    end
end

endmodule

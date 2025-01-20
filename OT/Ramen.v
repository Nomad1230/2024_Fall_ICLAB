module Ramen(
    // Input Registers
    input clk, 
    input rst_n, 
    input in_valid,
    input selling,
    input portion, 
    input [1:0] ramen_type,

    // Output Signals
    output reg out_valid_order,
    output reg success,

    output reg out_valid_tot,
    output reg [27:0] sold_num,
    output reg [14:0] total_gain
);


//==============================================//
//             Parameter and Integer            //
//==============================================//

// ramen_type
parameter TONKOTSU = 0;
parameter TONKOTSU_SOY = 1;
parameter MISO = 2;
parameter MISO_SOY = 3;

// initial ingredient
parameter NOODLE_INIT = 12000;
parameter BROTH_INIT = 41000;
parameter TONKOTSU_SOUP_INIT =  9000;
parameter MISO_INIT = 1000;
parameter SOY_SAUSE_INIT = 1500;

parameter idle = 2'd0, sell = 2'd1, finish = 2'd2;
//==============================================//
//                 reg declaration              //
//==============================================// 
reg [1:0] cs, ns;
reg valid_cnt;
reg [13:0] noodle;
reg [15:0] broth;
reg [13:0] soup;
reg [9:0] miso;
reg [10:0] soy_sause;
reg [1:0] _ramen_type;
reg [13:0] subA0, subout0; 
reg [7:0] subB0;
reg [15:0] subA1, subout1;
reg [9:0] subB1;
reg [13:0] subA2, subout2;
reg [7:0] subB2;
reg [9:0] subA3, subout3;
reg [5:0] subB3;
reg [10:0] subA4, subout4;
reg [5:0] subB4;
//==============================================//
//                    Design                    //
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cs <= idle;
    end
    else
        cs <= ns;    
end

always @(*) begin
    case (cs)
        idle: ns = (selling)? sell : idle;
        sell: ns = (!selling)? finish : sell;
        finish: ns = idle;
        default: ns = idle;
    endcase
end

always @(*) begin
    subA0 = noodle;
    subB0 = (portion)? 8'd150 : 8'd100;
    subout0 = subA0 - subB0;
end

always @(*) begin
    subA1 = broth;
    case ({_ramen_type, portion})
        3'd0: subB1 = 10'd300;
        3'd1: subB1 = 10'd500;
        3'd2: subB1 = 10'd300;
        3'd3: subB1 = 10'd500;
        3'd4: subB1 = 10'd400;
        3'd5: subB1 = 10'd650;
        3'd6: subB1 = 10'd300;
        3'd7: subB1 = 10'd500;
        default: subB1 = 0;
    endcase
    subout1 = subA1 - subB1;
end

always @(*) begin
    subA2 = soup;
    case ({_ramen_type, portion})
        3'd0: subB2 = 8'd150;
        3'd1: subB2 = 8'd200;
        3'd2: subB2 = 8'd100;
        3'd3: subB2 = 8'd150;
        3'd4: subB2 = 8'd0;
        3'd5: subB2 = 8'd0;
        3'd6: subB2 = 8'd70;
        3'd7: subB2 = 8'd100;
        default: subB2 = 0;
    endcase
    subout2 = subA2 - subB2;
end

always @(*) begin
    subA3 = miso;
    case ({_ramen_type, portion})
        3'd0: subB3 = 6'd0;
        3'd1: subB3 = 6'd0;
        3'd2: subB3 = 6'd0;
        3'd3: subB3 = 6'd0;
        3'd4: subB3 = 6'd30;
        3'd5: subB3 = 6'd50;
        3'd6: subB3 = 6'd15;
        3'd7: subB3 = 6'd25;
        default: subB3 = 0;
    endcase
    subout3 = subA3 - subB3;
end

always @(*) begin
    subA4 = soy_sause;
    case ({_ramen_type, portion})
        3'd0: subB4 = 6'd0;
        3'd1: subB4 = 6'd0;
        3'd2: subB4 = 6'd30;
        3'd3: subB4 = 6'd50;
        3'd4: subB4 = 6'd0;
        3'd5: subB4 = 6'd0;
        3'd6: subB4 = 6'd15;
        3'd7: subB4 = 6'd25;
        default: subB4 = 0;
    endcase
    subout4 = subA4 - subB4;
end
reg finish_flag;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid_order <= 1'd0;
        success <= 1'd0;
        out_valid_tot <= 1'd0;
        sold_num <= 28'd0;
        total_gain <= 15'd0;

        noodle <= 14'd12000;
        broth <= 16'd41000;
        soup <= 14'd9000;
        miso <= 10'd1000;
        soy_sause <= 11'd1500;
        valid_cnt <= 1'd0;
        finish_flag <= 1'd0;
    end
    else begin
        case (cs)
            idle, sell: begin
                if(finish_flag) begin
                    finish_flag <= 1'd0;
                    out_valid_order <= 1'd0;
                    out_valid_tot <= 1'd0;
                    total_gain <= 15'd0;
                    sold_num <= 28'd0;
                end
                if(in_valid) begin
                    valid_cnt <= ~valid_cnt;
                    if (!valid_cnt) begin
                        out_valid_order <= 1'd0;
                        success <= 1'd0;
                        _ramen_type <= ramen_type;
                    end
                    else begin
                        if (noodle < subout0 || broth < subout1 || soup < subout2 || miso < subout3 || soy_sause < subout4) begin
                            out_valid_order <= 1'd1;
                            success <= 1'd0;
                        end
                        else begin
                            out_valid_order <= 1'd1;
                            success <= 1'd1;
                            noodle <= subout0;
                            broth <= subout1;
                            soup <= subout2;
                            miso <= subout3;
                            soy_sause <= subout4;
                            case (_ramen_type)
                                2'd0: sold_num[27:21] <= sold_num[27:21] + 1;
                                2'd1: sold_num[20:14] <= sold_num[20:14] + 1;
                                2'd2: sold_num[13:7] <= sold_num[13:7] + 1;
                                2'd3: sold_num[6:0] <= sold_num[6:0] + 1;
                                default: sold_num <= sold_num;
                            endcase
                        end
                    end
                end
                else begin
                    out_valid_order <= 1'd0;
                    success <= 1'd0;
                end
            end
            finish: begin
                out_valid_tot <= 1'd1;
                total_gain <= sold_num[27:21] * 8'd200 + sold_num[20:14] * 8'd250 + sold_num[13:7] * 8'd200 + sold_num[6:0] * 8'd250;
                noodle <= 14'd12000;
                broth <= 16'd41000;
                soup <= 14'd9000;
                miso <= 10'd1000;
                soy_sause <= 11'd1500;
                valid_cnt <= 1'd0;
                finish_flag <= 1'd1;
            end
            default: out_valid_tot <= 1'd0;
        endcase
    end
end




endmodule

// module check_sell (
//     input [1:0] ramen_type,
//     input portion,
//     input [13:0] orig_noodle,
//     input [15:0] orig_broth,
//     input [13:0] orig_soup,
//     input [9:0] orig_miso,
//     input [10:0] orig_soy_sause,
//     output reg success,
//     output reg [13:0] noodle,
//     output reg [15:0] broth,
//     output reg [13:0] soup,
//     output reg [9:0] miso,
//     output reg [10:0] soy_sause,
// );
    
// endmodule
/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

/**
 * This section contains the definition of the class and the instantiation of the object.
 *  * 
 * The always_ff blocks update the object based on the values of valid signals.
 * When valid signal is true, the corresponding property is updated with the value of inf.D
 */

class Formula_and_mode;
    Formula_Type f_type;
    Mode f_mode;
endclass

Formula_and_mode fm_info = new();

logic [1:0]  act_change;
logic [1:0]  warn_msg;
logic [11:0] index_change;
logic [1:0]  current_act;

always_ff @(posedge clk)
    current_act <= (inf.sel_action_valid)? inf.D.d_act[0] : current_act;

always_comb begin
    if (inf.sel_action_valid) begin
        act_change = inf.D.d_act[0];
    end
    
    if (inf.formula_valid) begin
        fm_info.f_type = inf.D.d_formula[0];
    end
    
    if (inf.mode_valid) begin
        fm_info.f_mode = inf.D.d_mode[0];
    end
    
    if (inf.out_valid) begin
        warn_msg = inf.warn_msg;
    end

    if (inf.index_valid && current_act == Update) begin
        index_change = inf.D.d_index;
    end
end

// 1. Each case of Formula_Type should be select at least 150 times.
covergroup Spec1 @(posedge clk iff (inf.formula_valid));
    option.per_instance = 1;
    option.at_least = 150;
    btype:coverpoint fm_info.f_type{
        bins b_f_type [] = {[ Formula_A : Formula_H ]};
    }
endgroup

// 2. Each case of Mode should be select at least 150 times. 
covergroup Spec2 @(posedge clk iff (inf.mode_valid));
    option.per_instance = 1;
    option.at_least = 150;
    bmode:coverpoint fm_info.f_mode{
        bins b_f_mode [] = { Insensitive, Normal, Sensitive };
    }
endgroup

/*
3.	Create a cross bin for the SPEC1 and SPEC2. Each combination should be selected at least 150 
times. (Formula_A,B,C,D,E,F,G,H) x (Insensitive, Normal, Sensitive) 
*/
covergroup Spec3 @(posedge clk iff (inf.out_valid  &&  act_change == 0) );
    option.per_instance = 1;
    option.at_least = 150;
    bcross:cross   fm_info.f_type , fm_info.f_mode;
endgroup

/*
4. Output signal inf.warn_msg should be “No_Warn”, “Date_Warn”, “Data_Warn“,”Risk_Warn, 
each at least 50 times. (Sample the value when inf.out_valid is high)
*/
covergroup Spec4 @(posedge clk iff (inf.out_valid));
    option.per_instance = 1;
    option.at_least = 50;
    warnmsg:coverpoint warn_msg{
        bins warn_msg_array [] = { [ 0 : 3 ]};
    }
endgroup

/*
5. Create the transitions bin for the inf.D.act[0] signal from [Index_Check:Check_Valid_Date] to 
[Index_Check:Check_Valid_Date]. Each transition should be hit at least 300 times. (sample the 
value at posedge clk iff inf.sel_action_valid) 
*/
covergroup Spec5 @(posedge clk iff(inf.sel_action_valid));
    option.per_instance = 1;
    option.at_least = 300;
    trans:coverpoint act_change{
        bins array1 [] = ( 0  => 0);
        bins array2 [] = ( 0  => 1);
        bins array3 [] = ( 0  => 2);
        bins array4 [] = ( 1  => 0);
        bins array5 [] = ( 1  => 1);
        bins array6 [] = ( 1  => 2);
        bins array7 [] = ( 2  => 0);
        bins array8 [] = ( 2  => 1);
        bins array9 [] = ( 2  => 2);
    }
endgroup

/*
6. Create a covergroup for variation of Update action with auto_bin_max = 32, and each bin have to 
hit at least one time. 
*/
covergroup Spec6 @(posedge clk);
    option.per_instance = 1;
    option.at_least = 1;
    updt:coverpoint index_change{
        option.auto_bin_max = 32;
    }
endgroup

Spec1 spec1_inst = new();
Spec2 spec2_inst = new();
Spec3 spec3_inst = new();
Spec4 spec4_inst = new();
Spec5 spec5_inst = new();
Spec6 spec6_inst = new();

// Assertion

SPEC1:
    assert property (
        @(posedge inf.rst_n)
            (inf.rst_n==1'b0) |-> 
            (inf.out_valid == 0 &&
             inf.warn_msg  == 0 &&
             inf.complete  == 0 &&
             inf.AR_VALID == 0 &&
             inf.AR_ADDR == 0 &&
             inf.R_READY == 0 &&
             inf.AW_VALID == 0 &&
             inf.AW_ADDR == 0 &&
             inf.W_VALID == 0 &&
             inf.W_DATA == 0 &&
             inf.B_READY == 0)
    )
    else begin
        $display("*************************************************************************");
        $display("*                    Assertion 1 is violated                            *");
        $display("*************************************************************************");
        $fatal;
    end

logic [1:0] valid_cnt;
always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        valid_cnt <= 0;
    else begin
        if (inf.index_valid) begin
            valid_cnt <= valid_cnt + 1;
        end 
    end
end

property Index_Check_delay;
        @(posedge clk)
            ((current_act==Index_Check && (valid_cnt == 3 && inf.index_valid)) |-> ##[1:1000] (inf.out_valid===1));
endproperty
property Update_delay;
        @(posedge clk)
            ((current_act==Update && (valid_cnt == 3 && inf.index_valid)) |-> ##[1:1000] (inf.out_valid===1));
endproperty
property Check_Valid_Date_delay;
        @(posedge clk)
            ((current_act==Check_Valid_Date && inf.data_no_valid)  |-> ##[1:1000] inf.out_valid===1);
endproperty

SPEC2:
    assert property (
        Index_Check_delay and Update_delay and Check_Valid_Date_delay
    )
    else begin
        $display("*************************************************************************");
        $display("*                    Assertion 2 is violated                            *");
        $display("*************************************************************************");
        $fatal;
    end

SPEC3:
    assert property (
        @(negedge clk ) inf.complete |-> !inf.warn_msg
    )
    else begin
        $display("*************************************************************************");
        $display("*                    Assertion 3 is violated                            *");
        $display("*************************************************************************");
        $fatal;
    end

property Index_Check_valid ; 
   @(negedge clk ) (inf.sel_action_valid === 1 ##[1:4] inf.formula_valid === 1 ##[1:4] inf.mode_valid === 1  ##[1:4] inf.date_valid === 1 ##[1:4] inf.data_no_valid === 1
                    ##[1:4] inf.index_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid );        
endproperty

property Update_valid ; 
   @(negedge clk ) (inf.sel_action_valid === 1 ##[1:4] inf.date_valid === 1 ##[1:4] inf.data_no_valid === 1
                    ##[1:4] inf.index_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid );        
endproperty

property Check_Valid_Date_valid ; 
   @(negedge clk ) (inf.sel_action_valid === 1 ##[1:4] inf.date_valid === 1 ##[1:4] inf.data_no_valid === 1 );        
endproperty

always@(negedge clk) begin
    if(inf.sel_action_valid === 1)begin
        case(inf.D.d_act[0])
        Index_Check:begin
            SPEC4_1 : assert property (Index_Check_valid)
                else begin
                    $display("*************************************************************************");
                    $display("*                    Assertion 4 is violated                            *");
                    $display("*************************************************************************");
                    $fatal;
                end
        end
        Update:begin
            SPEC4_2 : assert property (Update_valid)
                else begin
                    $display("*************************************************************************");
                    $display("*                    Assertion 4 is violated                            *");
                    $display("*************************************************************************");
                    $fatal;
                end
        end
        Check_Valid_Date:begin
            SPEC4_3 : assert property (Check_Valid_Date_valid)
                else begin
                    $display("*************************************************************************");
                    $display("*                    Assertion 4 is violated                            *");
                    $display("*************************************************************************");
                    $fatal;
                end
        end
        endcase    
    end
end

logic[5:0] Valid ;
always@(negedge clk)begin
    Valid[0] = inf.sel_action_valid ;
    Valid[1] = inf.formula_valid;
    Valid[2] = inf.mode_valid;
    Valid[3] = inf.date_valid;
    Valid[4] = inf.data_no_valid;
    Valid[5] = inf.index_valid; 
    if(Valid[0] || Valid[1] || Valid[2] || Valid[3] || Valid[4] || Valid[5])begin
        SPEC5 : assert ($onehot(Valid))
                else begin
                    $display("*************************************************************************");
                    $display("*                    Assertion 5 is violated                            *");
                    $display("*************************************************************************");
                    $fatal;
                end
    end        
end

SPEC6 : assert property (@(negedge clk ) inf.out_valid |=> !inf.out_valid)
        else begin
            $display("*************************************************************************");
            $display("*                    Assertion 6 is violated                            *");
            $display("*************************************************************************");
            $fatal;
        end

SPEC7 : assert property (@(negedge clk) inf.out_valid |-> ##[2:5] inf.sel_action_valid)
        else begin
            $display("*************************************************************************");
            $display("*                    Assertion 7 is violated                            *");
            $display("*************************************************************************");
            $fatal;
        end

logic [3:0] Month ;
logic [4:0] Day   ;
logic wrong;
always@(negedge clk )begin
    if(inf.date_valid === 1)begin
        { Month , Day } = inf.D.d_date[0] ;

        wrong = 1;
        case(Month)
            2:begin
                if( Day < 1 || Day > 28)
                    wrong = 0;
            end
            1,3,5,7,8,10,12:begin
                if( Day < 1 || Day > 31)       
                    wrong = 0;
            end
            4,6,9,11:begin
                if( Day < 1 || Day > 30)       
                    wrong = 0;
            end
            default : wrong = 0; 
        endcase
        SPEC8 : assert  (wrong)
                else begin
                    $display("*************************************************************************");
                    $display("*                    Assertion 8 is violated                            *");
                    $display("*************************************************************************");
                    $fatal;
                end
        end       
end

//SPEC9 : assert property (@(negedge clk) inf.AR_VALID ##[1:$] inf.AW_VALID)
SPEC9 : assert property ( @(negedge clk) !(inf.AR_VALID === 1 && inf.AW_VALID === 1) )
        else begin
            $display("*************************************************************************");
            $display("*                    Assertion 9 is violated                            *");
            $display("*************************************************************************");
            $fatal;
        end

endmodule
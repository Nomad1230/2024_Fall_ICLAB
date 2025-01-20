
// `include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter MAX_CYCLE=1000;

integer   TOTAL_PATNUM = 6600;
integer   SEED = 45456;
string reset_color       = "\033[1;0m";
string txt_black_prefix  = "\033[1;30m";
string txt_red_prefix    = "\033[1;31m";
string txt_green_prefix  = "\033[1;32m";
string txt_yellow_prefix = "\033[1;33m";
string txt_blue_prefix   = "\033[1;34m";
integer pat;
integer latency;
integer i,j,t;

//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  // 32 box

logic [1:0] warn_msg;
logic       complete;
logic [2:0] formula_type_tmp;
logic [1:0] mode_tmp;
logic [8:0] today_date;
logic [7:0] data_no_tmp;
logic [11:0] indexA_tmp, indexB_tmp, indexC_tmp, indexD_tmp;
Action inputAction;

logic [11:0] threshold;
logic [11:0] dram_indexA, dram_indexB, dram_indexC, dram_indexD;
logic [3:0]  dram_M;
logic [4:0]  dram_D;
logic [16:0] baseAddress;
logic [13:0] result;
logic [11:0] sortA, sortB, sortC, sortD;
logic [11:0] gA, gB, gC, gD;
logic [12:0] sign_sumA, sign_sumB, sign_sumC, sign_sumD;
logic [1:0]  valid_cnt;

//================================================================
// class random
//================================================================

/**
 * Class representing a random action.
 */
assert_rst:
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
        $display("Output signal should be 0 at %-12d ps  ", $time*1000);
        repeat(5) @(negedge clk);
        $fatal;
    end

assert_out_valid:
    assert property (
        @(posedge clk)
            inf.out_valid |-> ##1 inf.out_valid === 0
    )
    else
    begin
        $display("out_valid is high for more than one cycle at %-12d ps  ", $time*1000);
        repeat(5) @(negedge clk);
        $fatal; 
    end

assert_out_valid_not_overlap:
    assert property (
        @(posedge clk)
            (inf.sel_action_valid || inf.formula_valid || inf.mode_valid || 
            inf.date_valid || inf.data_no_valid || inf.index_valid) |-> inf.out_valid === 0
    )
    else
    begin
        $display("Out valid can't be overlapped with input valid at %-12d ps", $time*1000);
        repeat(5) @(negedge clk);
        $fatal; 
    end

class random_act;
    function new(int seed);
        this.srandom(seed);
    endfunction
    randc Action act_id;
    constraint range{
        act_id inside{Index_Check, Update, Check_Valid_Date};
    }
endclass

class random_formula_type;
    function new(int seed);
        this.srandom(seed);
    endfunction
    randc Formula_Type formula_type;
    constraint range{
        formula_type inside{[0:7]};
    }
endclass

class random_mode;
    function new(int seed);
        this.srandom(seed);
    endfunction
    randc Mode mode_rand;
    constraint range{
        mode_rand inside{Insensitive, Normal, Sensitive};
        // mode_rand inside{[0:3]};
    }
endclass

class random_index;
    function new(int seed);
        this.srandom(seed);
    endfunction
    randc Index indexA;
    randc Index indexB;
    randc Index indexC;
    randc Index indexD;
    constraint range{
        indexA inside{[0:4095]};
        indexB inside{[0:4095]};
        indexC inside{[0:4095]};
        indexD inside{[0:4095]};
    }
endclass

class random_date;
    function new(int seed);
        this.srandom(seed);
    endfunction
    randc Date Date;
    constraint range{
        Date.M inside{ [1:12]};
        if (Date.M == 2) {
            Date.D inside {[1:28]};
        } else if (Date.M == 4 || Date.M == 6 || Date.M == 9 || Date.M == 11) {
            Date.D inside {[1:30]};
        }else{
            Date.D inside {[1:31]};
        }
    }
endclass

class random_data_no;
    function new(int seed);
        this.srandom(seed);
    endfunction
    randc Data_No data_no;
    constraint range{
        data_no inside{[0:255]};
    }
endclass

random_act   r_action = new(SEED);
random_formula_type  r_formula_type = new(SEED);
random_mode  r_mode = new(SEED);
random_index   r_index = new(SEED);
random_date  r_date = new(SEED);
random_data_no  r_data_no = new(SEED);

initial $readmemh(DRAM_p_r, golden_DRAM);

initial begin
    reset_task;
    #10;
    for (pat=0 ; pat<TOTAL_PATNUM ; pat=pat+1) begin
        input_task;
        wait_out_valid_task;
        check_ans_task;
        $display("%0sPASS PATTERN NO.%4d %0sCycles: %3d%0s",txt_blue_prefix, pat, txt_green_prefix, latency, reset_color);
    end

    YOU_PASS_task;
end

logic [1:0] check_cnt;

task reset_task; begin
    inf.rst_n = 1;
    inf.sel_action_valid = 0;
    inf.formula_valid = 0;
    inf.mode_valid = 0;
    inf.date_valid = 0;
    inf.data_no_valid = 0;
    inf.index_valid = 0;
    inf.D = 'dx;

    mode_tmp = 0;
    formula_type_tmp = 0;
    check_cnt = 0;
    #(10) inf.rst_n = 0;
    #(10) inf.rst_n = 1;
end endtask

task input_task; begin
    @(negedge clk);
    r_action.randomize();
    r_formula_type.randomize();
    r_mode.randomize();
    r_index.randomize();
    r_date.randomize();
    r_data_no.randomize();
    if (pat > 6400)
        inputAction = 2;
    else if (pat > 6150)
        inputAction = 1;
    else if (pat > 3000)
        inputAction = 0;
    else
        inputAction = r_action.act_id;
    inf.D = 'dx;
    inf.D.d_act[0] = inputAction;
    inf.sel_action_valid = 1;
    @(negedge clk);
    inf.sel_action_valid = 1'b0;
    inf.D.d_act[0] = 'dX;

    @(negedge clk);
    valid_cnt = 0;
    case (inputAction)
        Index_Check: begin
            inf.formula_valid = 1;
            formula_type_tmp = r_formula_type.formula_type;
            inf.D.d_formula[0] = formula_type_tmp;
            @(negedge clk);
            inf.formula_valid = 0;
            inf.D.d_formula[0] = 'dx;
            @(negedge clk);
            inf.mode_valid = 1;
            // mode_tmp = r_mode.mode_rand;
            case (mode_tmp)
                0: mode_tmp = 1;
                1: mode_tmp = 3;
                3: mode_tmp = 0; 
            endcase
            inf.D.d_mode[0] = mode_tmp;
            @(negedge clk);
            inf.mode_valid = 0;
            inf.D.d_mode[0] = 'dx;
            @(negedge clk);
            inf.date_valid = 1;
            today_date = r_date.Date;
            inf.D.d_date[0] = today_date;
            @(negedge clk);
            inf.date_valid = 0;
            inf.D.d_date[0] = 'dx;
            @(negedge clk);
            inf.data_no_valid = 1;
            data_no_tmp = r_data_no.data_no;
            inf.D.d_data_no[0] = data_no_tmp;
            @(negedge clk);
            inf.data_no_valid = 0;
            inf.D.d_data_no[0] = 'dx;
            @(negedge clk);
            valid_cnt = valid_cnt + 1;
            inf.index_valid = 1;
            indexA_tmp = r_index.indexA;
            inf.D.d_index[0] = indexA_tmp;
            @(negedge clk);
            inf.index_valid = 0;
            inf.D.d_index[0] = 'dx;
            @(negedge clk);
            valid_cnt = valid_cnt + 1;
            inf.index_valid = 1;
            indexB_tmp = r_index.indexB;
            inf.D.d_index[0] = indexB_tmp;
            @(negedge clk);
            inf.index_valid = 0;
            inf.D.d_index[0] = 'dx;
            @(negedge clk);
            valid_cnt = valid_cnt + 1;
            inf.index_valid = 1;
            indexC_tmp = r_index.indexC;
            inf.D.d_index[0] = indexC_tmp;
            @(negedge clk);
            inf.index_valid = 0;
            inf.D.d_index[0] = 'dx;
            @(negedge clk);
            valid_cnt = valid_cnt + 1;
            inf.index_valid = 1;
            indexD_tmp = r_index.indexD;
            inf.D.d_index[0] = indexD_tmp;
            @(negedge clk);
            inf.index_valid = 0;
            inf.D.d_index[0] = 'dx;
            check_cnt = check_cnt + 1;
        end
        Update: begin
            inf.date_valid = 1;
            today_date = r_date.Date;
            inf.D.d_date[0] = today_date;
            @(negedge clk);
            inf.date_valid = 0;
            inf.D.d_date[0] = 'dx;
            @(negedge clk);
            inf.data_no_valid = 1;
            data_no_tmp = r_data_no.data_no;
            inf.D.d_data_no[0] = data_no_tmp;
            @(negedge clk);
            inf.data_no_valid = 0;
            inf.D.d_data_no[0] = 'dx;
            @(negedge clk);
            valid_cnt = valid_cnt + 1;
            inf.index_valid = 1;
            indexA_tmp = r_index.indexA;
            inf.D.d_index[0] = indexA_tmp;
            @(negedge clk);
            inf.index_valid = 0;
            inf.D.d_index[0] = 'dx;
            @(negedge clk);
            valid_cnt = valid_cnt + 1;
            inf.index_valid = 1;
            indexB_tmp = r_index.indexB;
            inf.D.d_index[0] = indexB_tmp;
            @(negedge clk);
            inf.index_valid = 0;
            inf.D.d_index[0] = 'dx;
            @(negedge clk);
            valid_cnt = valid_cnt + 1;
            inf.index_valid = 1;
            indexC_tmp = r_index.indexC;
            inf.D.d_index[0] = indexC_tmp;
            @(negedge clk);
            inf.index_valid = 0;
            inf.D.d_index[0] = 'dx;
            @(negedge clk);
            valid_cnt = valid_cnt + 1;
            inf.index_valid = 1;
            indexD_tmp = r_index.indexD;
            inf.D.d_index[0] = indexD_tmp;
            @(negedge clk);
            inf.index_valid = 0;
            inf.D.d_index[0] = 'dx;
        end
        Check_Valid_Date: begin
            inf.date_valid = 1;
            today_date = r_date.Date;
            inf.D.d_date[0] = today_date;
            @(negedge clk);
            inf.date_valid = 0;
            inf.D.d_date[0] = 'dx;
            @(negedge clk);
            inf.data_no_valid = 1;
            data_no_tmp = r_data_no.data_no;
            inf.D.d_data_no[0] = data_no_tmp;
            @(negedge clk);
            inf.data_no_valid = 0;
            inf.D.d_data_no[0] = 'dx;
        end
    endcase
    pre_compute;
    case (inputAction)
        Index_Check: index_check_gold_task;
        Update: update_gold_task;
        Check_Valid_Date: check_valid_date_gold_task;
    endcase
end endtask

task wait_out_valid_task;
    begin
        latency = 1;
        while (inf.out_valid!== 1'b1) begin
            if(latency == 1000) begin
                $display("*                           over 1000 cycles                            *");
                YOU_FAIL_task;
            end
            latency = latency + 1;
            @(negedge clk);
        end
    end
endtask

task check_ans_task;
    begin
        if(inf.out_valid === 1) begin       
            if(inf.warn_msg !== warn_msg || inf.complete != complete) begin 
                // $display("Action is %d", inputAction);
                // if (!inputAction) begin
                //     $display("formula_type = %d, mode = %d", formula_type_tmp, mode_tmp);
                //     $display("data_no = %d", data_no_tmp);
                //     $display("today index = %d, %d, %d, %d", indexA_tmp, indexB_tmp, indexC_tmp, indexD_tmp);
                //     $display("dram_index = %d, %d, %d, %d", dram_indexA, dram_indexB, dram_indexC, dram_indexD);
                //     $display("g_index = %d, %d, %d, %d", gA, gB, gC, gD);
                //     $display("error: result = %d", result);
                //     $display("threshold = %d", threshold);
                // end
                $display("True warn_msg is : %d",warn_msg);
                $display("your answer is : %d",inf.warn_msg);
                YOU_FAIL_task;
            end
            @(negedge clk);
        end
    end
endtask

task threshold_task; begin
    case ({formula_type_tmp, mode_tmp})
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
end endtask

task pre_compute; begin
    threshold_task;
    baseAddress = 65536+8*data_no_tmp;
    dram_indexA = {golden_DRAM[baseAddress+7], golden_DRAM[baseAddress+6][7:4]};
    dram_indexB = {golden_DRAM[baseAddress+6][3:0], golden_DRAM[baseAddress+5]};
    dram_indexC = {golden_DRAM[baseAddress+3], golden_DRAM[baseAddress+2][7:4]};
    dram_indexD = {golden_DRAM[baseAddress+2][3:0], golden_DRAM[baseAddress+1]};
    dram_M = golden_DRAM[baseAddress+4][3:0];
    dram_D = golden_DRAM[baseAddress][4:0];

    gA = (dram_indexA >= indexA_tmp)? dram_indexA - indexA_tmp : indexA_tmp - dram_indexA;
    gB = (dram_indexB >= indexB_tmp)? dram_indexB - indexB_tmp : indexB_tmp - dram_indexB;
    gC = (dram_indexC >= indexC_tmp)? dram_indexC - indexC_tmp : indexC_tmp - dram_indexC;
    gD = (dram_indexD >= indexD_tmp)? dram_indexD - indexD_tmp : indexD_tmp - dram_indexD;
end endtask

task index_check_gold_task;
    begin
        if ((today_date[8:5] < dram_M) || ((today_date[8:5] == dram_M) && (today_date[4:0] < dram_D))) begin
            complete = 0;
            warn_msg = Date_Warn;
        end
        else begin
            case (formula_type_tmp)
                Formula_A: begin
                    result = (dram_indexA + dram_indexB + dram_indexC + dram_indexD) / 4;
                end
                Formula_B: begin
                    {sortA, sortB} = (dram_indexA >= dram_indexB)? {dram_indexA, dram_indexB} : {dram_indexB, dram_indexA};
                    {sortC, sortD} = (dram_indexC >= dram_indexD)? {dram_indexC, dram_indexD} : {dram_indexD, dram_indexC};
                    {sortA, sortC} = (sortA >= sortC)? {sortA, sortC} : {sortC, sortA};
                    {sortB, sortD} = (sortB >= sortD)? {sortB, sortD} : {sortD, sortB};
                    result = sortA - sortD;
                end
                Formula_C: begin
                    {sortA, sortB} = (dram_indexA >= dram_indexB)? {dram_indexA, dram_indexB} : {dram_indexB, dram_indexA};
                    {sortC, sortD} = (dram_indexC >= dram_indexD)? {dram_indexC, dram_indexD} : {dram_indexD, dram_indexC};
                    {sortA, sortC} = (sortA >= sortC)? {sortA, sortC} : {sortC, sortA};
                    {sortB, sortD} = (sortB >= sortD)? {sortB, sortD} : {sortD, sortB};
                    result = sortD;
                end
                Formula_D: begin
                    result = (dram_indexA >= 2047) + (dram_indexB >= 2047) + (dram_indexC >= 2047) + (dram_indexD >= 2047);
                end
                Formula_E: begin
                    result = (dram_indexA >= indexA_tmp) + (dram_indexB >= indexB_tmp) + (dram_indexC >= indexC_tmp) + (dram_indexD >= indexD_tmp);
                end
                Formula_F: begin
                    {sortA, sortB} = (gA >= gB)? {gA, gB} : {gB, gA};
                    {sortC, sortD} = (gC >= gD)? {gC, gD} : {gD, gC};
                    {sortA, sortC} = (sortA >= sortC)? {sortA, sortC} : {sortC, sortA};
                    {sortB, sortD} = (sortB >= sortD)? {sortB, sortD} : {sortD, sortB};
                    result = sortB + sortC + sortD;
                end
                Formula_G: begin
                    {sortA, sortB} = (gA >= gB)? {gA, gB} : {gB, gA};
                    {sortC, sortD} = (gC >= gD)? {gC, gD} : {gD, gC};
                    {sortA, sortC} = (sortA >= sortC)? {sortA, sortC} : {sortC, sortA};
                    {sortB, sortD} = (sortB >= sortD)? {sortB, sortD} : {sortD, sortB};
                    result = sortD / 2 + sortC / 4 + sortB / 4;
                end
                Formula_H: begin
                    result = (gA + gB + gC + gD) / 4;
                end
            endcase
            if (result >= threshold) begin
                complete = 0;
                warn_msg = Risk_Warn;
            end
            else begin
                complete = 1;
                warn_msg = No_Warn;
            end
        end
    end
endtask 

task signsum; begin
    sign_sumA = dram_indexA + {indexA_tmp[11], indexA_tmp};
    sign_sumB = dram_indexB + {indexB_tmp[11], indexB_tmp};
    sign_sumC = dram_indexC + {indexC_tmp[11], indexC_tmp};
    sign_sumD = dram_indexD + {indexD_tmp[11], indexD_tmp};
end endtask

task update_gold_task;
    begin
        signsum;
        case (sign_sumA[12:11])
            2'b10: {golden_DRAM[baseAddress+7], golden_DRAM[baseAddress+6][7:4]} = 4095;
            2'b11: {golden_DRAM[baseAddress+7], golden_DRAM[baseAddress+6][7:4]} = 0;
            default: {golden_DRAM[baseAddress+7], golden_DRAM[baseAddress+6][7:4]} = sign_sumA[11:0];
        endcase
        case (sign_sumB[12:11])
            2'b10: {golden_DRAM[baseAddress+6][3:0], golden_DRAM[baseAddress+5]} = 4095;
            2'b11: {golden_DRAM[baseAddress+6][3:0], golden_DRAM[baseAddress+5]} = 0;
            default: {golden_DRAM[baseAddress+6][3:0], golden_DRAM[baseAddress+5]} = sign_sumB[11:0];
        endcase
        case (sign_sumC[12:11])
            2'b10: {golden_DRAM[baseAddress+3], golden_DRAM[baseAddress+2][7:4]} = 4095;
            2'b11: {golden_DRAM[baseAddress+3], golden_DRAM[baseAddress+2][7:4]} = 0;
            default: {golden_DRAM[baseAddress+3], golden_DRAM[baseAddress+2][7:4]} = sign_sumC[11:0];
        endcase
        case (sign_sumD[12:11])
            2'b10: {golden_DRAM[baseAddress+2][3:0], golden_DRAM[baseAddress+1]} <= 4095;
            2'b11: {golden_DRAM[baseAddress+2][3:0], golden_DRAM[baseAddress+1]} <= 0;
            default: {golden_DRAM[baseAddress+2][3:0], golden_DRAM[baseAddress+1]} <= sign_sumD[11:0];
        endcase
        golden_DRAM[baseAddress+4] = today_date[8:5];
        golden_DRAM[baseAddress] = today_date[4:0];
        {warn_msg, complete} = (sign_sumA[12] || sign_sumB[12] || sign_sumC[12] || sign_sumD[12])? 3'd6 : 3'd1;
    end
endtask 

task check_valid_date_gold_task;
    begin
        if ((today_date[8:5] < dram_M) || ((today_date[8:5] == dram_M) && (today_date[4:0] < dram_D))) begin
            complete = 0;
            warn_msg = Date_Warn;
        end
        else begin
            complete = 1;
            warn_msg = No_Warn;
        end
    end
endtask 

task YOU_PASS_task;
    begin
        $display("*************************************************************************");
        $display("*                         Congratulations                               *");
        $display("*************************************************************************");
        $finish;
    end
endtask

task YOU_FAIL_task;
    begin
        $display("*************************************************************************");
        $display("*                             Wrong Answer                              *");
        $display("*************************************************************************");
        $finish;
    end
endtask

endprogram

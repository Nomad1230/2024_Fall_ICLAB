/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: PATTERN
// FILE NAME: PATTERN.v
// VERSRION: 1.0
// DATE: August 15, 2024
// AUTHOR: Yu-Hsuan Hsu, NYCU IEE
// DESCRIPTION: ICLAB2024FALL / LAB3 / PATTERN
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

`ifdef RTL
    `define CYCLE_TIME 40
`endif
`ifdef GATE
    `define CYCLE_TIME 4.7
`endif

module PATTERN(
	//OUTPUT
	rst_n,
	clk,
	in_valid,
	tetrominoes,
	position,
	//INPUT
	tetris_valid,
	score_valid,
	fail,
	score,
	tetris
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output reg			rst_n, clk, in_valid;
output reg	[2:0]	tetrominoes;
output reg  [2:0]	position;
input 				tetris_valid, score_valid, fail;
input 		[3:0]	score;
input		[71:0]	tetris;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
integer total_latency, latency;
integer i_pat, PAT_NUM;
integer pat_fd;
integer a, i, t;
integer shape_tmp0, shape_tmp1, shape_tmp2, shape_tmp3;
integer discard;

			
//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg [2:0] tetrominoes_tmp, position_tmp;
reg [95:0] tetris_tmp;
reg fail_tmp, add_score;
reg [3:0] score_tmp;
reg [11:0] shift;
reg [11:0] score_t;
reg score_valid_cnt, tetris_valid_cnt;
reg break_flag;
reg compute_done;
reg score_v, tet_v;
reg block;
reg [6:0] shape_pos0, shape_pos1, shape_pos2, shape_pos3, pos0, pos1, pos2, pos3;

//---------------------------------------------------------------------
//  CLOCK
//---------------------------------------------------------------------
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

//---------------------------------------------------------------------
//  SIMULATION
//---------------------------------------------------------------------
always @(negedge clk) begin
	reg condition1, condition2;
	if (tetris_valid === 0 && tetris !== 0) begin
		condition1 = 1;
	end
	if (score_valid === 0) begin
		if (score !== 4'd0 || fail !== 1'd0 || tetris_valid !== 1'd0) begin
			condition2 = 1;
		end
	end
	if (condition1 || condition2) begin
		$display("                    SPEC-5 FAIL                   ");
		$finish;
	end
end

always @(negedge clk) begin
	reg condition1, condition2;
	if (score_valid) begin
		condition1 = score_valid_cnt;
		score_valid_cnt = 1;
	end
	else
		score_valid_cnt = 0;
	if (tetris_valid) begin
		condition2 = tetris_valid_cnt;
		tetris_valid_cnt = 1;
	end
	else
		tetris_valid_cnt = 0;
	if (condition1 || condition2) begin
		$display("                    SPEC-8 FAIL                   ");
		$finish;
	end
end

initial begin
	pat_fd = $fopen("../00_TESTBED/input.txt", "r");
	SPEC4; 

	i_pat = 0;
	total_latency = 0;
	pre_input;
	$fscanf(pat_fd, "%d", PAT_NUM);
	for (i_pat = 1; i_pat <= PAT_NUM; i_pat = i_pat + 1) begin
		$fscanf(pat_fd, "%d", discard);
		pre_input;
		for (i = 0; i < 16 && !fail_tmp; i = i + 1) begin
			input_task;
            compute;
            if(fail_tmp || i == 15) begin
				break;
			end
            wait_valid;
		end
        //if (i != 15)
            wait_valid;
        while (i < 15) begin
			a = $fscanf(pat_fd, "%d %d", tetrominoes, position);
			i = i + 1;
		end
        /*if (!fail_tmp)
            wait_valid;*/
        if (latency !== 0)
            total_latency = total_latency + latency;
        //$display("PASS PATTERN NO.%4d", i_pat);
    end
	$display("                  Congratulations!               ");
	$display("              execution cycles = %7d", total_latency);
	$display("              clock period = %4fns", CYCLE);
	$fclose(pat_fd);
	$finish;
end

task pre_input;
	begin
		tetris_tmp = 95'd0;
		shift = 12'd0;
		score_t = 12'd0;
		score_tmp = 4'd0;
		fail_tmp = 0;
		compute_done = 0;
		score_v = 0;
		tet_v = 0;
		block = 0;
	end
endtask

task SPEC4;
	reg condition;
	begin
		rst_n = 1'b1;
        in_valid = 1'b0;
        tetrominoes = 3'dx;
		position = 3'dx;

        force clk = 1'b0;
        rst_n = 1'b0;

		#(100);
		condition = (tetris_valid !== 0 || score_valid !== 0 || fail !== 0 || score !== 0 || tetris !== 0);
		if (condition) begin
			$display("                    SPEC-4 FAIL                   ");
			$finish;
		end
		rst_n = 1;
		release clk;
	end
endtask

/*always @(posedge clk) begin
	if (in_valid) begin
		compute;
	end
end*/

task input_task;
    begin
        if(tetris_valid !== 1) begin

            t = $urandom_range(1, 4); // The next input
            repeat(t) @(negedge clk);
            //if (!fail_tmp) begin
                in_valid = 1'b1;
                a = $fscanf(pat_fd, "%d %d", tetrominoes, position);
                tetrominoes_tmp = tetrominoes;
			    position_tmp = position;
            /*end
            else begin
                in_valid = 1'b0;
		        while (i < 15) begin
			        a = $fscanf(pat_fd, "%d %d", tetrominoes, position);
			        i = i + 1;
			    end
            end*/
			

            @(negedge clk);
            in_valid = 1'd0;
            tetrominoes = 3'dx;
			position = 3'dx;
        end
    end
endtask

task compute;
	reg compute_flag = 0;
	reg block = 0;
    integer j = 0;
	begin
		break_flag = 1;
		case (tetrominoes_tmp)
			3'd0: begin
				shape_pos0 = 7'd78;
				shape_pos1 = 7'd79;
				shape_pos2 = 7'd72;
				shape_pos3 = 7'd73;
			end
			3'd1: begin
				shape_pos0 = 7'd90;
				shape_pos1 = 7'd84;
				shape_pos2 = 7'd78;
				shape_pos3 = 7'd72;
			end
			3'd2: begin
				shape_pos0 = 7'd72;
				shape_pos1 = 7'd73;
				shape_pos2 = 7'd74;
				shape_pos3 = 7'd75;
			end
			3'd3: begin
				shape_pos0 = 7'd84;
				shape_pos1 = 7'd85;
				shape_pos2 = 7'd79;
				shape_pos3 = 7'd73;
			end
			3'd4: begin
				shape_pos0 = 7'd78;
				shape_pos1 = 7'd79;
				shape_pos2 = 7'd80;
				shape_pos3 = 7'd72;
			end
			3'd5: begin
				shape_pos0 = 7'd84;
				shape_pos1 = 7'd78;
				shape_pos2 = 7'd72;
				shape_pos3 = 7'd73;
			end
			3'd6: begin
				shape_pos0 = 7'd84;
				shape_pos1 = 7'd78;
				shape_pos2 = 7'd79;
				shape_pos3 = 7'd73;
			end
			3'd7: begin
				shape_pos0 = 7'd79;
				shape_pos1 = 7'd80;
				shape_pos2 = 7'd72;
				shape_pos3 = 7'd73;
			end
			default: begin
				shape_pos0 = 7'd0;
				shape_pos1 = 7'd0;
				shape_pos2 = 7'd0;
				shape_pos3 = 7'd0;
			end
		endcase

        pos0 = shape_pos0 + position_tmp;
        pos1 = shape_pos1 + position_tmp;
        pos2 = shape_pos2 + position_tmp;
        pos3 = shape_pos3 + position_tmp;

		while(break_flag && !tetris_tmp[pos0] && !tetris_tmp[pos1] && !tetris_tmp[pos2] && !tetris_tmp[pos3]) begin
			if (pos3 < 6) begin
				break_flag = 0;
			end
			else begin
				pos0 = pos0 - 6;
                pos1 = pos1 - 6;
                pos2 = pos2 - 6;
                pos3 = pos3 - 6;
			end
		end
        if (break_flag) begin
            pos0 = pos0 + 6;
            pos1 = pos1 + 6;
            pos2 = pos2 + 6;
            pos3 = pos3 + 6;
        end

        tetris_tmp[pos0] = 1'd1;
        tetris_tmp[pos1] = 1'd1;
        tetris_tmp[pos2] = 1'd1;
        tetris_tmp[pos3] = 1'd1;

		check_score;
        // for (j = 0; j < 4 && add_score; j = j + 1) begin
        //     count_score;
        //     score_tmp = score_tmp + 1;
        //     check_score;
        //     if (|(tetris_tmp[95:72])) begin
        //         break;
        //     end
        // end
        while (add_score) begin
            count_score;
            score_tmp = score_tmp + 1;
            check_score;
        end
        fail_tmp = (|(tetris_tmp[95:72]))? 1 : 0;
        tetris_tmp[95:72] = 24'd0;
	end
endtask

task check_score;
	begin

		score_t[0] = &(tetris_tmp[5:0]);
		score_t[1] = &(tetris_tmp[11:6]);
		score_t[2] = &(tetris_tmp[17:12]);
		score_t[3] = &(tetris_tmp[23:18]);
		score_t[4] = &(tetris_tmp[29:24]);
		score_t[5] = &(tetris_tmp[35:30]);
		score_t[6] = &(tetris_tmp[41:36]);
		score_t[7] = &(tetris_tmp[47:42]);
		score_t[8] = &(tetris_tmp[53:48]);
		score_t[9] = &(tetris_tmp[59:54]);
		score_t[10] = &(tetris_tmp[65:60]);
		score_t[11] = &(tetris_tmp[71:66]);

		add_score = |score_t;
	end
endtask

task count_score;
	begin
		shift[0] = score_t[0];
		shift[1] = shift[0] || score_t[1];
		shift[2] = shift[1] || score_t[2];
		shift[3] = shift[2] || score_t[3];
		shift[4] = shift[3] || score_t[4];
		shift[5] = shift[4] || score_t[5];
		shift[6] = shift[5] || score_t[6];
		shift[7] = shift[6] || score_t[7];
		shift[8] = shift[7] || score_t[8];
		shift[9] = shift[8] || score_t[9];
		shift[10] = shift[9] || score_t[10];
		shift[11] = shift[10] || score_t[11];

		tetris_tmp[5:0] = (shift[0])? tetris_tmp[11:6] : tetris_tmp[5:0];
		tetris_tmp[11:6] = (shift[1])? tetris_tmp[17:12] : tetris_tmp[11:6];
		tetris_tmp[17:12] = (shift[2])? tetris_tmp[23:18] : tetris_tmp[17:12];
		tetris_tmp[23:18] = (shift[3])? tetris_tmp[29:24] : tetris_tmp[23:18];
		tetris_tmp[29:24] = (shift[4])? tetris_tmp[35:30] : tetris_tmp[29:24];
		tetris_tmp[35:30] = (shift[5])? tetris_tmp[41:36] : tetris_tmp[35:30];
		tetris_tmp[41:36] = (shift[6])? tetris_tmp[47:42] : tetris_tmp[41:36];
		tetris_tmp[47:42] = (shift[7])? tetris_tmp[53:48] : tetris_tmp[47:42];
		tetris_tmp[53:48] = (shift[8])? tetris_tmp[59:54] : tetris_tmp[53:48];
		tetris_tmp[59:54] = (shift[9])? tetris_tmp[65:60] : tetris_tmp[59:54];
		tetris_tmp[65:60] = (shift[10])? tetris_tmp[71:66] : tetris_tmp[65:60];
        tetris_tmp[71:66] = tetris_tmp[77:72];
		tetris_tmp[77:72] = tetris_tmp[83:78];
		tetris_tmp[83:78] = tetris_tmp[89:84];
		tetris_tmp[89:84] = tetris_tmp[95:90];
		tetris_tmp[95:90] = 6'd0;
    end
endtask

task wait_valid;
    begin
        latency = 1;
        while (score_valid !== 1'b1 && tetris_valid !== 1'b1) begin
            if(latency == 1000) begin
                $display("                    SPEC-6 FAIL                   ");
                $finish;
            end
            latency = latency + 1;
            @(negedge clk);
        end
		if (score_valid) begin
			score_v = 1;
            if (score_valid_cnt) begin
                $display("                    SPEC-8 FAIL                   ");
                $finish;
            end
			if (score !== score_tmp || fail !== fail_tmp) begin
                $display("score is %d, Your is %d.", score_tmp, score);
                $display("fail is %d, Your is %d.", fail_tmp, fail);
				$display("                    SPEC-7 FAIL                   ");
                $finish;
			end
		end
		if (tetris_valid) begin
			tet_v = 1;
            if (tetris_valid_cnt) begin
                $display("                    SPEC-8 FAIL                   ");
                $finish;
            end
			if (tetris !== tetris_tmp[71:0]) begin
                $display("Golden is %h, Your is %h", tetris_tmp[71:0], tetris);
				$display("                    SPEC-7 FAIL                   ");
                $finish;
			end
			//pre_input;
		end
		@(negedge clk);
    end
endtask

endmodule
// for spec check
// $display("                    SPEC-4 FAIL                   ");
// $display("                    SPEC-5 FAIL                   ");
// $display("                    SPEC-6 FAIL                   ");
// $display("                    SPEC-7 FAIL                   ");
// $display("                    SPEC-8 FAIL                   ");
// for successful design
// $display("                  Congratulations!               ");
// $display("              execution cycles = %7d", total_latency);
// $display("              clock period = %4fns", CYCLE);
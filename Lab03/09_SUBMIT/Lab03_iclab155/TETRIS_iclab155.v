/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: TETRIS
// FILE NAME: TETRIS.v
// VERSRION: 1.0
// DATE: August 15, 2024
// AUTHOR: Yu-Hsuan Hsu, NYCU IEE
// DESCRIPTION: ICLAB2024FALL / LAB3 / TETRIS
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/
module TETRIS (
	//INPUT
	rst_n,
	clk,
	in_valid,
	tetrominoes,
	position,
	//OUTPUT
	tetris_valid,
	score_valid,
	fail,
	score,
	tetris
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
input				rst_n, clk, in_valid;
input		[2:0]	tetrominoes;
input		[2:0]	position;
output reg			tetris_valid, score_valid, fail;
output reg	[3:0]	score;
output reg 	[71:0]	tetris;


//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
integer i;
//parameter read = 3'd0, read2 = 3'd1, shiftpixel = 3'd2, fill = 3'd3, compute = 3'd4;
parameter read = 2'd0, read2 = 2'd1, compute = 2'd2;

//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg [2:0] cs, ns;

reg [95:0] tetris_tmp;
reg [10:0] shift;
reg [11:0] score_t;
reg add_score;
wire [6:0] height [0:5];

reg [6:0] pos0, pos1, pos2, pos3;
reg [3:0] h0, h1, h2, h3;
reg [2:0] tetrominoes_tmp;
reg [2:0] position_tmp;
reg [3:0] _max_height;

reg [6:0] shape_pos0, shape_pos1, shape_pos2, shape_pos3;
reg [6:0] displace, posd0, posd1, posd2, posd3;
reg shift_condition;
reg [2:0] score_tmp;
reg [4:0] count;
reg fail_tmp;


//---------------------------------------------------------------------
//   FSM
//---------------------------------------------------------------------

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cs <= read;
    else
        cs <= ns;
end

always @(*) begin
    if (!rst_n)
        ns = read;
    else begin
        case (cs)
            read: begin
				ns = (in_valid && !fail)? read2 : read;
			end
			read2: ns = compute;
			// fill: begin
			// 	ns = compute;
			// end
			compute: begin
				ns = (add_score)? compute : read;
			end
            default: ns = read;
        endcase
    end
end
//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------

always @(*) begin
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
end

assign add_score = |score_t;

/*always @(*) begin
	shift = (score_t[0])? 11'b11111111111 : (score_t[1])? 11'b11111111110 : (score_t[2])? 11'b11111111100 : (score_t[3])? 11'b11111111000 :
		    (score_t[4])? 11'b11111110000 : (score_t[5])? 11'b11111100000 : (score_t[6])? 11'b11111000000 : (score_t[7])? 11'b11110000000 :
			(score_t[8])? 11'b11100000000 : (score_t[9])? 11'b11000000000 : (score_t[10])? 11'b10000000000 : 11'd0;
end*/

always @(*) begin
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
end

assign height[0] = (tetris_tmp[66])? 4'd12 : (tetris_tmp[60])? 4'd11 : (tetris_tmp[54])? 4'd10 : (tetris_tmp[48])? 4'd9 :
				   (tetris_tmp[42])? 4'd8  : (tetris_tmp[36])? 4'd7  : (tetris_tmp[30])? 4'd6  : (tetris_tmp[24])? 4'd5 :
				   (tetris_tmp[18])? 4'd4  : (tetris_tmp[12])? 4'd3  : (tetris_tmp[6])? 4'd2  : (tetris_tmp[0])? 4'd1 : 4'd0;

assign height[1] = (tetris_tmp[67])? 4'd12 : (tetris_tmp[61])? 4'd11 : (tetris_tmp[55])? 4'd10 : (tetris_tmp[49])? 4'd9 :
				   (tetris_tmp[43])? 4'd8  : (tetris_tmp[37])? 4'd7  : (tetris_tmp[31])? 4'd6  : (tetris_tmp[25])? 4'd5 :
				   (tetris_tmp[19])? 4'd4  : (tetris_tmp[13])? 4'd3  : (tetris_tmp[7])? 4'd2  : (tetris_tmp[1])? 4'd1 : 4'd0;

assign height[2] = (tetris_tmp[68])? 4'd12 : (tetris_tmp[62])? 4'd11 : (tetris_tmp[56])? 4'd10 : (tetris_tmp[50])? 4'd9 :
				   (tetris_tmp[44])? 4'd8  : (tetris_tmp[38])? 4'd7  : (tetris_tmp[32])? 4'd6  : (tetris_tmp[26])? 4'd5 :
				   (tetris_tmp[20])? 4'd4  : (tetris_tmp[14])? 4'd3  : (tetris_tmp[8])? 4'd2  : (tetris_tmp[2])? 4'd1 : 4'd0;

assign height[3] = (tetris_tmp[69])? 4'd12 : (tetris_tmp[63])? 4'd11 : (tetris_tmp[57])? 4'd10 : (tetris_tmp[51])? 4'd9 :
				   (tetris_tmp[45])? 4'd8  : (tetris_tmp[39])? 4'd7  : (tetris_tmp[33])? 4'd6  : (tetris_tmp[27])? 4'd5 :
				   (tetris_tmp[21])? 4'd4  : (tetris_tmp[15])? 4'd3  : (tetris_tmp[9])? 4'd2  : (tetris_tmp[3])? 4'd1 : 4'd0;

assign height[4] = (tetris_tmp[70])? 4'd12 : (tetris_tmp[64])? 4'd11 : (tetris_tmp[58])? 4'd10 : (tetris_tmp[52])? 4'd9 :
				   (tetris_tmp[46])? 4'd8  : (tetris_tmp[40])? 4'd7  : (tetris_tmp[34])? 4'd6  : (tetris_tmp[28])? 4'd5 :
				   (tetris_tmp[22])? 4'd4  : (tetris_tmp[16])? 4'd3  : (tetris_tmp[10])? 4'd2  : (tetris_tmp[4])? 4'd1 : 4'd0;

assign height[5] = (tetris_tmp[71])? 4'd12 : (tetris_tmp[65])? 4'd11 : (tetris_tmp[59])? 4'd10 : (tetris_tmp[53])? 4'd9 :
				   (tetris_tmp[47])? 4'd8  : (tetris_tmp[41])? 4'd7  : (tetris_tmp[35])? 4'd6  : (tetris_tmp[29])? 4'd5 :
				   (tetris_tmp[23])? 4'd4  : (tetris_tmp[17])? 4'd3  : (tetris_tmp[11])? 4'd2  : (tetris_tmp[5])? 4'd1 : 4'd0;

reg [3:0] max_height, max1, max2;
reg [2:0] p0, p1, p2, p3;
reg [6:0] tetro_h, dis1, dis2, dis3;

always @(*) begin
	if (in_valid) begin
		p0 = position;
		p1 = position + ((position[2] && position[0])? 3'd0 : 3'd1);
		p2 = position + ((position[2])? 3'd0 : 3'd2);
		p3 = position + ((position >= 3'd3 )? 3'd0 : 3'd3);

		h0 = height[p0];
		h1 = height[p1];
		h2 = height[p2];
		h3 = height[p3];
	end
	else begin
		p0 = 0;
		p1 = 0;
		p2 = 0;
		p3 = 0;

		h0 = 0;
		h1 = 0;
		h2 = 0;
		h3 = 0;
	end
end

always @(*) begin
	if (in_valid) begin
		case (tetrominoes)
			3'd0: max_height = (h0 >= h1)? h0 : h1;
			3'd1: max_height = h0;
			3'd2: begin
				max1 = (h0 >= h1)? h0 : h1;
				max2 = (h2 >= h3)? h2 : h3;
				max_height = (max1 >= max2)? max1 : max2;
			end
			3'd3: begin
				//max_height = (h0 >= h1)? h0 : h1;
				max_height = (h1 >= h0)? h1 : (((h0 - h1) <= 4'd2)? h1 : h0 - 2);
			end
			3'd4: begin
				/*max1 = (h0 >= h1)? h0 : h1;
				max_height = (max1 >= h2)? max1 : h2;*/
				max1 = (h1 >= h2)? h1 : h2;
				max_height = (h0 >= max1)? h0 : (((max1 - h0) <= 4'd1)? h0 : max1 - 1);
			end
			3'd5: max_height = (h0 >= h1)? h0 : h1;
			3'd6: begin
				//max_height = (h0 >= h1)? h0 : h1;
				max_height = (h1 >= h0)? h1 : (((h0 - h1) <= 4'd1)? h1 : h0 - 1);
			end
			3'd7: begin
				/*max1 = (h0 >= h1)? h0 : h1;
				max_height = (max1 >= h2)? max1 : h2;*/
				max1 = (h0 >= h1)? h0 : h1;
				max_height = (max1 >= h2)? max1 : (((h2 - max1) <= 4'd1)? max1 : h2 - 1);
			end
			default: max_height = h0;
		endcase
	end
	else begin
		max_height = 0;
	end 
end

always @(*) begin
	tetro_h = {_max_height, 2'd0} + {_max_height, 1'd0};
end

/*always @(*) begin
	if (in_valid) begin
		h0 = height[position];
		case (tetrominoes)
			3'd0: begin
				h1 = height[position + 1];
				max_height = (h0 > h1)? h0 : h1;
				dis1 = 7'd
			end 
			3'd1: begin
				
			end 
			3'd2: begin
				
			end 
			3'd3: begin
				
			end 
			3'd4: begin
				
			end 
			3'd5: begin
				
			end 
			3'd6: begin
				
			end 
			3'd7: begin
				
			end 
			default: 
		endcase
		pos4 = tetro_h + position;
		
	end
end*/

always @(*) begin
	//if (in_valid) begin
	case (tetrominoes_tmp)
		3'd0: shape_pos0 = tetro_h + 3'd6;
		3'd1: shape_pos0 = tetro_h + 5'd18; 
		3'd2: shape_pos0 = tetro_h;
		3'd3, 3'd5, 3'd6: shape_pos0 = tetro_h + 4'd12;
		3'd4: shape_pos0 = tetro_h + 3'd6;
		3'd7: shape_pos0 = tetro_h + 3'd7;
		default: shape_pos0 = 7'd78;
	endcase
	/*end
	else
		shape_pos0 = 7'd78;*/
end

always @(*) begin
	//if (in_valid) begin
	case (tetrominoes_tmp)
		3'd0, 3'd4: shape_pos1 = tetro_h + 3'd7;
		3'd1: shape_pos1 = tetro_h + 4'd12;
		3'd2: shape_pos1 = tetro_h + 1'd1;
		3'd3: shape_pos1 = tetro_h + 4'd13;
		3'd5, 3'd6: shape_pos1 = tetro_h + 3'd6;
		3'd7: shape_pos1 = tetro_h + 4'd8;
		default: shape_pos1 = 7'd79;
	endcase
	/*end
	else
		shape_pos1 = 7'd79;*/
end

always @(*) begin
	//if (in_valid) begin
	case (tetrominoes_tmp)
		3'd0, 3'd5, 3'd7: shape_pos2 = tetro_h;
		3'd1: shape_pos2 = tetro_h + 3'd6;
		3'd2: shape_pos2 = tetro_h + 2'd2;
		3'd3, 3'd6: shape_pos2 = tetro_h + 3'd7;
		3'd4: shape_pos2 = tetro_h + 4'd8;
		default: shape_pos2 = 7'd72;
	endcase
	/*end
	else
		shape_pos2 = 7'd72;*/
end

always @(*) begin
	//if (in_valid) begin
	case (tetrominoes_tmp)
		3'd0, 3'd3, 3'd5, 3'd6, 3'd7: shape_pos3 = tetro_h + 1'd1;
		3'd1, 3'd4: shape_pos3 = tetro_h; 
		3'd2: shape_pos3 = tetro_h + 2'd3;
		default: shape_pos3 = 7'd73;
	endcase
	/*end
	else
		shape_pos3 = 7'd73;*/
end

/*always @(*) begin
	if (in_valid) begin
		case (tetrominoes)
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
	end
end*/

always @(*) begin
	posd0 = pos0 + displace;
	posd1 = pos1 + displace;
	posd2 = pos2 + displace;
	posd3 = pos3 + displace;
end

assign score = (score_valid)? score_tmp : 4'd0;
assign tetris = (tetris_valid)? tetris_tmp[71:0] : 72'd0;
assign fail = (score_valid)? fail_tmp : 1'd0;

//assign shift_condition = tetris_tmp[posd0] || tetris_tmp[posd1] || tetris_tmp[posd2] || tetris_tmp[posd3] || posd3 > 7'd95;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		tetris_tmp <= 96'd0;
		score_valid <= 1'd0;
		tetris_valid <= 1'd0;
		fail_tmp <= 0;

		pos0 <= 0;
		pos1 <= 0;
		pos2 <= 0;
		pos3 <= 0;
		displace <= 0;
		score_tmp <= 3'd0;
		count <= 5'd0;
		tetrominoes_tmp <= 3'd0;
	end
	else begin
		case (cs)
			read: begin
				score_valid <= 1'd0;
				tetris_valid <= 1'd0;
				if (fail_tmp || count == 5'd16) begin
					//fail_tmp <= 1'd0;
					count <= 5'd0;
					score_tmp <= 3'd0;
					tetris_tmp[71:0] <= 72'd0;
				end
				if (in_valid && !fail) begin
					fail_tmp <= 1'd0;
					count <= count + 5'd1;
					// h0 <= height[p0];
					// h1 <= height[p1];
					// h2 <= height[p2];
					// h3 <= height[p3];
					_max_height <= max_height;
					tetrominoes_tmp <= tetrominoes;
					position_tmp <= position;
				end
			end
			read2: begin
				// pos0 <= shape_pos0;
				// pos1 <= shape_pos1;
				// pos2 <= shape_pos2;
				// pos3 <= shape_pos3;
				// displace <= position_tmp;
				tetris_tmp[shape_pos0 + position_tmp] <= 1'd1;
				tetris_tmp[shape_pos1 + position_tmp] <= 1'd1;
				tetris_tmp[shape_pos2 + position_tmp] <= 1'd1;
				tetris_tmp[shape_pos3 + position_tmp] <= 1'd1;
			end
			// fill: begin
			// 	tetris_tmp[posd0] <= 1'd1;
			// 	tetris_tmp[posd1] <= 1'd1;
			// 	tetris_tmp[posd2] <= 1'd1;
			// 	tetris_tmp[posd3] <= 1'd1;
			// end 
			compute: begin
				if (!add_score) begin
					score_valid <= 1'd1;
					tetris_valid <= 1'd1;
					fail_tmp <= |(tetris_tmp[95:72]);
					tetris_tmp[95:72] <= 24'd0;
				end
				else begin
					score_tmp <= score_tmp + 3'd1;
					tetris_tmp[5:0] <= (shift[0])? tetris_tmp[11:6] : tetris_tmp[5:0];
					tetris_tmp[11:6] <= (shift[1])? tetris_tmp[17:12] : tetris_tmp[11:6];
					tetris_tmp[17:12] <= (shift[2])? tetris_tmp[23:18] : tetris_tmp[17:12];
					tetris_tmp[23:18] <= (shift[3])? tetris_tmp[29:24] : tetris_tmp[23:18];
					tetris_tmp[29:24] <= (shift[4])? tetris_tmp[35:30] : tetris_tmp[29:24];
					tetris_tmp[35:30] <= (shift[5])? tetris_tmp[41:36] : tetris_tmp[35:30];
					tetris_tmp[41:36] <= (shift[6])? tetris_tmp[47:42] : tetris_tmp[41:36];
					tetris_tmp[47:42] <= (shift[7])? tetris_tmp[53:48] : tetris_tmp[47:42];
					tetris_tmp[53:48] <= (shift[8])? tetris_tmp[59:54] : tetris_tmp[53:48];
					tetris_tmp[59:54] <= (shift[9])? tetris_tmp[65:60] : tetris_tmp[59:54];
					tetris_tmp[65:60] <= (shift[10])? tetris_tmp[71:66] : tetris_tmp[65:60];
					tetris_tmp[71:66] <= tetris_tmp[77:72];
					tetris_tmp[77:72] <= tetris_tmp[83:78];
					tetris_tmp[83:78] <= tetris_tmp[89:84];
					tetris_tmp[89:84] <= tetris_tmp[95:90];
					tetris_tmp[95:90] <= 6'd0;
				end
			end
			default: score_valid <= 1'd0;
		endcase
	end
end

endmodule
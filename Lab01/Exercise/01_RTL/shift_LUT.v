module shift_LUT (
    input [3:0] in,
    output reg [3:0] out
);
/*always @(*) begin
    case (in)
        //4'd1, 4'd2, 4'd3, 4'd4: out = {in[2:0], 1'd0};
        4'd1: out = 4'd2;
        4'd2: out = 4'd4;
        4'd3: out = 4'd6;
        4'd4: out = 4'd8;
		4'd5: out = 4'd1;
        4'd6: out = 4'd3;
        4'd7: out = 4'd5;
        4'd8: out = 4'd7;
        4'd9: out = 4'd9;
		default: out = 4'd0;
	endcase
end*/
always @(*) begin
    case (in[2:0])
        //4'd1, 4'd2, 4'd3, 4'd4: out = {in[2:0], 1'd0};
        3'd0: out = (in[3])? 4'd7 : 4'd0;
        3'd1: out = (in[3])? 4'd9 : 4'd2;
        3'd2: out = 4'd4;
        3'd3: out = 4'd6;
        3'd4: out = 4'd8;
		3'd5: out = 4'd1;
        3'd6: out = 4'd3;
        3'd7: out = 4'd5;
		default: out = 4'd0;
	endcase
end

endmodule
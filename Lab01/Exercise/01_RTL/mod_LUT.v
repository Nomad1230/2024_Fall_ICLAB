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

module mul_LUT (
    input [7:0] multiplicand,
    output reg [7:0] product
);
always @(*) begin
    case (multiplicand)
        
		default: product = 8'd0;
	endcase
end

endmodule
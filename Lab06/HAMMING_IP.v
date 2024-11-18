//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2024/10
//		Version		: v1.0
//   	File Name   : HAMMING_IP.v
//   	Module Name : HAMMING_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module HAMMING_IP #(parameter IP_BIT = 8) (
    // Input signals
    IN_code,
    // Output signals
    OUT_code
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_BIT+4-1:0]  IN_code;

output reg [IP_BIT-1:0] OUT_code;

// ===============================================================
// Design
// ===============================================================
reg [3:0] xor_result;
wire [3:0] bit_value [0:1][0:15];
reg [15:0] out_temp;
reg [15:0] incode_temp;

always @(*) begin
    incode_temp = 0;
    incode_temp = IN_code;
end

assign bit_value[0] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
assign bit_value[1] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0};

always @(*) begin
    xor_result = bit_value[incode_temp[IP_BIT[3:0]+4'd3]][0] ^ bit_value[incode_temp[IP_BIT[3:0]+4'd2]][1] ^ bit_value[incode_temp[IP_BIT[3:0]+4'd1]][2] ^ bit_value[incode_temp[IP_BIT[3:0]]][3] ^
                 bit_value[incode_temp[IP_BIT[3:0]-4'd1]][4] ^ bit_value[incode_temp[IP_BIT[3:0]-4'd2]][5] ^ bit_value[incode_temp[IP_BIT[3:0]-4'd3]][6] ^ bit_value[incode_temp[IP_BIT[3:0]-4'd4]][7] ^
                 bit_value[incode_temp[IP_BIT[3:0]-4'd5]][8] ^ bit_value[incode_temp[IP_BIT[3:0]-4'd6]][9] ^ bit_value[incode_temp[IP_BIT[3:0]-4'd7]][10] ^ bit_value[incode_temp[IP_BIT[3:0]-4'd8]][11] ^
                 bit_value[incode_temp[IP_BIT[3:0]-4'd9]][12] ^ bit_value[incode_temp[IP_BIT[3:0]-4'd10]][13] ^ bit_value[incode_temp[IP_BIT[3:0]-4'd11]][14];
end

always @(*) begin
    out_temp = incode_temp;
    out_temp[IP_BIT+4 - xor_result] = ~incode_temp[IP_BIT+4 - xor_result];
    OUT_code = {out_temp[IP_BIT+4-3], out_temp[(IP_BIT+4-5)-:3], out_temp[(IP_BIT+4-9):0]};
end

endmodule
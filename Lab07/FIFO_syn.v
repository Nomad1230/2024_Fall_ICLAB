module FIFO_syn #(parameter WIDTH=8, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo,

    flag_fifo_to_clk1,
	flag_clk1_to_fifo
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
output reg flag_fifo_to_clk2;
input flag_clk2_to_fifo;

output flag_fifo_to_clk1;
input flag_clk1_to_fifo;

wire [WIDTH-1:0] rdata_q;

// Remember: 
//   wptr and rptr should be gray coded
//   Don't modify the signal name
reg [$clog2(WORDS):0] wptr, n_wptr, nn_wptr;
reg [$clog2(WORDS):0] rptr, n_rptr;
reg [6:0] write_address, n_write_address;
reg [6:0] read_address, n_read_address; // binary format
always @(*) begin  // gray code combinatial
    n_wptr = n_write_address ^ (n_write_address >> 1);
    n_rptr = n_read_address ^ (n_read_address >> 1);

    nn_wptr = (n_write_address + 7'd1) ^ ((n_write_address + 7'd1) >> 1);
end

reg [6:0] wptr_to_r;
reg [6:0] rptr_to_w;
wire full, empty;
wire almost_full;
reg rinc_q;

NDFF_BUS_syn #(.WIDTH(7)) ndff1(.D(rptr), .Q(rptr_to_w), .clk(wclk), .rst_n(rst_n));
NDFF_BUS_syn #(.WIDTH(7)) ndff2(.D(wptr), .Q(wptr_to_r), .clk(rclk), .rst_n(rst_n));

assign n_write_address = write_address + winc;//(winc & ~wfull);
assign n_read_address = read_address + rinc;//(rinc & ~rempty);

assign full = {~n_wptr[6:5], n_wptr[4:0]} == rptr_to_w;
assign empty = n_rptr == wptr_to_r;
assign almost_full = {~nn_wptr[6:5], nn_wptr[4:0]} == rptr_to_w;

// always @(posedge wclk or negedge rst_n) begin
//     if (!rst_n) begin
//         flag_fifo_to_clk2 <= 0;
//     end
//     else
//         flag_fifo_to_clk2 <= almost_full;
// end

assign flag_fifo_to_clk2 = full;

always @(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
        rempty <= 1;
        rptr <= 0;
        read_address <= 0;
    end
    else begin
       rempty <= empty; 
       rptr <= n_rptr;
       read_address <= n_read_address;
    end
end

always @(posedge wclk or negedge rst_n) begin
    if (!rst_n) begin
        wfull <= 0;
        wptr <= 0;
        write_address <= 0;
    end
    else begin
       wfull <= full;
       wptr <= n_wptr;
       write_address <= n_write_address;
    end
end

always @(posedge rclk or negedge rst_n) begin
    if (!rst_n) begin
        rdata <= 0;
    end
    else
        rdata <= (rinc || rinc_q)? rdata_q : 0; 
end

always @(posedge rclk or negedge rst_n) rinc_q <= (~rst_n) ? (1'b0) : (rinc);

reg [7:0]write_data;
wire [7:0] data_out_A;
reg WEB1;
wire WEB2;
wire CS1 , CS2;
assign CS1 = 1'b1;//~wfull;
assign CS2 = 1'b1;
assign WEB1 = ~winc;
assign WEB2 = 1'b1;
DUAL_64X8X1BM1 u_dual_sram (
                    .A0( write_address[0]),
                    .A1( write_address[1]),
                    .A2( write_address[2]),
                    .A3( write_address[3]),
                    .A4( write_address[4]),
                    .A5( write_address[5]),
                    .B0( read_address[0]),
                    .B1( read_address[1]),
                    .B2( read_address[2]),
                    .B3( read_address[3]),
                    .B4( read_address[4]),
                    .B5( read_address[5]),
                    .DOA0(data_out_A[0]),
                    .DOA1(data_out_A[1]),
                    .DOA2(data_out_A[2]),
                    .DOA3(data_out_A[3]),
                    .DOA4(data_out_A[4]),
                    .DOA5(data_out_A[5]),
                    .DOA6(data_out_A[6]),
                    .DOA7(data_out_A[7]),
                    .DOB0(rdata_q[0]),
                    .DOB1(rdata_q[1]),
                    .DOB2(rdata_q[2]),
                    .DOB3(rdata_q[3]),
                    .DOB4(rdata_q[4]),
                    .DOB5(rdata_q[5]),
                    .DOB6(rdata_q[6]),
                    .DOB7(rdata_q[7]),
                    .DIA0( wdata[0]),
                    .DIA1( wdata[1]),
                    .DIA2( wdata[2]),
                    .DIA3( wdata[3]),
                    .DIA4( wdata[4]),
                    .DIA5( wdata[5]),
                    .DIA6( wdata[6]),
                    .DIA7( wdata[7]),
                    .DIB0(1'b0),
                    .DIB1(1'b0),
                    .DIB2(1'b0),
                    .DIB3(1'b0),
                    .DIB4(1'b0),
                    .DIB5(1'b0),
                    .DIB6(1'b0),
                    .DIB7(1'b0),
                    .WEAN(WEB1),
                    .WEBN(WEB2),
                    .CKA(wclk),
                    .CKB(rclk),
                    .CSA(CS1),
                    .CSB(CS2),
                    .OEA(1'b1),
                    .OEB(1'b1)
                );

endmodule

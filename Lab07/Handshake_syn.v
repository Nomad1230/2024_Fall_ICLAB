module Handshake_syn #(parameter WIDTH=8) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output reg sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
output reg flag_handshake_to_clk1;
input flag_clk1_to_handshake;

output flag_handshake_to_clk2;
input flag_clk2_to_handshake;

// Remember:
//   Don't modify the signal name
reg sreq;
wire dreq;
reg dack;
wire sack;

reg [1:0] state1, state2;
reg [WIDTH-1:0] din_tmp;
NDFF_syn ndff1(.D(sreq), .Q(dreq), .clk(dclk), .rst_n(rst_n));
NDFF_syn ndff2(.D(dack), .Q(sack), .clk(sclk), .rst_n(rst_n));

always @(*) begin
    case (state1)
        2'd0: sidle = sready;
        2'd1: sidle = 1;
        2'd2: sidle = 1;//~sack;
        default: sidle = 0;
    endcase
end

always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        sreq <= 1'd0;
        state1 <= 2'd0;
        din_tmp <= 0;
        //sidle <= 1'd0;
    end
    else begin
        case (state1)
            2'd0: begin
                if (sready) begin
                    sreq <= 1'd1;
                    //sidle <= 1'd1;
                    state1 <= 2'd1;
                    din_tmp <= din;
                end
            end
            2'd1: begin
                if (sack) begin
                    sreq <= 1'd0;
                    state1 <= 2'd2;
                end
                // else begin
                //     sreq <= 1'd1;
                // end
            end
            2'd2: begin
                if (sack == 0) begin
                    //sidle <= 1'd0;
                    state1 <= 2'd0;
                end
            end
            default: sreq <= sreq; 
        endcase
    end
end

always @(posedge dclk or negedge rst_n) begin
    if (!rst_n) begin
        state2 <= 2'd0;
        dack <= 0;
        dvalid <= 0;
        dout <= 0;
    end
    else begin
        case (state2)
            2'd0: begin
                if (dreq) begin
                    dack <= 1'd1;
                    state2 <= 2'd1;
                end
            end 
            2'd1: begin
                if(dbusy == 0) begin
                    dout <= din_tmp;
                    dvalid <= 1;
                    //state2 <= 2'd2;
                end
                else begin
                    dout <= 0;
                    dvalid <= 0;
                    state2 <= 2'd2;
                end
            end
            2'd2: begin
                if(dreq == 0) begin
                    state2 <= 0;
                    dack <= 0;
                end
            end
            default: dack <= dack;
        endcase
    end
end
endmodule
module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
	in_row,
    in_kernel,
    out_idle,
    handshake_sready,
    handshake_din,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

	fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    out_data,

    flag_clk1_to_fifo,
    flag_fifo_to_clk1
);
input clk;
input rst_n;
input in_valid;
input [17:0] in_row;
input [11:0] in_kernel;
input out_idle;
output reg handshake_sready;
output reg [29:0] handshake_din;
// You can use the the custom flag ports for your design
input  flag_handshake_to_clk1;
output flag_clk1_to_handshake;

input fifo_empty;
input [7:0] fifo_rdata;
output reg fifo_rinc;
output reg out_valid;
output reg [7:0] out_data;
// You can use the the custom flag ports for your design
output flag_clk1_to_fifo;
input flag_fifo_to_clk1;

reg  [2:0] state;
reg [29:0] data_reg [0:5];
reg [2:0] read_cnt;
reg [7:0] read_mem_cnt;
reg [7:0] out_cnt;
reg [1:0] read_delay;

assign fifo_rinc = ~fifo_empty && (state >= 3'd2);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        read_mem_cnt <= 8'd0;
    end
    else begin
        read_mem_cnt <= (read_mem_cnt == 8'd150 && out_cnt >= 8'd149)? 8'd0 : (fifo_rinc && !fifo_empty)? read_mem_cnt + 1 : read_mem_cnt;
    end
end

reg [7:0] tmp;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= 0;
        out_valid <= 0;
        out_data <= 0;
        read_cnt <= 0;
        out_cnt <= 0;
        handshake_sready <= 0;
        handshake_din <= 0;
    end
    else begin
        case(state)
            3'd0: begin
                out_valid <= 0;
                out_data <= 0;
                if(in_valid) begin
                    data_reg[read_cnt] <= {in_row[2:0], in_row[5:3], in_row[8:6], in_row[11:9], in_row[14:12], in_row[17:15], 
                                           in_kernel[2:0], in_kernel[5:3], in_kernel[8:6], in_kernel[11:9]};
                    if (read_cnt == 3'd5) begin
                        read_cnt <= 3'd0;
                        state <= 3'd1;
                    end
                    else begin
                        read_cnt <= read_cnt + 1;
                    end
                end
            end
            3'd1: begin
                if(out_idle == 0) begin
                    handshake_sready <= 1'b1;         //start to transmit
                    handshake_din <= data_reg[read_cnt];
                    read_cnt <= read_cnt + 1;
                end
                else begin
                    handshake_sready <= 1'b0;   //end transmit
                    handshake_din <= 0;
                    state <= (read_cnt == 3'd6)? 3'd2 : 3'd1;
                end
            end
            3'd2: begin
                if (out_cnt == 150) begin
                    state <= 3'd0;
                    out_cnt <= 0;
                    read_cnt <= 0;
                    out_valid <= 0;
                    out_data <= 0;
                end
                else
                    state <= (!fifo_empty)? 3'd3 : 3'd2;
                if (out_cnt < read_mem_cnt) begin
                    out_cnt <=  out_cnt + 1;
                    out_valid <= 1;
                    out_data <= fifo_rdata;
                end
                else begin
                    out_valid <= 0;
                    out_data <= 0;
                end
            end
            3'd3: begin
                state <= 3'd4;
                tmp <= fifo_rdata;
                out_valid <= 0;
                out_data <= 0;
            end
            3'd4: begin
                out_cnt <=  out_cnt + 1;
                out_valid <= 1;
                out_data <= fifo_rdata;

                if(out_cnt == 150) begin
                    state <= 3'd0;
                    out_valid <= 0;
                    out_cnt <= 0;
                    out_data <= 0;
                    read_cnt <= 0;
                end
                else begin
                    if (fifo_empty) begin
                        state <= 3'd2;
                    end
                end
            end
            default: begin
                out_valid <= 0;
                out_data <= 0;
            end
        endcase
    end
end

endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    in_data,
    out_valid,
    out_data,
    busy,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [29:0] in_data;
output reg out_valid;
output reg [7:0] out_data;
output reg busy;

// You can use the the custom flag ports for your design
input  flag_handshake_to_clk2;
output flag_clk2_to_handshake;

input  flag_fifo_to_clk2;
output flag_clk2_to_fifo;

integer i;
reg state;
reg [2:0] read_cnt;

reg [2:0] map [0:35];
reg [2:0] kernel1 [0:3];
reg [2:0] kernel2 [0:3];
reg [2:0] kernel3 [0:3];
reg [2:0] kernel4 [0:3];
reg [2:0] kernel5 [0:3];
reg [2:0] kernel6 [0:3];
reg [7:0] compute_cnt;
reg [5:0] map_cnt;
reg [2:0] kernel_cnt;
reg map_change_row;
reg wait_flag;

//assign busy = in_valid;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        busy <= 1'd0;
        read_cnt <= 3'd0;
    end
    else begin
        if (!busy && in_valid) begin
            busy <= 1'd1;
            read_cnt <= read_cnt + 1;
            case (read_cnt)
                3'd0: begin
                    {map[0], map[1], map[2], map[3], map[4], map[5]} <= in_data[29:12];
                    {kernel1[0], kernel1[1], kernel1[2], kernel1[3]} <= in_data[11:0];
                end
                3'd1: begin
                    {map[6], map[7], map[8], map[9], map[10], map[11]} <= in_data[29:12];
                    {kernel2[0], kernel2[1], kernel2[2], kernel2[3]} <= in_data[11:0];
                end
                3'd2: begin
                    {map[12], map[13], map[14], map[15], map[16], map[17]} <= in_data[29:12];
                    {kernel3[0], kernel3[1], kernel3[2], kernel3[3]} <= in_data[11:0];
                end
                3'd3: begin
                    {map[18], map[19], map[20], map[21], map[22], map[23]} <= in_data[29:12];
                    {kernel4[0], kernel4[1], kernel4[2], kernel4[3]} <= in_data[11:0];
                end
                3'd4: begin
                    {map[24], map[25], map[26], map[27], map[28], map[29]} <= in_data[29:12];
                    {kernel5[0], kernel5[1], kernel5[2], kernel5[3]} <= in_data[11:0];
                end
                3'd5: begin
                    {map[30], map[31], map[32], map[33], map[34], map[35]} <= in_data[29:12];
                    {kernel6[0], kernel6[1], kernel6[2], kernel6[3]} <= in_data[11:0];
                end
                default: begin
                    map[0] <= map[0];
                end
            endcase
        end
        else begin
            busy <= 1'd0;
            if (compute_cnt == 8'd151)
                read_cnt <= 3'd0;
        end
    end
end

always @(*) begin
    case (map_cnt)
        6'd4, 6'd10, 6'd16, 6'd22: map_change_row = 1; 
        default: map_change_row = 0;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        compute_cnt <= 0;
        map_cnt <= 0;
        kernel_cnt <= 0;
        wait_flag <= 0;
    end
    else begin
        if (read_cnt >= 3'd2 && !flag_fifo_to_clk2 && !wait_flag) begin
            //compute_cnt <= (compute_cnt == 151)? 0 : compute_cnt + 1;
            map_cnt <= (map_cnt == 6'd28)? 0 : map_cnt + ((map_change_row)? 2'd2 : 2'd1);
            kernel_cnt <= (map_cnt == 6'd28)? kernel_cnt + 1 : kernel_cnt;
            if (read_cnt <= 3'd5 && map_change_row) begin
                wait_flag <= 1;
            end
            if (compute_cnt == 151) begin
                compute_cnt <= 0;
                map_cnt <= 0;
                kernel_cnt <= 0;
            end
            else
                compute_cnt <= compute_cnt + 1;
        end
        else begin
            if (compute_cnt == 151) begin
                compute_cnt <= 0;
                map_cnt <= 0;
                kernel_cnt <= 0;
            end
            if (in_valid) begin
                wait_flag <= 0;
            end
        end
    end
end

reg [2:0] mulA [0:3];
reg [2:0] mulB [0:3];
reg [5:0] result [0:3];

always @(*) begin
    for (i = 0; i < 4; i = i + 1) begin
        result[i] = mulA[i] * mulB[i];
    end
end

always @(*) begin
    mulA[0] = map[map_cnt];
    mulA[1] = map[map_cnt + 1];
    mulA[2] = map[map_cnt + 6];
    mulA[3] = map[map_cnt + 7];
end

always @(*) begin
    case (kernel_cnt)
        3'd0: begin
            for (i = 0; i < 4; i = i + 1) begin
                mulB[i] = kernel1[i];
            end
        end 
        3'd1: begin
            for (i = 0; i < 4; i = i + 1) begin
                mulB[i] = kernel2[i];
            end
        end
        3'd2: begin
            for (i = 0; i < 4; i = i + 1) begin
                mulB[i] = kernel3[i];
            end
        end 
        3'd3: begin
            for (i = 0; i < 4; i = i + 1) begin
                mulB[i] = kernel4[i];
            end
        end
        3'd4: begin
            for (i = 0; i < 4; i = i + 1) begin
                mulB[i] = kernel5[i];
            end
        end 
        3'd5: begin
            for (i = 0; i < 4; i = i + 1) begin
                mulB[i] = kernel6[i];
            end
        end
        default: begin
            mulB[0] = 0;
            mulB[1] = 0;
            mulB[2] = 0;
            mulB[3] = 0;
        end
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 0;
        out_data <= 0;
    end
    else begin
        // out_valid <= 1;
        // out_data <= 50;
        //if (read_cnt >= 3'd2 && !flag_fifo_to_clk2 && !wait_flag && compute_cnt <= 149) begin
        if (read_cnt >= 3'd2 && !flag_fifo_to_clk2 && !wait_flag && compute_cnt <= 149) begin
            out_valid <= 1;
            out_data <= result[0] + result[1] + result[2] + result[3];
        end
        else begin
            out_valid <= 0;
            out_data <= 0;
        end
    end
end
endmodule
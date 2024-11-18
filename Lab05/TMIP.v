module TMIP(
    // input signals
    clk,
    rst_n,
    in_valid, 
    in_valid2,
    
    image,
    template,
    image_size,
	action,
	
    // output signals
    out_valid,
    out_value
    );

input            clk, rst_n;
input            in_valid, in_valid2;

input      [7:0] image;
input      [7:0] template;
input      [1:0] image_size;
input      [2:0] action;

output reg       out_valid;
output reg       out_value;

//==================================================================
// parameter & integer
//==================================================================
parameter S_IDLE = 4'd0, S_READ_IMG = 4'd1, S_READ_ACTION = 4'd2, S_READ_MAP = 4'd3, S_CONTROL = 4'd4, 
          S_MAX_POOL = 4'd5, S_MEDIAN = 4'd6, S_OUTPUT = 4'd7, S_WAIT = 4'd8;
integer i;

//==================================================================
// reg & wire
//==================================================================
wire A0, A1, A2, A3, A4, A5, A6, A7, A8;
wire DI0, DI1, DI2, DI3, DI4, DI5, DI6, DI7, DI8, DI9, DI10, DI11, DI12, DI13, DI14, DI15, DI16, 
     DI17, DI18, DI19, DI20, DI21, DI22, DI23, DI24, DI25, DI26, DI27, DI28, DI29, DI30, DI31, DI32, 
     DI33, DI34, DI35, DI36, DI37, DI38, DI39, DI40, DI41, DI42, DI43, DI44, DI45, DI46, DI47, DI48, 
     DI49, DI50, DI51, DI52, DI53, DI54, DI55, DI56, DI57, DI58, DI59, DI60, DI61, DI62, DI63, DI64, 
     DI65, DI66, DI67, DI68, DI69, DI70, DI71, DI72, DI73, DI74, DI75, DI76, DI77, DI78, DI79, DI80, 
     DI81, DI82, DI83, DI84, DI85, DI86, DI87, DI88, DI89, DI90, DI91, DI92, DI93, DI94, DI95, DI96, 
     DI97, DI98, DI99, DI100, DI101, DI102, DI103, DI104, DI105, DI106, DI107, DI108, DI109, DI110, DI111, DI112, 
     DI113, DI114, DI115, DI116, DI117, DI118, DI119, DI120, DI121, DI122, DI123, DI124, DI125, DI126, DI127;

wire DO0, DO1, DO2, DO3, DO4, DO5, DO6, DO7, DO8, DO9, DO10, DO11, DO12, DO13, DO14, DO15, DO16, 
	 DO17, DO18, DO19, DO20, DO21, DO22, DO23, DO24, DO25, DO26, DO27, DO28, DO29, DO30, DO31, DO32, 
	 DO33, DO34, DO35, DO36, DO37, DO38, DO39, DO40, DO41, DO42, DO43, DO44, DO45, DO46, DO47, DO48, 
	 DO49, DO50, DO51, DO52, DO53, DO54, DO55, DO56, DO57, DO58, DO59, DO60, DO61, DO62, DO63, DO64, 
	 DO65, DO66, DO67, DO68, DO69, DO70, DO71, DO72, DO73, DO74, DO75, DO76, DO77, DO78, DO79, DO80, 
	 DO81, DO82, DO83, DO84, DO85, DO86, DO87, DO88, DO89, DO90, DO91, DO92, DO93, DO94, DO95, DO96, 
	 DO97, DO98, DO99, DO100, DO101, DO102, DO103, DO104, DO105, DO106, DO107, DO108, DO109, DO110, DO111, DO112, 
	 DO113, DO114, DO115, DO116, DO117, DO118, DO119, DO120, DO121, DO122, DO123, DO124, DO125, DO126, DO127;
reg [15:0] data_in, data_out;
reg img_mem_we;
reg [3:0] cs, ns;
reg [7:0] template_reg [0:8];
reg [3:0] template_cnt, n_template_cnt;
reg [2:0] channel_cnt, n_channel_cnt;
reg flip;
reg [8:0] img_addr;
reg [1:0] img_addr_base, n_img_addr_base;
reg [6:0] img_addr_offset, n_img_addr_offset;

reg wait_flag;
reg [7:0] img_reg;
reg [1:0] _img_size, _img_size_n;
reg [7:0] img_bound;
reg [7:0] in_buf [0:11];
reg [7:0] n_in_buf [0:11];
reg mem_write_flag;

reg [7:0] avg1, avg2;
reg [2:0] rmd1, rmd2;
reg [7:0] w_avg1, w_avg2;
reg [3:0] w_rmd1, w_rmd2;
reg [1:0] cor1, cor2, cor3, cor4;

reg [1:0] base_reg;
reg [2:0] _action [0:7];
reg [2:0] _n_action [0:7];
reg shift;       // 0: shift 1 reg, 1: shift 2 reg
reg neg_compute; // check if operand should go through not gate
reg compute_done;
reg read_done;
reg read_flag;

reg change_row;
reg [7:0] change_row_displace;
reg [7:0] compute_reg [0:255];
reg [7:0] read_cnt, n_read_cnt;
wire [7:0] read_cnt_inc;
reg [6:0] pseudo_addr;
wire [7:0] pseudo_addr_inc;
reg [7:0] data_out_ff [0:1];

reg [7:0] A [0:15];
reg [7:0] B [0:15];
reg [7:0] C [0:15];
reg [7:0] D [0:15];
reg [7:0] E [0:15];
reg [7:0] F [0:15];
reg [7:0] G [0:15];
reg [7:0] H [0:15];
reg [7:0] I [0:15];
reg [7:0] out_wire [0:15];
reg [4:0] cal_cnt;
reg [3:0] cal_cnt_bound;
wire first_col, last_col;
reg [7:0] shift_reg [0:15];
reg [7:0] out_reg [0:15];
reg [4:0] out_cnt;
reg out_cnt_valid;
reg [7:0] mula;
reg [7:0] mulb;
reg [15:0] mul_result;
reg [7:0] mul_addr;
reg [7:0] mul_addr_bound;
reg [3:0] mul_cnt;
reg cal_first_col, cal_last_col, cal_first_row, cal_last_row;
wire [7:0] mul_addr_left_up,  mul_addr_up, mul_addr_right_up;
wire [7:0] mul_addr_left, mul_addr_right;
wire [7:0] mul_addr_left_down,  mul_addr_down, mul_addr_right_down;
wire [7:0] mul_data_left_up,  mul_data_up, mul_data_right_up;
wire [7:0] mul_data_left, mul_data_right, mul_data_mid;
wire [7:0] mul_data_left_down,  mul_data_down, mul_data_right_down;
reg [2:0] set_num;

//==================================================================
// design
//==================================================================
assign {DI0, DI1, DI2, DI3, DI4, DI5, DI6, DI7, DI8, DI9, DI10, DI11, DI12, DI13, DI14, DI15} = data_in;
assign data_out = {DO0, DO1, DO2, DO3, DO4, DO5, DO6, DO7, DO8, DO9, DO10, DO11, DO12, DO13, DO14, DO15};
assign {A0, A1, A2, A3, A4, A5, A6, A7, A8} = img_addr;

SUMA180_512X16X1BM1 IMG_REM(.A0(A0), .A1(A1), .A2(A2), .A3(A3), .A4(A4), .A5(A5), .A6(A6), .A7(A7), .A8(A8),
	                        .DI0(DI0), .DI1(DI1), .DI2(DI2), .DI3(DI3), .DI4(DI4), .DI5(DI5), .DI6(DI6), .DI7(DI7), .DI8(DI8), .DI9(DI9), .DI10(DI10), .DI11(DI11), .DI12(DI12), .DI13(DI13), .DI14(DI14), .DI15(DI15), 
	                        .DO0(DO0), .DO1(DO1), .DO2(DO2), .DO3(DO3), .DO4(DO4), .DO5(DO5), .DO6(DO6), .DO7(DO7), .DO8(DO8), .DO9(DO9), .DO10(DO10), .DO11(DO11), .DO12(DO12), .DO13(DO13), .DO14(DO14), .DO15(DO15), 
	                        .CK(clk), .WEB(img_mem_we), .OE(1'd1), .CS(1'b1));

//---------------------------//
//           FSM             //
//---------------------------//
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        cs <= S_IDLE;
    end
    else begin
        cs <= ns;
    end
end

always @(*) begin
    case (cs)
        S_IDLE: ns = (in_valid)? S_READ_IMG : S_IDLE;
        S_READ_IMG: ns = (in_valid)? S_READ_IMG : S_READ_ACTION;
        S_READ_ACTION: ns = (in_valid2)? S_READ_ACTION : (template_cnt <= 1)? S_READ_ACTION : S_WAIT;//((!base_reg)? S_CONTROL : S_READ_MAP);
        S_WAIT: ns = (wait_flag)? S_READ_MAP : S_WAIT;
        S_READ_MAP: ns = (read_cnt <= img_bound || !mem_write_flag)? S_READ_MAP : S_CONTROL;
        S_CONTROL: begin
            if (_action[0] == 3'd7) begin// || (_action[0] == 3'd4 && _action[1] == 3'd7)) begin
                ns = S_OUTPUT;
            end
            else begin
                if (_action[0] == 3'd3 && _img_size) begin //|| (_action[0] == 3'd4 && _action[0] == 3'd3)) begin
                    ns = S_MAX_POOL;
                end
                else if (_action[0] == 3'd6) begin//|| (_action[0] == 3'd4 && _action[0] == 3'd6)) begin
                    ns = S_MEDIAN;
                end
                else
                    ns = S_CONTROL;
            end
                
        end
        S_MAX_POOL: ns = (cal_cnt == ((_img_size)? 5'd4 : 5'd1))? S_CONTROL : S_MAX_POOL;
        S_MEDIAN: ns = (cal_cnt == (cal_cnt_bound + 1))? S_CONTROL : S_MEDIAN;
        S_OUTPUT: ns = (((mul_addr > mul_addr_bound) || !mul_addr) && (out_cnt == 18 && out_valid))? ((set_num == 3'd7)? S_IDLE : S_READ_ACTION) : S_OUTPUT;
        default: ns = S_IDLE;
    endcase
end

//---------------------------//
//         Read IMG          //
//---------------------------//
reg [1:0] orig_img_size;
always @(posedge clk) begin
    wait_flag <= (cs == S_WAIT)? 1'd1 : 1'd0;
    orig_img_size <= (cs == S_IDLE && in_valid) ? image_size : orig_img_size;
end

always@(posedge clk)
    _img_size <= _img_size_n;

always @(*) begin
    if (cs == S_IDLE && in_valid) begin
        _img_size_n = image_size;
    end
    else if (cs != S_MAX_POOL && ns == S_MAX_POOL) begin
        _img_size_n = _img_size >> 1;
    end
    else if (cs == S_OUTPUT && ns != S_OUTPUT) begin
        _img_size_n = orig_img_size;
    end
    else
        _img_size_n = _img_size;
end

always @(*) begin
    case (_img_size)
        2'd0: img_bound = 49;
        2'd1: img_bound = 117;
        2'd2: img_bound = 253; 
        default: img_bound = 0;
    endcase
end

always @(posedge clk)
    template_cnt <= n_template_cnt;

wire [3:0] template_cnt_inc;
assign template_cnt_inc = template_cnt + 1;
 
always @(*) begin
    case (cs)
        S_IDLE: n_template_cnt = in_valid;
        S_READ_IMG: n_template_cnt = (template_cnt <= 4'd8)? template_cnt_inc : ((ns == S_READ_ACTION)? 4'd0 : template_cnt);
        S_READ_ACTION: n_template_cnt = (in_valid2)? template_cnt_inc : 4'd0;
        default: n_template_cnt = template_cnt;
    endcase
end

always @(posedge clk) begin
    case (cs)
        S_IDLE, S_READ_IMG: begin
            if (template_cnt <= 4'd8 && in_valid) begin
                template_reg[template_cnt] <= template;
            end
        end 
        default: template_reg[0] <= template_reg[0];
    endcase
end

always @(posedge clk)
    channel_cnt <= n_channel_cnt;  //0~5 loop

always @(*) begin
    case (cs)
        S_IDLE: n_channel_cnt = in_valid;
        S_READ_IMG, S_READ_ACTION: n_channel_cnt = (channel_cnt <= 3'd4)? channel_cnt + 1 : 3'd0;
        default: n_channel_cnt = channel_cnt;
    endcase
end

always @(posedge clk) begin
    case (cs)
        S_IDLE: mem_write_flag <= 1'd0;
        S_READ_IMG: mem_write_flag <= (channel_cnt == 3'd5)? 1'd1 : mem_write_flag; 
        S_READ_ACTION: mem_write_flag <= (in_valid2)? 1'd0 : mem_write_flag;
        S_WAIT: mem_write_flag <= (!read_cnt)? 1'd1 : mem_write_flag;
        default: mem_write_flag <= 1'd1;
    endcase
end

always @(posedge clk or negedge rst_n) 
    img_addr_base <= (!rst_n)? 0 : n_img_addr_base;

always @(*) begin
    case (cs)
        S_IDLE: n_img_addr_base = 2'd0;
        S_READ_IMG, S_READ_ACTION: begin
            case (channel_cnt) 
                3'd1: n_img_addr_base = 2'd0; 
                3'd2: n_img_addr_base = 2'd1; 
                3'd3: n_img_addr_base = 2'd2; 
                default: n_img_addr_base = img_addr_base;
            endcase
        end
        //S_READ_ACTION: n_img_addr_base = (in_valid2 && mem_write_flag)? action[1:0] : img_addr_base; 
        default: n_img_addr_base = base_reg;
    endcase
end

always @(posedge clk or negedge rst_n)
    img_addr_offset <= (!rst_n)? 0 : n_img_addr_offset;

always @(posedge clk) begin
    read_flag <= (cs == S_READ_ACTION && ns == S_READ_MAP)? 1'd1 : 1'd0;
end

reg [6:0] write_RAM_bound;

always @(*) begin
    case (_img_size)
        2'd0: write_RAM_bound = 7;
        2'd1: write_RAM_bound = 31;
        2'd2: write_RAM_bound = 127;
        default: write_RAM_bound = 7;
    endcase
end

always @(*) begin
    case (cs)
        S_IDLE: n_img_addr_offset = 7'd0;
        S_READ_IMG, S_READ_ACTION: n_img_addr_offset = (channel_cnt == 3'd4 && mem_write_flag)? 
                                   img_addr_offset + 1 : ((cs == S_READ_ACTION && channel_cnt == 3'd4)? 0 : img_addr_offset);
        S_WAIT: n_img_addr_offset = (wait_flag)? img_addr_offset + 1 : 0;
        S_READ_MAP: n_img_addr_offset = img_addr_offset + 1;//(read_flag)? 0 : img_addr_offset + 1;
        S_CONTROL: n_img_addr_offset = 7'd0;
        default: n_img_addr_offset = img_addr_offset;
    endcase
end

//assign img_addr = {img_addr_base, img_addr_offset};
assign img_addr = {img_addr_base, pseudo_addr};

reg [7:0] max1, max2;
always @(posedge clk) begin
    case (channel_cnt)
        3'd0: max1 <= image;
        3'd1, 2'd2: max1 <= (image >= max1)? image : max1;
        3'd3: max2 <= image;
        3'd4, 3'd5: max2 <= (image >= max2)? image : max2;
        default: max1 <= max1;
    endcase
end

wire [6:0] q;
wire [1:0] r;

//div3 div(image, q, r);
div3_LUT div(image, q, r);

always @(posedge clk) begin
    case (channel_cnt)
        3'd0: {avg1, rmd1} <= {1'd0, q, 1'd0, r};
        3'd1, 2'd2: begin
            avg1 <= avg1 + q;
            rmd1 <= rmd1 + r;
        end
        3'd3: {avg2, rmd2} <= {1'd0, q, 1'd0, r};
        3'd4, 3'd5: begin
            avg2 <= avg2 + q;
            rmd2 <= rmd2 + r;
        end
        default: avg1 <= avg1;
    endcase
end

always @(posedge clk) begin
    case (channel_cnt)
        3'd0: {w_avg1, w_rmd1} <= {2'd0, image[7:2] , 2'd0, image[1:0]};
        3'd1, 3'd2: begin
            w_avg1 <= w_avg1 + ((channel_cnt[0])? image[7:1] : image[7:2]);
            w_rmd1 <= w_rmd1 + ((channel_cnt[0])? {image[0], 1'd0} : image[1:0]);
        end
        3'd3: {w_avg2, w_rmd2} <= {2'd0, image[7:2] , 2'd0, image[1:0]};
        3'd4, 3'd5: begin
            w_avg2 <= w_avg2 + ((channel_cnt[0])? image[7:2] : image[7:1]);
            w_rmd2 <= w_rmd2 + ((channel_cnt[0])? image[1:0] : {image[0], 1'd0});
        end
        default: w_avg1 <= w_avg1;
    endcase
end

always @(*)
    cor1 = (rmd1 >= 3'd6)? 2'd2 : ((rmd1 >= 3'd3)? 2'd1 : 2'd0);
always @(*)
    cor2 = (rmd2 >= 3'd6)? 2'd2 : ((rmd2 >= 3'd3)? 2'd1 : 2'd0);
always @(*)
    cor3 = (w_rmd1 >= 4'd8)? 2'd2 : ((w_rmd1 >= 3'd4)? 2'd1 : 2'd0);
always @(*)
    cor4 = (w_rmd2 >= 4'd8)? 2'd2 : ((w_rmd2 >= 3'd4)? 2'd1 : 2'd0);

always @(posedge clk) begin
    for (i = 0; i < 34; i = i + 1) begin
        in_buf[i] <= n_in_buf[i];
    end
end

always @(*) begin
    case (cs)
        S_IDLE, S_READ_IMG, S_READ_ACTION: begin
            if (img_mem_we) begin
                for (i = 0; i < 6; i = i + 1) begin
                    n_in_buf[i] = in_buf[i + 6];
                end
            end
            else begin
                for (i = 0; i < 6; i = i + 1) begin
                    n_in_buf[i] = in_buf[i + 2];
                end
            end
            case (channel_cnt)
                3'd1, 3'd2, 3'd3: begin
                    {n_in_buf[6], n_in_buf[8], n_in_buf[10]} = {max1, avg1 + cor1, w_avg1};
                    {n_in_buf[7], n_in_buf[9], n_in_buf[11]} = {in_buf[7], in_buf[9], in_buf[11]};
                end 
                3'd0, 3'd4, 3'd5: begin
                    {n_in_buf[6], n_in_buf[8], n_in_buf[10]} = {in_buf[6], in_buf[8], in_buf[10]};
                    {n_in_buf[7], n_in_buf[9], n_in_buf[11]} = {max2, avg2 + cor2, w_avg2};
                end 
                default: begin
                    for (i = 0; i < 34; i = i + 1) begin
                        n_in_buf[i] = in_buf[i];
                    end
                end
            endcase 
        end
        default: begin
            for (i = 0; i < 34; i = i + 1) begin
                n_in_buf[i] = in_buf[i];
            end
        end 
    endcase
end

always @(*) begin
    case (cs)
        S_READ_IMG, S_READ_ACTION: data_in = (!img_mem_we)? {in_buf[0], in_buf[1]} : 0;
        default: data_in = 16'd0;
    endcase
end

reg write_RAM_flag;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        write_RAM_flag <= 1'd0;
    end
    else if (cs == S_READ_ACTION && channel_cnt == 3'd4) begin
        write_RAM_flag <= 1'd1;
    end
    else if (cs == S_IDLE)
        write_RAM_flag <= 1'd0;
end

always @(*) begin
    case (cs)
        S_READ_IMG: begin
            if (channel_cnt >= 2 && channel_cnt <= 4 && mem_write_flag) 
                img_mem_we = 1'd0;
            else
                img_mem_we = 1'd1;
        end
        S_READ_ACTION: begin
            if (channel_cnt >= 2 && channel_cnt <= 4 && !write_RAM_flag)
                img_mem_we = 1'd0;
            else
                img_mem_we = 1'd1; 
        end
        default: img_mem_we = 1'd1; 
    endcase
end

//---------------------------//
//      Action parsing       //
//---------------------------//
always @(posedge clk) begin
    for (i = 0; i < 8; i = i + 1) begin
        _action[i] <= _n_action[i];
    end
end

always @(posedge clk)
    base_reg <= (in_valid2 && mem_write_flag)? action[1:0] : base_reg;

always @(*) begin
    case (cs)
        S_READ_ACTION: begin
            for (i = 0; i < 8; i = i + 1) begin
                _n_action[i] = _action[i];
            end
            case (template_cnt)
                4'd0: _n_action[0] = (!in_valid2)? 8'd0 :((action == 3'd5 || (!_img_size && action == 3'd3))? base_reg : action);
                4'd1: _n_action[1] = (!in_valid2)? 8'd0 :((action == 3'd5 || (!_img_size && action == 3'd3))? base_reg : action);
                4'd2: _n_action[2] = (!in_valid2)? 8'd0 :((action == 3'd5 || (!_img_size && action == 3'd3))? base_reg : action);
                4'd3: _n_action[3] = (!in_valid2)? 8'd0 :((action == 3'd5 || (!_img_size && action == 3'd3))? base_reg : action);
                4'd4: _n_action[4] = (!in_valid2)? 8'd0 :((action == 3'd5 || (!_img_size && action == 3'd3))? base_reg : action);
                4'd5: _n_action[5] = (!in_valid2)? 8'd0 :((action == 3'd5 || (!_img_size && action == 3'd3))? base_reg : action);
                4'd6: _n_action[6] = (!in_valid2)? 8'd0 :((action == 3'd5 || (!_img_size && action == 3'd3))? base_reg : action);
                4'd7: _n_action[7] = (!in_valid2)? 8'd0 :((action == 3'd5 || (!_img_size && action == 3'd3))? base_reg : action);
                default: begin
                    for (i = 0; i < 8; i = i + 1) begin
                        _n_action[i] = _action[i];
                    end
                end
            endcase
        end
        S_CONTROL: begin
            if (shift) begin
                _n_action[6] = img_addr_base;
                _n_action[7] = img_addr_base;
                for (i = 0; i < 6; i = i + 1) begin
                    _n_action[i] = _action[i + 2];
                end
            end
            else begin
                _n_action[7] = img_addr_base;
                for (i = 0; i < 7; i = i + 1) begin
                    _n_action[i] = _action[i + 1];
                end
            end
        end
        default: begin
            for (i = 0; i < 8; i = i + 1) begin
                _n_action[i] = _action[i];
            end
        end
    endcase
end

always @(*) begin
    if (cs == S_CONTROL) begin
        case ({_action[0], _action[1]})
            {3'd4, 3'd4}: shift = 1;
            {3'd0, 3'd0}: shift = 1;
            {3'd1, 3'd1}: shift = 1;
            {3'd2, 3'd2}: shift = 1;
            default: shift = 0;
        endcase
    end
    else
        shift = 0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        flip <= 0;
    else begin
    case (cs)
        S_READ_IMG: flip <= 0;
        S_READ_ACTION: flip <= (in_valid2 && action == 3'd5)? ~flip : flip;// 0 : ((action == 3'd5)? ~flip : flip);
        S_OUTPUT: flip <= (ns != S_OUTPUT)? 0 : flip;
        default: flip <= flip;
    endcase
    end
end

always @(posedge clk) begin
    case (cs)
        S_READ_ACTION: neg_compute <= 1'd0;
        S_CONTROL: neg_compute <= _action[0] == 3'd4 && (_action[1] == 3'd3 || _action[1] == 3'd6 || _action[1] == 3'd7); 
        S_MAX_POOL, S_MEDIAN: neg_compute <= (compute_done)? 1'd0 : neg_compute;
        default: neg_compute <= neg_compute;
    endcase
end

//---------------------------//
//         Read Map          //
//---------------------------//
always @(posedge clk) begin
    read_cnt <= n_read_cnt;
    {data_out_ff[0], data_out_ff[1]} <= data_out;
end

always @(*) begin
    case (_img_size)
        2'd0: change_row = (read_cnt[1:0] == 2'd2) && !read_cnt[7];
        2'd1: change_row = (read_cnt[2:0] == 3'd6) && !read_cnt[7];
        //2'd2: change_row = read_cnt[3:0] == 4'd15;
        default: change_row = 0;
    endcase
end

always @(*) begin
    case (_img_size)
        2'd0: change_row_displace = 14;
        2'd1: change_row_displace = 10;
        //2'd2: change_row_displace = 2;
        default: change_row_displace = 2;
    endcase
end

assign read_cnt_inc = read_cnt + ((change_row)? change_row_displace : 2);

always @(*) begin
    case (cs)
        S_IDLE: n_read_cnt = 0;
        S_READ_IMG: n_read_cnt = (channel_cnt == 3'd2 && !img_mem_we)? read_cnt_inc : read_cnt;
        S_READ_ACTION: n_read_cnt = (ns == S_WAIT)? 0 : ((channel_cnt == 3'd2 && !img_mem_we)? read_cnt_inc : read_cnt);
        S_WAIT: n_read_cnt = 0;
        S_READ_MAP: n_read_cnt = (wait_flag)? 0 : read_cnt_inc;
        default: n_read_cnt = read_cnt;
    endcase
end

always @(*) begin
    case (orig_img_size)
        2'd0: pseudo_addr = {img_addr_offset[6:1], ((flip && img_mem_we)? ~img_addr_offset[0] : img_addr_offset[0])};
        2'd1: pseudo_addr = {img_addr_offset[6:2], ((flip && img_mem_we)? ~img_addr_offset[1:0] : img_addr_offset[1:0])};
        2'd2: pseudo_addr = {img_addr_offset[6:3], ((flip && img_mem_we)? ~img_addr_offset[2:0] : img_addr_offset[2:0])};
        default: pseudo_addr = img_addr_offset;
    endcase
end

always @(posedge clk) begin
    case (cs)
        // S_READ_IMG, S_READ_ACTION: {compute_reg[read_cnt], compute_reg[read_cnt + 1]} <= (channel_cnt == 3'd2 && !img_mem_we)? data_in : {compute_reg[read_cnt], compute_reg[read_cnt + 1]};
        S_READ_MAP: {compute_reg[read_cnt], compute_reg[read_cnt + 1]} <= (flip)? {data_out_ff[1], data_out_ff[0]} : {data_out_ff[0], data_out_ff[1]};
        S_CONTROL: begin
            if (_action[0] == 3'd4 && _action[1] != 3'd4) begin
                for (i = 0; i < 256; i = i + 1) begin
                    compute_reg[i] <= ~compute_reg[i];
                end
                //$display("neg once");
            end
        end
        S_MEDIAN: begin
            if (_img_size == 2'd0) begin
                for (i = 0; i < 3; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[3] <= out_reg[0];
                for (i = 16; i < 19; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[19] <= out_reg[1];
                for (i = 32; i < 35; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[35] <= out_reg[2];
                for (i = 48; i < 51; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[51] <= out_reg[3];
            end
            if (_img_size == 2'd1) begin
                for (i = 0; i < 7; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[7] <= out_reg[0];
                for (i = 16; i < 23; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[23] <= out_reg[1];
                for (i = 32; i < 39; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[39] <= out_reg[2];
                for (i = 48; i < 55; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[55] <= out_reg[3];
                for (i = 64; i < 71; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[71] <= out_reg[4];
                for (i = 80; i < 87; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[87] <= out_reg[5];
                for (i = 96; i < 103; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[103] <= out_reg[6];
                for (i = 112; i < 119; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[119] <= out_reg[7];
            end
            if (_img_size == 2'd2) begin
                for (i = 0; i < 15; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[15] <= out_reg[0];
                for (i = 16; i < 31; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[31] <= out_reg[1];
                for (i = 32; i < 47; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[47] <= out_reg[2];
                for (i = 48; i < 63; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[63] <= out_reg[3];
                for (i = 64; i < 79; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[79] <= out_reg[4];
                for (i = 80; i < 95; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[95] <= out_reg[5];
                for (i = 96; i < 111; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[111] <= out_reg[6];
                for (i = 112; i < 127; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[127] <= out_reg[7];
                for (i = 128; i < 143; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[143] <= out_reg[8];
                for (i = 144; i < 159; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[159] <= out_reg[9];
                for (i = 160; i < 175; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[175] <= out_reg[10];
                for (i = 176; i < 191; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[191] <= out_reg[11];
                for (i = 192; i < 207; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[207] <= out_reg[12];
                for (i = 208; i < 223; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[223] <= out_reg[13];
                for (i = 224; i < 239; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[239] <= out_reg[14];
                for (i = 240; i < 255; i = i + 1)
                    compute_reg[i] <= compute_reg[i + 1];
                compute_reg[255] <= out_reg[15];
            end
        end 
        S_MAX_POOL: begin
            if (_img_size) begin
                case (cal_cnt)
                    5'd1: begin
                        compute_reg[0] <= out_reg[0];
                        compute_reg[1] <= out_reg[1];
                        compute_reg[2] <= out_reg[2];
                        compute_reg[3] <= out_reg[3];
                        compute_reg[16] <= out_reg[4];
                        compute_reg[17] <= out_reg[5];
                        compute_reg[18] <= out_reg[6];
                        compute_reg[19] <= out_reg[7];
                        compute_reg[32] <= out_reg[8];
                        compute_reg[33] <= out_reg[9];
                        compute_reg[34] <= out_reg[10];
                        compute_reg[35] <= out_reg[11];
                        compute_reg[48] <= out_reg[12];
                        compute_reg[49] <= out_reg[13];
                        compute_reg[50] <= out_reg[14];
                        compute_reg[51] <= out_reg[15];
                    end
                    5'd2: begin
                        compute_reg[4] <= out_reg[0];
                        compute_reg[5] <= out_reg[1];
                        compute_reg[6] <= out_reg[2];
                        compute_reg[7] <= out_reg[3];
                        compute_reg[20] <= out_reg[4];
                        compute_reg[21] <= out_reg[5];
                        compute_reg[22] <= out_reg[6];
                        compute_reg[23] <= out_reg[7];
                        compute_reg[36] <= out_reg[8];
                        compute_reg[37] <= out_reg[9];
                        compute_reg[38] <= out_reg[10];
                        compute_reg[39] <= out_reg[11];
                        compute_reg[52] <= out_reg[12];
                        compute_reg[53] <= out_reg[13];
                        compute_reg[54] <= out_reg[14];
                        compute_reg[55] <= out_reg[15];
                    end
                    5'd3: begin
                        compute_reg[64] <= out_reg[0];
                        compute_reg[65] <= out_reg[1];
                        compute_reg[66] <= out_reg[2];
                        compute_reg[67] <= out_reg[3];
                        compute_reg[80] <= out_reg[4];
                        compute_reg[81] <= out_reg[5];
                        compute_reg[82] <= out_reg[6];
                        compute_reg[83] <= out_reg[7];
                        compute_reg[96] <= out_reg[8];
                        compute_reg[97] <= out_reg[9];
                        compute_reg[98] <= out_reg[10];
                        compute_reg[99] <= out_reg[11];
                        compute_reg[112] <= out_reg[12];
                        compute_reg[113] <= out_reg[13];
                        compute_reg[114] <= out_reg[14];
                        compute_reg[115] <= out_reg[15];
                    end
                    5'd4: begin
                        compute_reg[68] <= out_reg[0];
                        compute_reg[69] <= out_reg[1];
                        compute_reg[70] <= out_reg[2];
                        compute_reg[71] <= out_reg[3];
                        compute_reg[84] <= out_reg[4];
                        compute_reg[85] <= out_reg[5];
                        compute_reg[86] <= out_reg[6];
                        compute_reg[87] <= out_reg[7];
                        compute_reg[100] <= out_reg[8];
                        compute_reg[101] <= out_reg[9];
                        compute_reg[102] <= out_reg[10];
                        compute_reg[103] <= out_reg[11];
                        compute_reg[116] <= out_reg[12];
                        compute_reg[117] <= out_reg[13];
                        compute_reg[118] <= out_reg[14];
                        compute_reg[119] <= out_reg[15];
                    end
                    default: compute_reg[0] <= compute_reg[0];
                endcase
            end
            else begin
                if (cal_cnt == 5'd1) begin
                    compute_reg[0] <= out_reg[0];
                    compute_reg[1] <= out_reg[1];
                    compute_reg[2] <= out_reg[2];
                    compute_reg[3] <= out_reg[3];
                    compute_reg[16] <= out_reg[4];
                    compute_reg[17] <= out_reg[5];
                    compute_reg[18] <= out_reg[6];
                    compute_reg[19] <= out_reg[7];
                    compute_reg[32] <= out_reg[8];
                    compute_reg[33] <= out_reg[9];
                    compute_reg[34] <= out_reg[10];
                    compute_reg[35] <= out_reg[11];
                    compute_reg[48] <= out_reg[12];
                    compute_reg[49] <= out_reg[13];
                    compute_reg[50] <= out_reg[14];
                    compute_reg[51] <= out_reg[15];
                end
            end
        end
        default: compute_reg[0] <= compute_reg[0] ;
    endcase
end

always @(posedge clk) begin
    for (i = 0; i < 16; i = i + 1) begin
        shift_reg[i] <= compute_reg[i * 16];
    end
end
//---------------------------//
//          Compute          //
//---------------------------//
always @(posedge clk) begin
    cal_cnt <= (cs == S_MEDIAN || cs == S_MAX_POOL)? cal_cnt + 1 : 0;
end

always @(*) begin
    case (_img_size)
        2'd0: cal_cnt_bound = 3;
        2'd1: cal_cnt_bound = 7;
        2'd2: cal_cnt_bound = 15; 
        default: cal_cnt_bound = 3;
    endcase
end

assign first_col = !cal_cnt;
assign last_col = cal_cnt == cal_cnt_bound;

generate
genvar m;
for (m = 0; m < 16; m = m + 1) begin
    sort9_median med (A[m], B[m], C[m], D[m], E[m], F[m], G[m], H[m], I[m], out_wire[m]);
end
endgenerate

always @(posedge clk) begin
    for (i = 0; i < 16; i = i + 1) begin
        out_reg[i] <= out_wire[i];
    end
end

always @(*) begin
    if (cs == S_MEDIAN) begin
        A[0] = shift_reg[0];
        B[0] = shift_reg[0];
        C[0] = shift_reg[1];
        D[0] = compute_reg[0];
        E[0] = compute_reg[0];
        F[0] = compute_reg[16];
        G[0] = (last_col)? compute_reg[0] : compute_reg[1];
        H[0] = (last_col)? compute_reg[0] : compute_reg[1];
        I[0] = (last_col)? compute_reg[16] : compute_reg[17];
    end
    else begin
        E[0] = 0;
        F[0] = 255;
        G[0] = 255;
        H[0] = 255;
        I[0] = 255;
        case (cal_cnt)
            5'd0: begin
                A[0] = compute_reg[0];
                B[0] = compute_reg[1];
                C[0] = compute_reg[16];
                D[0] = compute_reg[17];
            end
            5'd1: begin
                A[0] = compute_reg[8];
                B[0] = compute_reg[9];
                C[0] = compute_reg[24];
                D[0] = compute_reg[25];
            end
            5'd2: begin
                A[0] = compute_reg[128];
                B[0] = compute_reg[129];
                C[0] = compute_reg[144];
                D[0] = compute_reg[145];
            end
            5'd3: begin
                A[0] = compute_reg[136];
                B[0] = compute_reg[137];
                C[0] = compute_reg[152];
                D[0] = compute_reg[153];
            end
            default: begin
                A[0] = 0;
                B[0] = 0;
                C[0] = 0;
                D[0] = 0;
            end 
        endcase
    end
end

always @(*) begin
    if (cs == S_MEDIAN) begin
        A[1] = shift_reg[0];
        B[1] = shift_reg[1];
        C[1] = shift_reg[2];
        D[1] = compute_reg[0];
        E[1] = compute_reg[16];
        F[1] = compute_reg[32];
        G[1] = (last_col)? compute_reg[0] : compute_reg[1];
        H[1] = (last_col)? compute_reg[16] : compute_reg[17];
        I[1] = (last_col)? compute_reg[32] : compute_reg[33];
    end
    else begin
        E[1] = 0;
        F[1] = 255;
        G[1] = 255;
        H[1] = 255;
        I[1] = 255;
        case (cal_cnt)
            5'd0: begin
                A[1] = compute_reg[2];
                B[1] = compute_reg[3];
                C[1] = compute_reg[18];
                D[1] = compute_reg[19];
            end
            5'd1: begin
                A[1] = compute_reg[10];
                B[1] = compute_reg[11];
                C[1] = compute_reg[26];
                D[1] = compute_reg[27];
            end
            5'd2: begin
                A[1] = compute_reg[130];
                B[1] = compute_reg[131];
                C[1] = compute_reg[146];
                D[1] = compute_reg[147];
            end
            5'd3: begin
                A[1] = compute_reg[138];
                B[1] = compute_reg[139];
                C[1] = compute_reg[154];
                D[1] = compute_reg[155];
            end
            default: begin
                A[1] = 0;
                B[1] = 0;
                C[1] = 0;
                D[1] = 0;
            end 
        endcase
    end
end

always @(*) begin
    if (cs == S_MEDIAN) begin
        A[2] = shift_reg[1];
        B[2] = shift_reg[2];
        C[2] = shift_reg[3];
        D[2] = compute_reg[16];
        E[2] = compute_reg[32];
        F[2] = compute_reg[48];
        G[2] = (last_col)? compute_reg[16] : compute_reg[17];
        H[2] = (last_col)? compute_reg[32] : compute_reg[33];
        I[2] = (last_col)? compute_reg[48] : compute_reg[49];
    end
    else begin
        E[2] = 0;
        F[2] = 255;
        G[2] = 255;
        H[2] = 255;
        I[2] = 255;
        case (cal_cnt)
            5'd0: begin
                A[2] = compute_reg[4];
                B[2] = compute_reg[5];
                C[2] = compute_reg[20];
                D[2] = compute_reg[21];
            end
            5'd1: begin
                A[2] = compute_reg[12];
                B[2] = compute_reg[13];
                C[2] = compute_reg[28];
                D[2] = compute_reg[29];
            end
            5'd2: begin
                A[2] = compute_reg[132];
                B[2] = compute_reg[133];
                C[2] = compute_reg[148];
                D[2] = compute_reg[149];
            end
            5'd3: begin
                A[2] = compute_reg[140];
                B[2] = compute_reg[141];
                C[2] = compute_reg[156];
                D[2] = compute_reg[157];
            end
            default: begin
                A[2] = 0;
                B[2] = 0;
                C[2] = 0;
                D[2] = 0;
            end 
        endcase
    end
end

always @(*) begin
    if (cs == S_MEDIAN) begin
        A[3] = shift_reg[2];
        B[3] = shift_reg[3];
        C[3] = (_img_size == 2'd0)? shift_reg[3] : shift_reg[4];
        D[3] = compute_reg[32];
        E[3] = compute_reg[48];
        F[3] = (_img_size == 2'd0)? compute_reg[48] : compute_reg[64];
        G[3] = (last_col)? compute_reg[32] : compute_reg[33];
        H[3] = (last_col)? compute_reg[48] : compute_reg[49];
        if (_img_size == 2'd0)
            I[3] = (last_col)? compute_reg[48] : compute_reg[49];
        else
            I[3] = (last_col)? compute_reg[64] : compute_reg[65];
    end
    else begin
        E[3] = 0;
        F[3] = 255;
        G[3] = 255;
        H[3] = 255;
        I[3] = 255;
        case (cal_cnt)
            5'd0: begin
                A[3] = compute_reg[6];
                B[3] = compute_reg[7];
                C[3] = compute_reg[22];
                D[3] = compute_reg[23];
            end
            5'd1: begin
                A[3] = compute_reg[14];
                B[3] = compute_reg[15];
                C[3] = compute_reg[30];
                D[3] = compute_reg[31];
            end
            5'd2: begin
                A[3] = compute_reg[134];
                B[3] = compute_reg[135];
                C[3] = compute_reg[150];
                D[3] = compute_reg[151];
            end
            5'd3: begin
                A[3] = compute_reg[142];
                B[3] = compute_reg[143];
                C[3] = compute_reg[158];
                D[3] = compute_reg[159];
            end
            default: begin
                A[3] = 0;
                B[3] = 0;
                C[3] = 0;
                D[3] = 0;
            end 
        endcase
    end
end

always @(*) begin
    if (cs == S_MEDIAN) begin
        A[4] = shift_reg[3];
        B[4] = shift_reg[4];
        C[4] = shift_reg[5];
        D[4] = compute_reg[48];
        E[4] = compute_reg[64];
        F[4] = compute_reg[80];
        G[4] = (last_col)? compute_reg[48] : compute_reg[49];
        H[4] = (last_col)? compute_reg[64] : compute_reg[65];
        I[4] = (last_col)? compute_reg[80] : compute_reg[81];
    end
    else begin
        E[4] = 0;
        F[4] = 255;
        G[4] = 255;
        H[4] = 255;
        I[4] = 255;
        case (cal_cnt)
            5'd0: begin
                A[4] = compute_reg[32];
                B[4] = compute_reg[33];
                C[4] = compute_reg[48];
                D[4] = compute_reg[49];
            end
            5'd1: begin
                A[4] = compute_reg[40];
                B[4] = compute_reg[41];
                C[4] = compute_reg[56];
                D[4] = compute_reg[57];
            end
            5'd2: begin
                A[4] = compute_reg[160];
                B[4] = compute_reg[161];
                C[4] = compute_reg[176];
                D[4] = compute_reg[177];
            end
            5'd3: begin
                A[4] = compute_reg[168];
                B[4] = compute_reg[169];
                C[4] = compute_reg[184];
                D[4] = compute_reg[185];
            end
            default: begin
                A[4] = 0;
                B[4] = 0;
                C[4] = 0;
                D[4] = 0;
            end 
        endcase
    end
end

always @(*) begin
    if (cs == S_MEDIAN) begin
        A[5] = shift_reg[4];
        B[5] = shift_reg[5];
        C[5] = shift_reg[6];
        D[5] = compute_reg[64];
        E[5] = compute_reg[80];
        F[5] = compute_reg[96];
        G[5] = (last_col)? compute_reg[64] : compute_reg[65];
        H[5] = (last_col)? compute_reg[80] : compute_reg[81];
        I[5] = (last_col)? compute_reg[96] : compute_reg[97];
    end
    else begin
        E[5] = 0;
        F[5] = 255;
        G[5] = 255;
        H[5] = 255;
        I[5] = 255;
        case (cal_cnt)
            5'd0: begin
                A[5] = compute_reg[34];
                B[5] = compute_reg[35];
                C[5] = compute_reg[50];
                D[5] = compute_reg[51];
            end
            5'd1: begin
                A[5] = compute_reg[42];
                B[5] = compute_reg[43];
                C[5] = compute_reg[58];
                D[5] = compute_reg[59];
            end
            5'd2: begin
                A[5] = compute_reg[162];
                B[5] = compute_reg[163];
                C[5] = compute_reg[178];
                D[5] = compute_reg[179];
            end
            5'd3: begin
                A[5] = compute_reg[170];
                B[5] = compute_reg[171];
                C[5] = compute_reg[186];
                D[5] = compute_reg[187];
            end
            default: begin
                A[5] = 0;
                B[5] = 0;
                C[5] = 0;
                D[5] = 0;
            end 
        endcase
    end
end

always @(*) begin
    if (cs == S_MEDIAN) begin
        A[6] = shift_reg[5];
        B[6] = shift_reg[6];
        C[6] = shift_reg[7];
        D[6] = compute_reg[80];
        E[6] = compute_reg[96];
        F[6] = compute_reg[112];
        G[6] = (last_col)? compute_reg[80] : compute_reg[81];
        H[6] = (last_col)? compute_reg[96] : compute_reg[97];
        I[6] = (last_col)? compute_reg[112] : compute_reg[113];
    end
    else begin
        E[6] = 0;
        F[6] = 255;
        G[6] = 255;
        H[6] = 255;
        I[6] = 255;
        case (cal_cnt)
            5'd0: begin
                A[6] = compute_reg[36];
                B[6] = compute_reg[37];
                C[6] = compute_reg[52];
                D[6] = compute_reg[53];
            end
            5'd1: begin
                A[6] = compute_reg[44];
                B[6] = compute_reg[45];
                C[6] = compute_reg[60];
                D[6] = compute_reg[61];
            end
            5'd2: begin
                A[6] = compute_reg[164];
                B[6] = compute_reg[165];
                C[6] = compute_reg[180];
                D[6] = compute_reg[181];
            end
            5'd3: begin
                A[6] = compute_reg[172];
                B[6] = compute_reg[173];
                C[6] = compute_reg[188];
                D[6] = compute_reg[189];
            end
            default: begin
                A[6] = 0;
                B[6] = 0;
                C[6] = 0;
                D[6] = 0;
            end 
        endcase
    end
end

always @(*) begin
    if (cs == S_MEDIAN) begin
        A[7] = shift_reg[6];
        B[7] = shift_reg[7];
        C[7] = (_img_size == 2'd1)? shift_reg[7] : shift_reg[8];
        D[7] = compute_reg[96];
        E[7] = compute_reg[112];
        F[7] = (_img_size == 2'd1)? compute_reg[112] : compute_reg[128];
        G[7] = (last_col)? compute_reg[96] : compute_reg[97];
        H[7] = (last_col)? compute_reg[112] : compute_reg[113];
        if (_img_size == 2'd1) 
            I[7] = (last_col)? compute_reg[112] : compute_reg[113];
        else
            I[7] = (last_col)? compute_reg[128] : compute_reg[129];
    end
    else begin
        E[7] = 0;
        F[7] = 255;
        G[7] = 255;
        H[7] = 255;
        I[7] = 255;
        case (cal_cnt)
            5'd0: begin
                A[7] = compute_reg[38];
                B[7] = compute_reg[39];
                C[7] = compute_reg[54];
                D[7] = compute_reg[55];
            end
            5'd1: begin
                A[7] = compute_reg[46];
                B[7] = compute_reg[47];
                C[7] = compute_reg[62];
                D[7] = compute_reg[63];
            end
            5'd2: begin
                A[7] = compute_reg[166];
                B[7] = compute_reg[167];
                C[7] = compute_reg[182];
                D[7] = compute_reg[183];
            end
            5'd3: begin
                A[7] = compute_reg[174];
                B[7] = compute_reg[175];
                C[7] = compute_reg[190];
                D[7] = compute_reg[191];
            end
            default: begin
                A[7] = 0;
                B[7] = 0;
                C[7] = 0;
                D[7] = 0;
            end 
        endcase
    end
end

always @(*) begin
    if (cs == S_MEDIAN) begin
        A[8] = shift_reg[7];
        B[8] = shift_reg[8];
        C[8] = shift_reg[9];
        D[8] = compute_reg[112];
        E[8] = compute_reg[128];
        F[8] = compute_reg[144];
        G[8] = (last_col)? compute_reg[112] : compute_reg[113];
        H[8] = (last_col)? compute_reg[128] : compute_reg[129];
        I[8] = (last_col)? compute_reg[144] : compute_reg[145];
    end
    else begin
        E[8] = 0;
        F[8] = 255;
        G[8] = 255;
        H[8] = 255;
        I[8] = 255;
        case (cal_cnt)
            5'd0: begin
                A[8] = compute_reg[64];
                B[8] = compute_reg[65];
                C[8] = compute_reg[80];
                D[8] = compute_reg[81];
            end
            5'd1: begin
                A[8] = compute_reg[72];
                B[8] = compute_reg[73];
                C[8] = compute_reg[88];
                D[8] = compute_reg[89];
            end
            5'd2: begin
                A[8] = compute_reg[192];
                B[8] = compute_reg[193];
                C[8] = compute_reg[208];
                D[8] = compute_reg[209];
            end
            5'd3: begin
                A[8] = compute_reg[200];
                B[8] = compute_reg[201];
                C[8] = compute_reg[216];
                D[8] = compute_reg[217];
            end
            default: begin
                A[8] = 0;
                B[8] = 0;
                C[8] = 0;
                D[8] = 0;
            end 
        endcase
    end
end

always @(*) begin
    if (cs == S_MEDIAN) begin
        A[9] = shift_reg[8];
        B[9] = shift_reg[9];
        C[9] = shift_reg[10];
        D[9] = compute_reg[128];
        E[9] = compute_reg[144];
        F[9] = compute_reg[160];
        G[9] = (last_col)? compute_reg[128] : compute_reg[129];
        H[9] = (last_col)? compute_reg[144] : compute_reg[145];
        I[9] = (last_col)? compute_reg[160] : compute_reg[161];
    end
    else begin
        E[9] = 0;
        F[9] = 255;
        G[9] = 255;
        H[9] = 255;
        I[9] = 255;
        case (cal_cnt)
            5'd0: begin
                A[9] = compute_reg[66];
                B[9] = compute_reg[67];
                C[9] = compute_reg[82];
                D[9] = compute_reg[83];
            end
            5'd1: begin
                A[9] = compute_reg[74];
                B[9] = compute_reg[75];
                C[9] = compute_reg[90];
                D[9] = compute_reg[91];
            end
            5'd2: begin
                A[9] = compute_reg[194];
                B[9] = compute_reg[195];
                C[9] = compute_reg[210];
                D[9] = compute_reg[211];
            end
            5'd3: begin
                A[9] = compute_reg[202];
                B[9] = compute_reg[203];
                C[9] = compute_reg[218];
                D[9] = compute_reg[219];
            end
            default: begin
                A[9] = 0;
                B[9] = 0;
                C[9] = 0;
                D[9] = 0;
            end 
        endcase
    end
end

always @(*) begin
    if (cs == S_MEDIAN) begin
        A[10] = shift_reg[9];
        B[10] = shift_reg[10];
        C[10] = shift_reg[11];
        D[10] = compute_reg[144];
        E[10] = compute_reg[160];
        F[10] = compute_reg[176];
        G[10] = (last_col)? compute_reg[144] : compute_reg[145];
        H[10] = (last_col)? compute_reg[160] : compute_reg[161];
        I[10] = (last_col)? compute_reg[176] : compute_reg[177];
    end
    else begin
        E[10] = 0;
        F[10] = 255;
        G[10] = 255;
        H[10] = 255;
        I[10] = 255;
        case (cal_cnt)
            5'd0: begin
                A[10] = compute_reg[68];
                B[10] = compute_reg[69];
                C[10] = compute_reg[84];
                D[10] = compute_reg[85];
            end
            5'd1: begin
                A[10] = compute_reg[76];
                B[10] = compute_reg[77];
                C[10] = compute_reg[92];
                D[10] = compute_reg[93];
            end
            5'd2: begin
                A[10] = compute_reg[196];
                B[10] = compute_reg[197];
                C[10] = compute_reg[212];
                D[10] = compute_reg[213];
            end
            5'd3: begin
                A[10] = compute_reg[204];
                B[10] = compute_reg[205];
                C[10] = compute_reg[220];
                D[10] = compute_reg[221];
            end
            default: begin
                A[10] = 0;
                B[10] = 0;
                C[10] = 0;
                D[10] = 0;
            end 
        endcase
    end
end

always @(*) begin
    if (cs == S_MEDIAN) begin
        A[11] = shift_reg[10];
        B[11] = shift_reg[11];
        C[11] = shift_reg[12];
        D[11] = compute_reg[160];
        E[11] = compute_reg[176];
        F[11] = compute_reg[192];
        G[11] = (last_col)? compute_reg[160] : compute_reg[161];
        H[11] = (last_col)? compute_reg[176] : compute_reg[177];
        I[11] = (last_col)? compute_reg[192] : compute_reg[193];
    end
    else begin
        E[11] = 0;
        F[11] = 255;
        G[11] = 255;
        H[11] = 255;
        I[11] = 255;
        case (cal_cnt)
            5'd0: begin
                A[11] = compute_reg[70];
                B[11] = compute_reg[71];
                C[11] = compute_reg[86];
                D[11] = compute_reg[87];
            end
            5'd1: begin
                A[11] = compute_reg[78];
                B[11] = compute_reg[79];
                C[11] = compute_reg[94];
                D[11] = compute_reg[95];
            end
            5'd2: begin
                A[11] = compute_reg[198];
                B[11] = compute_reg[199];
                C[11] = compute_reg[214];
                D[11] = compute_reg[215];
            end
            5'd3: begin
                A[11] = compute_reg[206];
                B[11] = compute_reg[207];
                C[11] = compute_reg[222];
                D[11] = compute_reg[223];
            end
            default: begin
                A[11] = 0;
                B[11] = 0;
                C[11] = 0;
                D[11] = 0;
            end 
        endcase
    end
end

always @(*) begin
    if (cs == S_MEDIAN) begin
        A[12] = shift_reg[11];
        B[12] = shift_reg[12];
        C[12] = shift_reg[13];
        D[12] = compute_reg[176];
        E[12] = compute_reg[192];
        F[12] = compute_reg[208];
        G[12] = (last_col)? compute_reg[176] : compute_reg[177];
        H[12] = (last_col)? compute_reg[192] : compute_reg[193];
        I[12] = (last_col)? compute_reg[208] : compute_reg[209];
    end
    else begin
        E[12] = 0;
        F[12] = 255;
        G[12] = 255;
        H[12] = 255;
        I[12] = 255;
        case (cal_cnt)
            5'd0: begin
                A[12] = compute_reg[96];
                B[12] = compute_reg[97];
                C[12] = compute_reg[112];
                D[12] = compute_reg[113];
            end
            5'd1: begin
                A[12] = compute_reg[104];
                B[12] = compute_reg[105];
                C[12] = compute_reg[120];
                D[12] = compute_reg[121];
            end
            5'd2: begin
                A[12] = compute_reg[224];
                B[12] = compute_reg[225];
                C[12] = compute_reg[240];
                D[12] = compute_reg[241];
            end
            5'd3: begin
                A[12] = compute_reg[232];
                B[12] = compute_reg[233];
                C[12] = compute_reg[248];
                D[12] = compute_reg[249];
            end
            default: begin
                A[12] = 0;
                B[12] = 0;
                C[12] = 0;
                D[12] = 0;
            end 
        endcase
    end
end

always @(*) begin
    if (cs == S_MEDIAN) begin
        A[13] = shift_reg[12];
        B[13] = shift_reg[13];
        C[13] = shift_reg[14];
        D[13] = compute_reg[192];
        E[13] = compute_reg[208];
        F[13] = compute_reg[224];
        G[13] = (last_col)? compute_reg[192] : compute_reg[193];
        H[13] = (last_col)? compute_reg[208] : compute_reg[209];
        I[13] = (last_col)? compute_reg[224] : compute_reg[225];
    end
    else begin
        E[13] = 0;
        F[13] = 255;
        G[13] = 255;
        H[13] = 255;
        I[13] = 255;
        case (cal_cnt)
            5'd0: begin
                A[13] = compute_reg[98];
                B[13] = compute_reg[99];
                C[13] = compute_reg[114];
                D[13] = compute_reg[115];
            end
            5'd1: begin
                A[13] = compute_reg[106];
                B[13] = compute_reg[107];
                C[13] = compute_reg[122];
                D[13] = compute_reg[123];
            end
            5'd2: begin
                A[13] = compute_reg[226];
                B[13] = compute_reg[227];
                C[13] = compute_reg[242];
                D[13] = compute_reg[243];
            end
            5'd3: begin
                A[13] = compute_reg[234];
                B[13] = compute_reg[235];
                C[13] = compute_reg[250];
                D[13] = compute_reg[251];
            end
            default: begin
                A[13] = 0;
                B[13] = 0;
                C[13] = 0;
                D[13] = 0;
            end 
        endcase
    end
end

always @(*) begin
    if (cs == S_MEDIAN) begin
        A[14] = shift_reg[13];
        B[14] = shift_reg[14];
        C[14] = shift_reg[15];
        D[14] = compute_reg[208];
        E[14] = compute_reg[224];
        F[14] = compute_reg[240];
        G[14] = (last_col)? compute_reg[208] : compute_reg[209];
        H[14] = (last_col)? compute_reg[224] : compute_reg[225];
        I[14] = (last_col)? compute_reg[240] : compute_reg[241];
    end
    else begin
        E[14] = 0;
        F[14] = 255;
        G[14] = 255;
        H[14] = 255;
        I[14] = 255;
        case (cal_cnt)
            5'd0: begin
                A[14] = compute_reg[100];
                B[14] = compute_reg[101];
                C[14] = compute_reg[116];
                D[14] = compute_reg[117];
            end
            5'd1: begin
                A[14] = compute_reg[108];
                B[14] = compute_reg[109];
                C[14] = compute_reg[124];
                D[14] = compute_reg[125];
            end
            5'd2: begin
                A[14] = compute_reg[228];
                B[14] = compute_reg[229];
                C[14] = compute_reg[244];
                D[14] = compute_reg[245];
            end
            5'd3: begin
                A[14] = compute_reg[236];
                B[14] = compute_reg[237];
                C[14] = compute_reg[252];
                D[14] = compute_reg[253];
            end
            default: begin
                A[14] = 0;
                B[14] = 0;
                C[14] = 0;
                D[14] = 0;
            end 
        endcase
    end
end

always @(*) begin
    if (cs == S_MEDIAN) begin
        A[15] = shift_reg[14];
        B[15] = shift_reg[15];
        C[15] = shift_reg[15];
        D[15] = compute_reg[224];
        E[15] = compute_reg[240];
        F[15] = compute_reg[240];
        G[15] = (last_col)? compute_reg[224] : compute_reg[225];
        H[15] = (last_col)? compute_reg[240] : compute_reg[241];
        I[15] = (last_col)? compute_reg[240] : compute_reg[241];
    end
    else begin
        E[15] = 0;
        F[15] = 255;
        G[15] = 255;
        H[15] = 255;
        I[15] = 255;
        case (cal_cnt)
            5'd0: begin
                A[15] = compute_reg[102];
                B[15] = compute_reg[103];
                C[15] = compute_reg[118];
                D[15] = compute_reg[119];
            end
            5'd1: begin
                A[15] = compute_reg[110];
                B[15] = compute_reg[111];
                C[15] = compute_reg[126];
                D[15] = compute_reg[127];
            end
            5'd2: begin
                A[15] = compute_reg[230];
                B[15] = compute_reg[231];
                C[15] = compute_reg[246];
                D[15] = compute_reg[247];
            end
            5'd3: begin
                A[15] = compute_reg[238];
                B[15] = compute_reg[239];
                C[15] = compute_reg[254];
                D[15] = compute_reg[255];
            end
            default: begin
                A[15] = 0;
                B[15] = 0;
                C[15] = 0;
                D[15] = 0;
            end 
        endcase
    end
end

always @(*) begin
    mulb = template_reg[mul_cnt];
end

always @(*) begin
    cal_first_col = mul_addr[3:0] == 4'd0;
    cal_last_col = mul_addr[3:0] == cal_cnt_bound;
    cal_first_row = mul_addr[7:4] == 4'd0;
    cal_last_row = mul_addr[7:4] == cal_cnt_bound;
end

always @(*) begin
    case (_img_size)
        2'd0: mul_addr_bound = 51; 
        2'd1: mul_addr_bound = 119; 
        2'd2: mul_addr_bound = 255; 
        default: mul_addr_bound = 15; 
    endcase
end

reg [3:0] mul_addr_change_row_offset;
always @(*) begin
    case (_img_size)
        2'd0: mul_addr_change_row_offset = 4'd13;
        2'd1: mul_addr_change_row_offset = 4'd9;
        2'd2: mul_addr_change_row_offset = 4'd1;
        default: mul_addr_change_row_offset = 4'd1;
    endcase
end

always @(posedge clk) begin
    if (cs == S_OUTPUT) begin
        mul_addr <= (out_cnt == 9)? mul_addr + ((mul_addr[3:0] == cal_cnt_bound)? mul_addr_change_row_offset : 4'd1)
                    : mul_addr;
    end
    else
        mul_addr <= 0;
end

always @(*)
    mul_result = mula * mulb;

always @(*) begin
    if (cs == S_OUTPUT) begin
        case (mul_cnt)
            4'd0: begin
                mula = (cal_first_col || cal_first_row)? 0 : compute_reg[mul_addr - 17];
            end 
            4'd1: begin
                if (cal_first_row)
                    mula = 0;
                else
                    mula = compute_reg[mul_addr - 16];
            end
            4'd2: begin
                mula = (cal_last_col || cal_first_row)? 0 : compute_reg[mul_addr - 15];
            end
            4'd3: begin
                if (cal_first_col)
                    mula = 0;
                else
                    mula = compute_reg[mul_addr - 1];
            end
            4'd4: begin
                mula = compute_reg[mul_addr];
            end
            4'd5: begin
                if (cal_last_col)
                    mula = 0;
                else
                    mula = compute_reg[mul_addr + 1];
            end
            4'd6: begin
                mula = (cal_first_col || cal_last_row)? 0 : compute_reg[mul_addr + 15];
            end
            4'd7: begin
                if (cal_last_row)
                    mula = 0;
                else
                    mula = compute_reg[mul_addr + 16];
            end
            4'd8: begin
                mula = (cal_last_col || cal_last_row)? 0 : compute_reg[mul_addr + 17];
            end
            default: mula = 0;
        endcase
    end
    else
        mula = 0;
end

reg [19:0] output_reg;
reg [19:0] out_result;
reg cal_flag;

always @(posedge clk) begin
    if (cs == S_OUTPUT && cal_flag) begin
        output_reg <= (!mul_cnt)? mul_result : output_reg + mul_result;
    end
    else
        output_reg <= output_reg;
end

always @(posedge clk) begin
    out_result <= (out_cnt == 19)? output_reg : out_result;
end

always @(posedge clk) begin
    if (cs == S_OUTPUT && cal_flag) begin
        mul_cnt <= (mul_cnt == 4'd8)? 0 : mul_cnt + 1;
    end
    else
        mul_cnt <= 0;
end

always @(posedge clk) begin
    if (!out_valid) begin
        cal_flag <= 1'd1;
    end
    else begin
        cal_flag <= out_cnt >= 9;
    end
end

always @(posedge clk) begin
    if (out_cnt_valid) begin
        out_cnt <= (out_cnt == 5'd19)? 0 : out_cnt + 1;
    end
    else
        out_cnt <= 5'd19;
end

wire out_valid_flag;


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 1'd0;
        out_cnt_valid <= 1'd0;
        set_num <= 3'd0;
    end
    else begin
        out_cnt_valid <= (cs == S_OUTPUT && mul_cnt == 4'd8)? 1'd1 : out_cnt_valid;
        if (cs == S_OUTPUT && ns != S_OUTPUT) begin
            set_num <= set_num + 1;
        end
        if (cs == S_READ_ACTION)
            out_cnt_valid <= 1'd0;
        // if(!img_mem_we)
        //     $display("cs = %d, channel_cnt = %d, data_in = %d, %d, offset = %d, pseudo_offset = %d, flip = %d", cs , channel_cnt, data_in[15:8], data_in[7:0], img_addr_offset, pseudo_addr, flip);
        // if (cs == S_MAX_POOL || cs == S_MEDIAN) begin
        //     $display("cs = %d, cal_cnt = %d, out = %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d", cs , cal_cnt, out_wire[0], out_wire[1], out_wire[2], out_wire[3],
        //     out_wire[4], out_wire[5], out_wire[6], out_wire[7], out_wire[8], out_wire[9], out_wire[10], out_wire[11], out_wire[12], out_wire[13],
        //     out_wire[14], out_wire[15]);
        //     // $display("cal_cnt = %d, out_reg = %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d", cal_cnt, out_reg[0], out_reg[1], out_reg[2], out_reg[3],
        //     // out_reg[4], out_reg[5], out_reg[6], out_reg[7], out_reg[8], out_reg[9], out_reg[10], out_reg[11], out_reg[12], out_reg[13],
        //     // out_reg[14], out_reg[15]);
        // end
        // if (in_valid)
        //     $display("image = %d, q = %d, r = %d,   ans is %d, %d", image, q, r, image / 3, image %3);
        // if (cs == S_READ_MAP) begin
        //     $display("img_mem_we = %d, read_cnt = %d, img_addr = %d, data_out_ff %d, %d", img_mem_we, read_cnt, img_addr, data_out_ff[0], data_out_ff[1]);
        // end
        // if (((mul_addr > mul_addr_bound) || !mul_addr) && out_cnt == 19) begin
        //     out_valid <= 1'd0;
        // end
        // else begin
        //     out_valid <= (out_cnt_valid)? 1'd1 : out_valid;
        // end
        if (cs == S_OUTPUT) begin
            out_valid <= (out_cnt_valid)? 1'd1 : out_valid;
        end
        else
            out_valid <= 1'd0;
    end
end

assign out_value = (out_valid)? out_result[19 - out_cnt] : 1'd0;

endmodule

module div3 (
    input [7:0] dividend, 
    output reg [6:0] q, 
    output reg [1:0] r
);
reg [7:0] t1;
reg [6:0] t2;
reg [5:0] t3;
reg [4:0] t4;
reg [3:0] t5;
reg [2:0] t6;
reg [1:0] t7;

always @(*) begin
    {q[6], t1} = (dividend[7] && dividend[6])? {3'd4, dividend[5:0]} : {1'd0, dividend[7:0]};
    {q[5], t2} = (t1[7] || (t1[6] && t1[5]))? {1'd1, t1[7] && t1[5], ~t1[5], t1[4:0]} : {1'd0, t1[6:0]};
    {q[4], t3} = (t2[6] || (t2[5] && t2[4]))? {1'd1, t2[6] && t2[4], ~t2[4], t2[3:0]} : {1'd0, t2[5:0]};
    {q[3], t4} = (t3[5] || (t3[4] && t3[3]))? {1'd1, t3[5] && t3[3], ~t3[3], t3[2:0]} : {1'd0, t3[4:0]};
    {q[2], t5} = (t4[4] || (t4[3] && t4[2]))? {1'd1, t4[4] && t4[2], ~t4[2], t4[1:0]} : {1'd0, t4[3:0]};
    {q[1], t6} = (t5[3] || (t5[2] && t5[1]))? {1'd1, t5[3] && t5[1], ~t5[1], t5[0]} : {1'd0, t5[2:0]};
    {q[0], r} = (t6[2] || (t6[1] && t6[0]))? {1'd1, t6[2] && t6[0], ~t6[0]} : {1'd0, t6[1:0]};
end

endmodule

module sort9_median (
    a, b, c, d, e, f, g, h, i, out
);
    input [7:0] a, b, c, d, e, f, g, h, i;
    output [7:0] out;

    wire [7:0] t10, t11, t12, t13, t14, t15, t17, t18;
    wire [7:0] t20, t22, t23, t24, t25, t26, t27, t28;
    wire [7:0] t30, t31, t32, t33, t34, t35, t37, t38;
    wire [7:0] t41, t43, t44, t45, t46, t47;
    wire [7:0] t52, t53, t54, t55;
    wire [7:0] t62, t63, t64, t65;

    assign {t10, t13} = (a >= d)? {a, d} : {d, a};
    assign {t11, t17} = (b >= h)? {b, h} : {h, b};
    assign {t12, t15} = (c >= f)? {c, f} : {f, c};
    assign {t14, t18} = (e >= i)? {e, i} : {i, e};
    
    assign {t20, t27} = (t10 >= t17)? {t10, t17} : {t17, t10};
    assign {t22, t24} = (t12 >= t14)? {t12, t14} : {t14, t12};
    assign {t23, t28} = (t13 >= t18)? {t13, t18} : {t18, t13};
    assign {t25, t26} = (t15 >= g)? {t15, g} : {g, t15};

    assign {t30, t32} = (t20 >= t22)? {t20, t22} : {t22, t20};
    assign {t31, t33} = (t11 >= t23)? {t11, t23} : {t23, t11};
    assign {t34, t35} = (t24 >= t25)? {t24, t25} : {t25, t24};
    assign {t37, t38} = (t27 >= t28)? {t27, t28} : {t28, t27};
    
    assign {t41, t44} = (t31 >= t34)? {t31, t34} : {t34, t31};
    assign {t43, t46} = (t33 >= t26)? {t33, t26} : {t26, t33};
    assign {t45, t47} = (t35 >= t37)? {t35, t37} : {t37, t35};

    assign {t52, t54} = (t32 >= t44)? {t32, t44} : {t44, t32};
    assign {t53, t55} = (t43 >= t45)? {t43, t45} : {t45, t43};

    assign {t62, t63} = (t52 >= t53)? {t52, t53} : {t53, t52};
    assign {t64, t65} = (t54 >= t55)? {t54, t55} : {t55, t54};

    assign out = (t63 >= t64)? t64 : t63; 
endmodule

module div3_LUT (input [7:0] a, output reg [6:0] p,output reg [1:0] q);
    always@(*) begin
        case(a)
            8'd0: {p, q} = {7'd0, 2'd0};
            8'd1: {p, q} = {7'd0, 2'd1};
            8'd2: {p, q} = {7'd0, 2'd2};
            8'd3: {p, q} = {7'd1, 2'd0};
            8'd4: {p, q} = {7'd1, 2'd1};
            8'd5: {p, q} = {7'd1, 2'd2};
            8'd6: {p, q} = {7'd2, 2'd0};
            8'd7: {p, q} = {7'd2, 2'd1};
            8'd8: {p, q} = {7'd2, 2'd2};
            8'd9: {p, q} = {7'd3, 2'd0};
            8'd10: {p, q} = {7'd3, 2'd1};
            8'd11: {p, q} = {7'd3, 2'd2};
            8'd12: {p, q} = {7'd4, 2'd0};
            8'd13: {p, q} = {7'd4, 2'd1};
            8'd14: {p, q} = {7'd4, 2'd2};
            8'd15: {p, q} = {7'd5, 2'd0};
            8'd16: {p, q} = {7'd5, 2'd1};
            8'd17: {p, q} = {7'd5, 2'd2};
            8'd18: {p, q} = {7'd6, 2'd0};
            8'd19: {p, q} = {7'd6, 2'd1};
            8'd20: {p, q} = {7'd6, 2'd2};
            8'd21: {p, q} = {7'd7, 2'd0};
            8'd22: {p, q} = {7'd7, 2'd1};
            8'd23: {p, q} = {7'd7, 2'd2};
            8'd24: {p, q} = {7'd8, 2'd0};
            8'd25: {p, q} = {7'd8, 2'd1};
            8'd26: {p, q} = {7'd8, 2'd2};
            8'd27: {p, q} = {7'd9, 2'd0};
            8'd28: {p, q} = {7'd9, 2'd1};
            8'd29: {p, q} = {7'd9, 2'd2};
            8'd30: {p, q} = {7'd10, 2'd0};
            8'd31: {p, q} = {7'd10, 2'd1};
            8'd32: {p, q} = {7'd10, 2'd2};
            8'd33: {p, q} = {7'd11, 2'd0};
            8'd34: {p, q} = {7'd11, 2'd1};
            8'd35: {p, q} = {7'd11, 2'd2};
            8'd36: {p, q} = {7'd12, 2'd0};
            8'd37: {p, q} = {7'd12, 2'd1};
            8'd38: {p, q} = {7'd12, 2'd2};
            8'd39: {p, q} = {7'd13, 2'd0};
            8'd40: {p, q} = {7'd13, 2'd1};
            8'd41: {p, q} = {7'd13, 2'd2};
            8'd42: {p, q} = {7'd14, 2'd0};
            8'd43: {p, q} = {7'd14, 2'd1};
            8'd44: {p, q} = {7'd14, 2'd2};
            8'd45: {p, q} = {7'd15, 2'd0};
            8'd46: {p, q} = {7'd15, 2'd1};
            8'd47: {p, q} = {7'd15, 2'd2};
            8'd48: {p, q} = {7'd16, 2'd0};
            8'd49: {p, q} = {7'd16, 2'd1};
            8'd50: {p, q} = {7'd16, 2'd2};
            8'd51: {p, q} = {7'd17, 2'd0};
            8'd52: {p, q} = {7'd17, 2'd1};
            8'd53: {p, q} = {7'd17, 2'd2};
            8'd54: {p, q} = {7'd18, 2'd0};
            8'd55: {p, q} = {7'd18, 2'd1};
            8'd56: {p, q} = {7'd18, 2'd2};
            8'd57: {p, q} = {7'd19, 2'd0};
            8'd58: {p, q} = {7'd19, 2'd1};
            8'd59: {p, q} = {7'd19, 2'd2};
            8'd60: {p, q} = {7'd20, 2'd0};
            8'd61: {p, q} = {7'd20, 2'd1};
            8'd62: {p, q} = {7'd20, 2'd2};
            8'd63: {p, q} = {7'd21, 2'd0};
            8'd64: {p, q} = {7'd21, 2'd1};
            8'd65: {p, q} = {7'd21, 2'd2};
            8'd66: {p, q} = {7'd22, 2'd0};
            8'd67: {p, q} = {7'd22, 2'd1};
            8'd68: {p, q} = {7'd22, 2'd2};
            8'd69: {p, q} = {7'd23, 2'd0};
            8'd70: {p, q} = {7'd23, 2'd1};
            8'd71: {p, q} = {7'd23, 2'd2};
            8'd72: {p, q} = {7'd24, 2'd0};
            8'd73: {p, q} = {7'd24, 2'd1};
            8'd74: {p, q} = {7'd24, 2'd2};
            8'd75: {p, q} = {7'd25, 2'd0};
            8'd76: {p, q} = {7'd25, 2'd1};
            8'd77: {p, q} = {7'd25, 2'd2};
            8'd78: {p, q} = {7'd26, 2'd0};
            8'd79: {p, q} = {7'd26, 2'd1};
            8'd80: {p, q} = {7'd26, 2'd2};
            8'd81: {p, q} = {7'd27, 2'd0};
            8'd82: {p, q} = {7'd27, 2'd1};
            8'd83: {p, q} = {7'd27, 2'd2};
            8'd84: {p, q} = {7'd28, 2'd0};
            8'd85: {p, q} = {7'd28, 2'd1};
            8'd86: {p, q} = {7'd28, 2'd2};
            8'd87: {p, q} = {7'd29, 2'd0};
            8'd88: {p, q} = {7'd29, 2'd1};
            8'd89: {p, q} = {7'd29, 2'd2};
            8'd90: {p, q} = {7'd30, 2'd0};
            8'd91: {p, q} = {7'd30, 2'd1};
            8'd92: {p, q} = {7'd30, 2'd2};
            8'd93: {p, q} = {7'd31, 2'd0};
            8'd94: {p, q} = {7'd31, 2'd1};
            8'd95: {p, q} = {7'd31, 2'd2};
            8'd96: {p, q} = {7'd32, 2'd0};
            8'd97: {p, q} = {7'd32, 2'd1};
            8'd98: {p, q} = {7'd32, 2'd2};
            8'd99: {p, q} = {7'd33, 2'd0};
            8'd100: {p, q} = {7'd33, 2'd1};
            8'd101: {p, q} = {7'd33, 2'd2};
            8'd102: {p, q} = {7'd34, 2'd0};
            8'd103: {p, q} = {7'd34, 2'd1};
            8'd104: {p, q} = {7'd34, 2'd2};
            8'd105: {p, q} = {7'd35, 2'd0};
            8'd106: {p, q} = {7'd35, 2'd1};
            8'd107: {p, q} = {7'd35, 2'd2};
            8'd108: {p, q} = {7'd36, 2'd0};
            8'd109: {p, q} = {7'd36, 2'd1};
            8'd110: {p, q} = {7'd36, 2'd2};
            8'd111: {p, q} = {7'd37, 2'd0};
            8'd112: {p, q} = {7'd37, 2'd1};
            8'd113: {p, q} = {7'd37, 2'd2};
            8'd114: {p, q} = {7'd38, 2'd0};
            8'd115: {p, q} = {7'd38, 2'd1};
            8'd116: {p, q} = {7'd38, 2'd2};
            8'd117: {p, q} = {7'd39, 2'd0};
            8'd118: {p, q} = {7'd39, 2'd1};
            8'd119: {p, q} = {7'd39, 2'd2};
            8'd120: {p, q} = {7'd40, 2'd0};
            8'd121: {p, q} = {7'd40, 2'd1};
            8'd122: {p, q} = {7'd40, 2'd2};
            8'd123: {p, q} = {7'd41, 2'd0};
            8'd124: {p, q} = {7'd41, 2'd1};
            8'd125: {p, q} = {7'd41, 2'd2};
            8'd126: {p, q} = {7'd42, 2'd0};
            8'd127: {p, q} = {7'd42, 2'd1};
            8'd128: {p, q} = {7'd42, 2'd2};
            8'd129: {p, q} = {7'd43, 2'd0};
            8'd130: {p, q} = {7'd43, 2'd1};
            8'd131: {p, q} = {7'd43, 2'd2};
            8'd132: {p, q} = {7'd44, 2'd0};
            8'd133: {p, q} = {7'd44, 2'd1};
            8'd134: {p, q} = {7'd44, 2'd2};
            8'd135: {p, q} = {7'd45, 2'd0};
            8'd136: {p, q} = {7'd45, 2'd1};
            8'd137: {p, q} = {7'd45, 2'd2};
            8'd138: {p, q} = {7'd46, 2'd0};
            8'd139: {p, q} = {7'd46, 2'd1};
            8'd140: {p, q} = {7'd46, 2'd2};
            8'd141: {p, q} = {7'd47, 2'd0};
            8'd142: {p, q} = {7'd47, 2'd1};
            8'd143: {p, q} = {7'd47, 2'd2};
            8'd144: {p, q} = {7'd48, 2'd0};
            8'd145: {p, q} = {7'd48, 2'd1};
            8'd146: {p, q} = {7'd48, 2'd2};
            8'd147: {p, q} = {7'd49, 2'd0};
            8'd148: {p, q} = {7'd49, 2'd1};
            8'd149: {p, q} = {7'd49, 2'd2};
            8'd150: {p, q} = {7'd50, 2'd0};
            8'd151: {p, q} = {7'd50, 2'd1};
            8'd152: {p, q} = {7'd50, 2'd2};
            8'd153: {p, q} = {7'd51, 2'd0};
            8'd154: {p, q} = {7'd51, 2'd1};
            8'd155: {p, q} = {7'd51, 2'd2};
            8'd156: {p, q} = {7'd52, 2'd0};
            8'd157: {p, q} = {7'd52, 2'd1};
            8'd158: {p, q} = {7'd52, 2'd2};
            8'd159: {p, q} = {7'd53, 2'd0};
            8'd160: {p, q} = {7'd53, 2'd1};
            8'd161: {p, q} = {7'd53, 2'd2};
            8'd162: {p, q} = {7'd54, 2'd0};
            8'd163: {p, q} = {7'd54, 2'd1};
            8'd164: {p, q} = {7'd54, 2'd2};
            8'd165: {p, q} = {7'd55, 2'd0};
            8'd166: {p, q} = {7'd55, 2'd1};
            8'd167: {p, q} = {7'd55, 2'd2};
            8'd168: {p, q} = {7'd56, 2'd0};
            8'd169: {p, q} = {7'd56, 2'd1};
            8'd170: {p, q} = {7'd56, 2'd2};
            8'd171: {p, q} = {7'd57, 2'd0};
            8'd172: {p, q} = {7'd57, 2'd1};
            8'd173: {p, q} = {7'd57, 2'd2};
            8'd174: {p, q} = {7'd58, 2'd0};
            8'd175: {p, q} = {7'd58, 2'd1};
            8'd176: {p, q} = {7'd58, 2'd2};
            8'd177: {p, q} = {7'd59, 2'd0};
            8'd178: {p, q} = {7'd59, 2'd1};
            8'd179: {p, q} = {7'd59, 2'd2};
            8'd180: {p, q} = {7'd60, 2'd0};
            8'd181: {p, q} = {7'd60, 2'd1};
            8'd182: {p, q} = {7'd60, 2'd2};
            8'd183: {p, q} = {7'd61, 2'd0};
            8'd184: {p, q} = {7'd61, 2'd1};
            8'd185: {p, q} = {7'd61, 2'd2};
            8'd186: {p, q} = {7'd62, 2'd0};
            8'd187: {p, q} = {7'd62, 2'd1};
            8'd188: {p, q} = {7'd62, 2'd2};
            8'd189: {p, q} = {7'd63, 2'd0};
            8'd190: {p, q} = {7'd63, 2'd1};
            8'd191: {p, q} = {7'd63, 2'd2};
            8'd192: {p, q} = {7'd64, 2'd0};
            8'd193: {p, q} = {7'd64, 2'd1};
            8'd194: {p, q} = {7'd64, 2'd2};
            8'd195: {p, q} = {7'd65, 2'd0};
            8'd196: {p, q} = {7'd65, 2'd1};
            8'd197: {p, q} = {7'd65, 2'd2};
            8'd198: {p, q} = {7'd66, 2'd0};
            8'd199: {p, q} = {7'd66, 2'd1};
            8'd200: {p, q} = {7'd66, 2'd2};
            8'd201: {p, q} = {7'd67, 2'd0};
            8'd202: {p, q} = {7'd67, 2'd1};
            8'd203: {p, q} = {7'd67, 2'd2};
            8'd204: {p, q} = {7'd68, 2'd0};
            8'd205: {p, q} = {7'd68, 2'd1};
            8'd206: {p, q} = {7'd68, 2'd2};
            8'd207: {p, q} = {7'd69, 2'd0};
            8'd208: {p, q} = {7'd69, 2'd1};
            8'd209: {p, q} = {7'd69, 2'd2};
            8'd210: {p, q} = {7'd70, 2'd0};
            8'd211: {p, q} = {7'd70, 2'd1};
            8'd212: {p, q} = {7'd70, 2'd2};
            8'd213: {p, q} = {7'd71, 2'd0};
            8'd214: {p, q} = {7'd71, 2'd1};
            8'd215: {p, q} = {7'd71, 2'd2};
            8'd216: {p, q} = {7'd72, 2'd0};
            8'd217: {p, q} = {7'd72, 2'd1};
            8'd218: {p, q} = {7'd72, 2'd2};
            8'd219: {p, q} = {7'd73, 2'd0};
            8'd220: {p, q} = {7'd73, 2'd1};
            8'd221: {p, q} = {7'd73, 2'd2};
            8'd222: {p, q} = {7'd74, 2'd0};
            8'd223: {p, q} = {7'd74, 2'd1};
            8'd224: {p, q} = {7'd74, 2'd2};
            8'd225: {p, q} = {7'd75, 2'd0};
            8'd226: {p, q} = {7'd75, 2'd1};
            8'd227: {p, q} = {7'd75, 2'd2};
            8'd228: {p, q} = {7'd76, 2'd0};
            8'd229: {p, q} = {7'd76, 2'd1};
            8'd230: {p, q} = {7'd76, 2'd2};
            8'd231: {p, q} = {7'd77, 2'd0};
            8'd232: {p, q} = {7'd77, 2'd1};
            8'd233: {p, q} = {7'd77, 2'd2};
            8'd234: {p, q} = {7'd78, 2'd0};
            8'd235: {p, q} = {7'd78, 2'd1};
            8'd236: {p, q} = {7'd78, 2'd2};
            8'd237: {p, q} = {7'd79, 2'd0};
            8'd238: {p, q} = {7'd79, 2'd1};
            8'd239: {p, q} = {7'd79, 2'd2};
            8'd240: {p, q} = {7'd80, 2'd0};
            8'd241: {p, q} = {7'd80, 2'd1};
            8'd242: {p, q} = {7'd80, 2'd2};
            8'd243: {p, q} = {7'd81, 2'd0};
            8'd244: {p, q} = {7'd81, 2'd1};
            8'd245: {p, q} = {7'd81, 2'd2};
            8'd246: {p, q} = {7'd82, 2'd0};
            8'd247: {p, q} = {7'd82, 2'd1};
            8'd248: {p, q} = {7'd82, 2'd2};
            8'd249: {p, q} = {7'd83, 2'd0};
            8'd250: {p, q} = {7'd83, 2'd1};
            8'd251: {p, q} = {7'd83, 2'd2};
            8'd252: {p, q} = {7'd84, 2'd0};
            8'd253: {p, q} = {7'd84, 2'd1};
            8'd254: {p, q} = {7'd84, 2'd2};
            8'd255: {p, q} = {7'd85, 2'd0};
        endcase
    end
endmodule

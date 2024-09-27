module BB(
    //Input Ports
    input clk,
    input rst_n,
    input in_valid,
    input [1:0] inning,   // Current inning number
    input half,           // 0: top of the inning, 1: bottom of the inning
    input [2:0] action,   // Action code

    //Output Ports
    output reg out_valid,  // Result output valid
    output reg [7:0] score_A,  // Score of team A (guest team)
    output reg [7:0] score_B,  // Score of team B (home team)
    output reg [1:0] result    // 0: Team A wins, 1: Team B wins, 2: Darw
);

//==============================================//
//             Action Memo for Students         //
// Action code interpretation:
// 3’d0: Walk (BB)
// 3’d1: 1H (single hit)
// 3’d2: 2H (double hit)
// 3’d3: 3H (triple hit)
// 3’d4: HR (home run)
// 3’d5: Bunt (short hit)
// 3’d6: Ground ball
// 3’d7: Fly ball
//==============================================//

//==============================================//
//             Parameter and Integer            //
//==============================================//
// State declaration for FSM
// Example: parameter IDLE = 3'b000;


//==============================================//
//                 reg declaration              //
//==============================================//
//reg cs, ns;

reg [3:0] score_t2;
reg [3:0] score_t3;
reg [2:0] base, base_n;
reg [3:0] tmp;
reg [2:0] score_t;
reg [1:0] outcnt, outcnt_n;

reg played;
reg done;

//==============================================//
//             Current State Block              //
//==============================================//
/*always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cs <= gaming;
    else
        cs <= ns;
end*/


//==============================================//
//              Next State Block                //
//==============================================//
/*always @(*) begin
    if (!rst_n)
        ns = gaming;
    else begin
        if (!cs)
            ns = (played && !in_valid);
        else
            ns = gaming;
    end
end*/


//==============================================//
//             Base and Score Logic             //
//==============================================//
// Handle base runner movements and score calculation.
// Update bases and score depending on the action:
// Example: Walk, Hits (1H, 2H, 3H), Home Runs, etc.
//assign hit = {3'd0, (outcnt[1] && (action[0] ^ action[1]))? {base, 2'd1} : {1'd0, base, 1'd1}} << action;
always @(*) begin
    tmp = 4'd0;
    base_n = base;
    outcnt_n = outcnt;
    case (action)
        3'd0: begin
            base_n[0] = 1'd1;
            if (base[0]) begin
                base_n[1] = 1'd1;
                if (base[1]) begin
                    base_n[2] = 1'd1;
                    if (base[2])
                        tmp = 4'd1;
                end
            end
        end
        3'd1: begin
            //{tmp, base_n} = (outcnt[1])? {2'd0, base, 2'd1} : {3'd0, base, 1'd1};
            //{tmp, base_n} = {((outcnt[1])? 2'd0 : 3'd0), base, ((outcnt[1])? 2'd1 : 1'd1)};
            tmp = (outcnt[1])? base[2:1] : base[2];
            base_n = (outcnt[1])? {base[0], 2'd1} : {base[1:0], 1'd1};
        end
        3'd2: begin
            //{tmp, base_n} = (outcnt[1])? {1'd0, base, 3'd2} : {2'd0, base, 2'd2};
            {tmp, base_n} = {(outcnt[1])? 1'd0 : 2'd0, base, (outcnt[1])? 3'd2 : 2'd2};
        end
        3'd3: begin
            {tmp, base_n} = {1'd0, base, 3'd4};
        end
        3'd4: {tmp, base_n} = {base, 4'd8};
        3'd5: begin
            {tmp, base_n} = {3'd0, base, 1'd0};
            outcnt_n = {outcnt[0], 1'd1}; 
        end
        3'd6: begin
            outcnt_n[0] = !outcnt || ~(outcnt[1] || base[0]);
            outcnt_n[1] = (base[0] && !outcnt) || (~base[0] && (~outcnt[1] && outcnt[0]));
            base_n[1:0] = 2'd0;
            {tmp[0], base_n[2]} = (outcnt[1] || (outcnt[0] && base[0]))? 2'd0 : {base[2:1]}; 
            /*if (outcnt[1] || (outcnt[0] && base[0])) begin
                base_n = 3'd0;
            end
            else begin
                {tmp, base_n} = {3'd0, base[2:1], 2'd0};
            end*/
        end
        3'd7:begin
            if (outcnt[1]) begin
                outcnt_n = 2'd0;
                base_n = 3'd0;
            end
            else begin
                outcnt_n = {outcnt[0], 1'd1};
                {tmp, base_n} = {3'd0, base[2], 1'd0, base[1:0]};
            end
        end
        default: base_n = base;
    endcase
end

always @(*) begin
    score_t = (tmp[0] + tmp[1]) + (tmp[2] + tmp[3]);
    /*score_t2 = base_n ^ {1'd0, base};
    if (outcnt ^ outcnt_n) begin
        if(score_t2[0])
            score_t2[0] = 1'd0;
        else begin
            if (score_t2[1])
                score_t2[1] = 1'd0;
            else
                score_t2[2] = 1'd0;
        end
    end
    score_t = (score_t2[0] + score_t2[1]) + (score_t2[2] + score_t2[3]);*/
end
/*reg [3:0] sel;

always @(*) begin
    sel = (half)? score_B: score_A;
    if (done && half) begin
        score_t3 = sel;
    end
    else begin
        case ({score_t, sel[2:0]})
            6'd8: score_t3 = 3'd1;
            6'd9, 6'd16: score_t3 = 3'd2;
            6'd10, 6'd17, 6'd24: score_t3 = 3'd3;
            6'd11, 6'd18, 6'd25, 6'd32: score_t3 = 3'd4;
            6'd12, 6'd19, 6'd26, 6'd33: score_t3 = 3'd5;
            6'd13, 6'd20, 6'd27, 6'd34: score_t3 = 3'd6;
            6'd14, 6'd21, 6'd28, 6'd35: score_t3 = 3'd7;
            6'd15, 6'd22, 6'd29, 6'd36: score_t3 = 4'd8;
            6'd23, 6'd30, 6'd37: score_t3 = 4'd9;
            default: score_t3 = sel;
        endcase
    end
end*/

always @(*) begin
    score_t3[2:0] = ((half)? score_B[2:0] : score_A[2:0]) + ((done && half)? 3'd0 : score_t);
    score_t3[3] = score_t3[2:0] < score_A[3:0];
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 1'd0;
        score_A[3:0] <= 4'd0;
        score_B[2:0] <= 3'd0;

        done <= 1'd0;
        base <= 3'd0;
        outcnt <= 2'd0;
        played <= 1'd0;
    end
    else begin
        if (!played || in_valid) begin
            out_valid <= 1'd0;
            if (!played) begin
                score_A[3:0] <= 4'd0;
                score_B[2:0] <= 3'd0;
            end
            if (in_valid) begin
                played <= 1'd1;
                if ({inning, half} == 3'd6)
                    done <= score_B[2:0] > score_A[3:0];
                if (half) begin
                    score_B[2:0] <= score_t3;
                    //score_B[2:0] <= score_B[2:0] + ((done && half)? 3'd0 : score_t);
                end
                else begin
                    score_A[3:0] <= score_t3;
                    //score_A[3:0] <= score_A[3:0] + score_t;
                end
                base <= base_n;
                outcnt <= outcnt_n;
            end
        end
        else begin
            out_valid <= 1'd1;
            played <= 1'd0;
            done <= 1'd0;
        end
    end
end


//==============================================//
//                Output Block                  //
//==============================================//
// Decide when to set out_valid high, and output score_A, score_B, and result.
assign score_A[7:4] = 4'd0;
assign score_B[7:3] = 5'd0;

always @(*) begin
    if (score_A >= score_B) begin
        result = 2'd0;
        if (score_A == score_B)
            result = (out_valid)? 2'd2 : 2'd0;
    end
    else
        result = 2'd1;
end

endmodule

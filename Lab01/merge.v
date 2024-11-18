module split_1_3 (
    l0,
    r0, r1, r2,
    a0, a1, a2, a3
);
    input [7:0] l0;
    input [7:0] r0, r1, r2;
    output reg [7:0] a0, a1, a2, a3;
    always @(*) begin
        if (l0 >= r0) begin
            {a0, a1, a2, a3} = {l0, r0, r1, r2};
        end
        else begin
            a0 = r0;
            if (l0 >= r1)
                {a1, a2, a3} = {l0, r1, r2};
            else begin
                a1 = r1;
                {a2, a3} = (l0 >= r2)? {l0, r2} : {r2, l0};
            end
        end
    end
    
endmodule

module split_2_2 (
    l0, l1,
    r0, r1,
    a0, a1, a2, a3
);
    input [7:0] l0, l1;
    input [7:0] r0, r1;
    output reg [7:0] a0, a1, a2, a3;
    
    always @(*) begin
        if (l0 >= r0) begin
            a0 = l0;
            if (l1 >= r0)
                {a1, a2, a3} = {l1, r0, r1};
            else begin
                a1 = r0;
                {a2, a3} = (l1 >= r1)? {l1, r1} : {r1, l1};
            end
        end
        else begin
            a0 = r0;
            if (l0 >= r1) begin
                a1 = l0;
                {a2, a3} = (l1 >= r1)? {l1, r1} : {r1, l1};
            end
            else
                {a1, a2, a3} = {r1, l0, l1};
        end
    end
endmodule

module merge_8(
    l0, l1, l2, l3,
    r0, r1, r2, r3,
    a0, a1, a2, a3, a4, a5, a6, a7 
);
    input [7:0] l0, l1, l2, l3;
    input [7:0] r0, r1, r2, r3;
    output reg [7:0] a0, a1, a2, a3, a4, a5, a6, a7;

    always @(*) begin
        if (l0 >= r0) begin
            a0 = l0;
            if (l1 >= r0) begin
                a1 = l1;
                if (l2 >= r0) begin
                    a2 = l2;
                    if (l3 >= r0)
                        {a3, a4, a5, a6, a7} = {l3, r0, r1, r2, r3};
                    else begin
                        a3 = r0;
                        if (l3 >= r1)
                            {a4, a5, a6, a7} = {l3, r1, r2, r3};
                        else begin
                            a4 = r1;
                            if (l3 >= r2)
                                {a5, a6, a7} = {l3, r2, r3};
                            else begin
                                a5 = r2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                        end
                    end
                end
                else begin //l0, l1, r0
                    a2 = r0;
                    if (l2 >= r1) begin
                        a3 = l2;
                        if (l3 >= r1)
                            {a4, a5, a6, a7} = {l3, r1, r2, r3};
                        else begin
                            a4 = r1;
                            if (l3 >= r2)
                                {a5, a6, a7} = {l3, r2, r3};
                            else begin
                                a5 = r2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end 
                        end
                    end
                    else begin //l0, l1, r0, r1
                        a3 = r1;
                        if (l2 >= r2) begin
                            a4 = l2;
                            if (l3 >= r2) 
                                {a5, a6, a7} = {l3, r2, r3};
                            else begin
                                a5 = r2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                        end
                        else begin
                            a4 = r2;
                            if (l2 >= r3) begin
                                a5 = l2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                            else
                                {a5, a6, a7} = {r3, l2, l3};
                        end
                    end
                end
            end
            else begin //l0, r0
                a1 = r0;
                if (l1 >= r1) begin
                    a2 = l1;
                    if (l2 >= r1) begin
                        a3 = l2;
                        if (l3 >= r1)
                            {a4, a5, a6, a7} = {l3, r1, r2, r3};
                        else begin
                            a4 = r1;
                            if (l3 >= r2) 
                                {a5, a6, a7} = {l3, r2, r3};
                            else begin
                                a5 = r2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                        end
                    end
                    else begin //l0, r0, l1, r1
                        a3 = r1;
                        if (l2 >= r2) begin
                            a4 = l2;
                            if (l3 >= r2)
                                {a5, a6, a7} = {l3, r2, r3};
                            else begin
                                a5 = r2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                        end
                        else begin
                            a4 = r2;
                            if (l2 >= r3) begin
                                a5 = l2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                            else
                                {a5, a6, a7} = {r3, l2, l3};
                        end
                    end
                end
                else begin //l0, r0, r1
                    a2 = r1;
                    if (l1 >= r2) begin
                        a3 = l1;
                        if (l2 >= r2) begin
                            a4 = l2;
                            if (l3 >= r2)
                                {a5, a6, a7} = {l3, r2, r3};
                            else begin
                                a5 = r2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                        end
                        else begin
                            a4 = r2;
                            if (l2 >= r3) begin
                                a5 = l2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                            else
                                {a5, a6, a7} = {r3, l2, l3};
                        end
                    end
                    else begin //l0, r0, r1, r2
                        a3 = r2;
                        if (l1 >= r3) begin
                            a4 = l1;
                            if (l2 >= r3) begin
                                a5 = l2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                            else
                                {a5, a6, a7} = {r3, l2, l3};
                        end
                        else
                            {a4, a5, a6, a7} = {r3, l1, l2, l3};
                    end
                end
            end
        end
        else begin
            a0 = r0;
            if (l0 >= r1) begin
                a1 = l0;
                if (l1 >= r1) begin
                    a2 = l1;
                    if (l2 >= r1) begin
                        a3 = l2;
                        if (l3 >= r1)
                            {a4, a5, a6, a7} = {l3, r1, r2, r3};
                        else begin
                            a4 = r1;
                            if (l3 >= r2)
                                {a5, a6, a7} = {l3, r2, r3};
                            else begin
                                a5 = r2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                        end
                    end
                    else begin //r0, l0, l1, r1
                        a3 = r1;
                        if (l2 >= r2) begin
                            a4 = l2;
                            if (l3 >= r2)
                                {a5, a6, a7} = {l3, r2, r3};
                            else begin
                                a5 = r2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                        end
                        else begin
                            a4 = r2;
                            if (l2 >= r3) begin
                                a5 = l2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                            else
                                {a5, a6, a7} = {r3, l2, l3};
                        end
                    end
                end
                else begin //r0, l0, r1
                    a2 = r1;
                    if (l1 >= r2) begin
                        a3 = l1;
                        if (l2 >= r2) begin
                            a4 = l2;
                            if (l3 >= r2)
                                {a5, a6, a7} = {l3, r2, r3};
                            else begin
                                a5 = r2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                        end
                        else begin
                            a4 = r2;
                            if (l2 >= r3) begin
                                a5 = l2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                            else
                                {a5, a6, a7} = {r3, l2, l3};
                        end
                    end
                    else begin // r0, l0, r1, r2
                        a3 = r2;
                        if (l1 >= r3) begin
                            a4 = l1;
                            if (l2 >= r3) begin
                                a5 = l2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                            else
                                {a5, a6, a7} = {r3, l2, l3};
                        end
                        else
                            {a4, a5, a6, a7} = {r3, l1, l2, l3};
                    end
                end
            end
            else begin
                a1 = r1;
                if (l0 >= r2) begin //r0, r1, l0
                    a2 = l0;
                    if (l1 >= r2) begin // r0, r1, l0, l1
                        a3 = l1;
                        if (l2 >= r2) begin
                            a4 = l2;
                            if (l3 >= r2)
                                {a5, a6, a7} = {l3, r2, r3};
                            else begin
                                a5 = r2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                        end
                        else begin
                            a4 = r2;
                            if (l2 >= r3) begin
                                a5 = l2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                            else
                                {a5, a6, a7} = {r3, l2, l3};
                        end
                    end
                    else begin //r0, r1, l0, r2
                        a3 = r2;
                        if (l1 >= r3) begin
                            a4 = l1;
                            if (l2 >= r3) begin
                                a5 = l2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                            else
                                {a5, a6, a7} = {r3, l2, l3};
                        end
                        else
                            {a4, a5, a6, a7} = {r3, l1, l2, l3};
                    end
                end
                else begin //r0, r1, r2
                    a2 = r2;
                    if (l0 >= r3) begin // r0, r1, r2, l0
                        a3 = l0;
                        if (l1 >= r3) begin
                            a4 = l1;
                            if (l2 >= r3) begin
                                a5 = l2;
                                {a6, a7} = (l3 >= r3)? {l3, r3} : {r3, l3};
                            end
                            else
                                {a5, a6, a7} = {r3, l2, l3};
                        end
                        else
                            {a4, a5, a6, a7} = {r3, l1, l2, l3};
                    end
                    else begin
                        {a3, a4, a5, a6, a7} = {r3, l0, l1, l2, l3};
                    end
                end
            end
        end
    end
endmodule

module merge_4(
    l0, l1,
    r0, r1,
    a0, a1, a2, a3
);
    input [7:0] l0, l1;
    input [7:0] r0, r1;
    output reg [7:0] a0, a1, a2, a3;

    always @(*) begin
        if (l0 >= r0) begin
            a0 = l0;
            if (l1 >= r0) begin
                a1 = l1;
                a2 = r0;
                a3 = r1;
            end
            else begin
                a1 = r0;
                {a2, a3} = (l1 >= r1)? {l1, r1} : {r1, l1};
            end
        end
        else begin
            a0 = r0;
            if (l0 >= r1) begin
                a1 = l0;
                {a2, a3} = (l1 >= r1)? {l1, r1} : {r1, l1};
            end
            else begin
                a1 = r1;
                a2 = l0;
                a3 = l1;
            end
        end
    end

endmodule

module merge_sort_4(
    a0, a1, a2, a3,
    b0, b1, b2, b3
);
    input [7:0] a0, a1, a2, a3;
    output [7:0] b0, b1, b2, b3;

    wire [7:0] l0, l1;
    wire [7:0] r0, r1;

    assign {l0, l1} = (a0 >= a1)? {a0, a1} : {a1, a0};
    assign {r0, r1} = (a2 >= a3)? {a2, a3} : {a3, a2};

    merge_4 merge(
        l0, l1,
        r0, r1,
        b0, b1, b2, b3
    );

endmodule

module merge_sort(
    a0, a1, a2, a3, a4, a5, a6, a7,
    b0, b1, b2, b3, b4, b5, b6, b7
);

    input [7:0] a0, a1, a2, a3, a4, a5, a6, a7;
    output [7:0] b0, b1, b2, b3, b4, b5, b6, b7;

    wire [7:0] l0, l1, l2, l3;
    wire [7:0] r0, r1, r2, r3;

    merge_sort_4 sort_left(
        a0, a1, a2, a3,
        l0, l1, l2, l3
    );

    merge_sort_4 sort_right(
        a4, a5, a6, a7,
        r0, r1, r2, r3
    );

    merge_8 merge(
        l0, l1, l2, l3,
        r0, r1, r2, r3,
        b0, b1, b2, b3, b4, b5, b6, b7
    );

endmodule
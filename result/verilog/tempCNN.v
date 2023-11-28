`timescale 1ns / 1ps

// accuracy 9% 나오는 문제 해결하기(IMGIN 값 저장 알고리즘 or conv, fc 알고리즘)
module simpleCNN (
        CLK,
        nRST,
        START,
        X,
        Y,
        IMGIN,
        
        DONE,
        OUT
    );

    input   wire        CLK;
    input   wire        nRST;
    input   wire        START;
    input   wire[4:0]       X;
    input   wire[4:0]       Y;
    input   wire[199:0] IMGIN;
        
    output  reg        DONE;
    output  reg[3:0]   OUT;

    `include "kernel.vh"

    reg[1:0] state;
    parameter IDLE = 2'b00, CONVOLUTION = 2'b01, RELU = 2'b10, FULLY_CONNECTED = 2'b11;

    // CONVOLUTION에서 사용하는 변수
    reg signed [15:0] conv_res[575:0];
    reg signed [15:0] mul_res;
    reg signed [15:0] sum;
    integer conv_cnt;

    // FC에서 사용하는 변수
    reg signed [23:0] fc_res[9:0];
    integer ans_idx;

    integer i, j;
    always @(posedge CLK or negedge nRST)
    begin
        if (!nRST) begin
            conv_cnt <= 0;
            DONE <= 0;
            OUT <= 0;
            state <= IDLE;
        end
        else begin
            case (state)
                IDLE: begin
                    conv_cnt <= 0;
                    DONE <= 0;
                    OUT <= 0;
                    if (START) begin
                        sum <= 0;
                        state <= CONVOLUTION;
                    end
                end
                
                CONVOLUTION: begin
                    $display("x: %d, y: %d", X, Y);
                    for (i = 0; i < 5; i = i + 1) begin
                        for (j = 0; j < 5; j = j + 1) begin
                            sum <= sum + conv_kernel(i, j) * IMGIN[(i * 5 + j) * 8 +: 8];
                            //$display("%d sum: %h, IMGIN: %h", conv_cnt, sum, IMGIN[(i * 5 + j) * 8 +: 8]);
                        end
                    end
                    #1 conv_res[conv_cnt] <= sum;
                    #1 state <= RELU;

                    //$display("conv_cnt: %d, conv_res/sum: %h/%h", conv_cnt, conv_res[conv_cnt], sum);
                end

                RELU: begin
                    if (sum < 0)
                        conv_res[conv_cnt] <= 0;

                //$display("conv_res: %h", conv_res[conv_cnt]);

                #1 conv_cnt <= conv_cnt + 1;
                #1 state <= FULLY_CONNECTED;

                end

                FULLY_CONNECTED: begin
                    for (i = 0; i < 10; i = i + 1) begin
                        fc_res[i] = 0;
                        for (j = 0; j < 576; j = j + 1) begin
                            fc_res[i] = fc_res[i] + fc_kernel(i, j) * conv_res[j];
                            //$display("fc_res: %h, fc_kernel: %h, conv_res: %h", fc_res[i], fc_kernel(i, j), conv_res[j]);
                        end
                        //$display("fc_res[%d]: %d", i, fc_res[i]);
                    end
                    
                    // OUT 결정
                    ans_idx = 0;
                    for (i = 1; i < 10; i = i + 1) begin
                        //$display("fc_res[i]: %d, fc_res[ans]: %d, ans_idx: %d", fc_res[i], fc_res[ans_idx], ans_idx);
                        if (fc_res[i] > fc_res[ans_idx])
                            ans_idx = i;
                    end

                    OUT <= ans_idx;
                    state <= IDLE;
                    DONE <= 1;
                end
            endcase
        end
    end

endmodule
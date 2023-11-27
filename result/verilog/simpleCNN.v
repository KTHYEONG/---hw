`timescale 1ns / 1ps

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
parameter IDLE = 2'b00, CONVOLUTION = 2'b01, FULLY_CONNECTED = 2'b10;

// CONVOLUTION에서 사용하는 변수
reg[15:0] conv_res[575:0];
reg[15:0] mul_res;
reg[15:0] sum;
integer conv_cnt;

// FC에서 사용하는 변수
reg[23:0] fc_res[9:0];
integer ans_idx;

integer i, j;
always @(posedge CLK or nRST)
begin
    if (!nRST) begin
        DONE <= 0;
        OUT <= 0;
        state <= IDLE;
    end
    else begin
        case (state)
            IDLE: begin
                if (START) begin
                    conv_cnt <= 0;
                    DONE <= 0;
                    state <= CONVOLUTION;
                end
            end
            
            CONVOLUTION: begin
                sum = 0;
                for (i = 0; i < 5; i = i + 1) begin
                    for (j = 0; j < 5; j = j + 1) begin
                        mul_res = conv_kernel(i, j) * IMGIN[(i * 5 + j) * 8 +: 8];
                        sum = sum + mul_res;
                        //$display("%d sum: %h, mul_res: %h", conv_cnt, sum, mul_res);
                    end
                end
                
                // relu
                if (sum < 0)
                    conv_res[conv_cnt] <= 0;
                conv_res[conv_cnt] = sum;
                
                //$display("%d, sum: %d, conv_res: %d", conv_cnt, sum, conv_res[conv_cnt]);
                
                conv_cnt <= conv_cnt + 1;
                if (conv_cnt > 575)
                    state <= FULLY_CONNECTED;
            end

            FULLY_CONNECTED: begin
                for (i = 0; i < 10; i = i + 1) begin
                    fc_res[i] = 0;
                    for (j = 0; j < 576; j = j + 1) begin
                        fc_res[i] = fc_res[i] + fc_kernel(i, j) * conv_res[j];
                        //$display("fc_res: %h, fc_kernel: %h, conv_res: %h", fc_res[i], fc_kernel(i, j), conv_res[j]);
                    end
                end
                
                // 결과 찾기
                ans_idx = 0;
                for (i = 1; i < 10; i = i + 1) begin
                    //$display("fc_resI: %h, fc_resA: %h, ans_idx: %d", fc_res[i], fc_res[ans_idx], ans_idx);
                    if (fc_res[i] > fc_res[ans_idx])
                        ans_idx <= i;
                end

                // 1이미지만 실행되는 이유 찾기
                OUT <= ans_idx;
                DONE <= 1;
                $display("%d", DONE);
                state <= IDLE;
            end
        endcase
    end
end

endmodule
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
    input   wire [4:0]       X;
    input   wire [4:0]       Y;
    input   wire [199:0] IMGIN;
        
    output  reg        DONE;
    output  reg [3:0]   OUT;

    `include "kernel.vh"

    reg [1:0] state;
    parameter IDLE = 2'b00, CONVOLUTION = 2'b01,
            FULLY_CONNECTED = 2'b10, RESULT = 2'b11;

    // CONVOLUTION && RELU
    reg signed [31:0] conv_res[23:0][23:0];
    reg [7:0] conv_temp[4:0][4:0];
    reg signed [31:0] conv_sum;

    // FC
    reg signed [24*24*24 - 1:0] fc_res [9:0];
    reg signed [24*24*24 - 1:0] fc_sum;
    integer fc_cnt, fc_idx, ans_idx;

    integer i, j;
    //initial
        //$monitor("conv_temp[%2d][%2d]: %h", i, j, conv_temp[i][j]);

    always @(posedge CLK or negedge nRST)
    begin
        if (!nRST) begin
            DONE <= 0;
            OUT <= 0;
            state <= IDLE;
        end
        else begin
            case (state)
                IDLE: begin
                    OUT <= 0;
                    DONE <= 0;
                    if (START) begin
                        state <= CONVOLUTION;
                    end
                end
                
                CONVOLUTION: begin
                    for (i = 0; i < 5; i = i + 1) begin
                        for (j = 0; j < 5; j = j + 1) begin
                            conv_temp[i][j] <= IMGIN[(i * 5 + j) * 8 +: 8];
                        end
                    end

                    ConvReluTask(conv_res[X][Y]);
                    //$monitor("conv_res[%2d][%2d]: %h", X, Y, conv_res[X][Y]);
                    
                    if (X == 23 && Y == 23)
                        state <= FULLY_CONNECTED;
                end

                FULLY_CONNECTED: begin
                    /*for (integer j = 0; j < 24 * 24; j = j + 1) begin
                        fc_sum[j * 24 +: 24] <= fc_kernel(fc_cnt, j) * conv_res[j / 24][j % 24];
                    end
                    fc_res[fc_cnt] <= fc_sum;
                    fc_cnt <= fc_cnt + 1;

                    if (fc_cnt > 0) begin
                        if (fc_res[ans_idx] > fc_res[fc_cnt])
                            ans_idx <= fc_cnt;
                    end

                    if (fc_cnt > 9) begin
                        DONE <= 1;
                        OUT <= ans_idx;
                        state <= IDLE;
                    end*/
                    DONE <= 1;
                    state <= IDLE;
                end

            endcase
        end
    end

// 벡터 크기가 다른 연산 값이 이상하게 저장되는 부분 수정하기
task ConvReluTask(output res);
reg signed [31:0] res;
reg signed [31:0] sum; 
integer i, j;
begin
    sum = 0;
    for (i = 0; i < 5; i = i + 1) begin
        for (j = 0; j < 5; j = j + 1) begin
            sum = sum + conv_kernel(i, j) * conv_temp[i][j];
            $display("sum: %h, mul: %h, conv_temp: %h", sum, conv_kernel(i, j) * conv_temp[i][j], conv_temp[i][j]);
        end
    end
    
    if (sum < 0)
        res = 0;
    else
        res = sum;
end    
endtask

endmodule
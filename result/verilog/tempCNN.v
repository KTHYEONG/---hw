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
    parameter IDLE = 2'b00, CONVOLUTION = 2'b01,
            FULLY_CONNECTED = 2'b10, RESULT = 2'b11;

    // CONVOLUTION && RELU
    reg signed [399:0] conv_res[23:0][23:0];
    reg signed [399:0] conv_sum;

    // FC
    reg signed [599:0] fc_res [9:0];
    reg signed [599:0] fc_sum;
    integer max_num, ans_idx;

    integer i, j;
    always @(posedge CLK)
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
                    // convolution && relu
                    for (integer k = 0; k < 5; k = k + 1) begin
                        for (integer l = 0; l < 5; l = l + 1) begin
                            if (conv_kernel(k, l) * IMGIN[(k * 5 + l) * 8 +: 8] < 0)
                                conv_sum[(k * 5 + l) * 16 +: 16] <= 0;
                            else
                                conv_sum[(k * 5 + l) * 16 +: 16] <= conv_kernel(k, l) * IMGIN[(k * 5 + l) * 8 +: 8];
                        end
                    end

                    conv_res[X][Y] <= conv_sum;

                    if (X > 23)
                        state <= FULLY_CONNECTED;
                end

                // fc 수정하기
                FULLY_CONNECTED: begin
                    for (integer i = 0; i < 10; i = i + 1) begin
                        for (integer j = 0; j < 24 * 24; j = j + 1) begin
                            fc_sum[(i * 5 + j) * 24 +: 24] <= fc_kernel(i, j) * conv_res[j / 24][j % 24];
                        end
                        fc_res[i] <= fc_sum;

                        if (fc_res[i] > max_num) begin
                            max_num <= fc_res[i];
                            ans_idx <= i;
                        end
                    end

                    state <= RESULT;
                end
                
                RESULT: begin
                    OUT <= ans_idx;
                    DONE <= 1;
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
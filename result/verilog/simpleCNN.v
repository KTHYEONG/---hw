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

// conv, fc의 결과 저장 변수
reg[7:0] conv_res[24:0];

reg signed [7:0] conv_num, fc_num;
integer i, j, sum;

reg[1:0] state;
parameter IDLE = 2'b00, CONVOLUTION = 2'b01, FULLY_CONNECTED = 2'b10;

// state에 따라 동작    
always @(posedge CLK or nRST) 
begin
    if (!nRST)
        begin
            DONE <= 0;
            OUT <= 0;
            state <= IDLE;
        end
    else
        begin
            case (state)
                IDLE:
                begin
                    if (START)
                    begin
                        DONE <= 0;
                        state <= CONVOLUTION;
                    end
                end

                // x=0,y=0 x=0,y=1 ... 각각 200bit --> 총 24 * 24 번 conv 수행
                CONVOLUTION:
                begin
                    sum = 0;
                    for (i = 0; i < 5; i = i + 1)
                    begin
                        for (j = 0; j < 5; j = j + 1)
                        begin
                            conv_num <= conv_kernel(i, j);
                            sum <= sum + conv_num * IMGIN[i * 5 + j];
                        end
                    end

                    // conv 끝난 후 fc 수행
                    state <= FULLY_CONNECTED;
                end

                FULLY_CONNECTED:
                begin
                    fc_num <= fc_kernel(Y, conv_num);
                
                    DONE <= 1;
                    //OUT <= fc_res[3:0];
                    state <= IDLE;
                end
            endcase
        end
end

endmodule

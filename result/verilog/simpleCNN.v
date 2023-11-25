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
                if (START)
                    state <= CONVOLUTION;
            end
            
            CONVOLUTION: begin
                for (i = 0; i < 5; i = i + 1) begin
                    for (j = 0; j < 5; j = j + 1) begin
                        
                    end
                end
                state <= FULLY_CONNECTED;
            end

            FULLY_CONNECTED: begin
                
                state <= CONVOLUTION;
            end
        endcase
    end
end

endmodule
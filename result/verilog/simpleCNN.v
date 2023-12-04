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

    // STATE
    reg [1:0] state;
    parameter IDLE = 2'b00, CONVOLUTION = 2'b01,
            FULLY_CONNECTED = 2'b10;

    // CONVOLUTION && RELU
    reg signed [31:0] conv_res[23:0][23:0];
    reg signed [31:0] conv_temp[4:0][4:0];

    // FC
    reg signed [31:0] fc_res[9:0];
    integer fc_idx;

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
                        
                        // 첫번째 줄 데이터 저장(X = 0, Y = 0)
                        for (integer i = 0; i < 5; i = i + 1) begin
                            for (integer j = 0; j < 5; j = j + 1) begin
                                conv_temp[i][j] <= IMGIN[(i * 5 + j) * 8 +: 8];
                            end
                        end
                    end
                end
                
                CONVOLUTION: begin
                    for (integer i = 0; i < 5; i = i + 1) begin
                        for (integer j = 0; j < 5; j = j + 1) begin
                            conv_temp[i][j] <= IMGIN[(i * 5 + j) * 8 +: 8];
                        end
                    end
                    
                    ConvReluTask(conv_res[X][Y]);

                    if (X == 23 && Y == 23) begin
                        state <= FULLY_CONNECTED;
                        fc_idx <= 0;
                    end
                end

                FULLY_CONNECTED: begin
                    FullyTask(fc_idx, fc_res[fc_idx]);

                    fc_idx <= fc_idx + 1;
                    if (fc_idx == 9) begin
                        ResultTask(OUT);                       
                        DONE <= 1;
                        state <= IDLE;
                    end
                end

            endcase
        end
    end

task ConvReluTask(output reg signed [31:0] res);
reg signed [31:0] sum;
integer i, j;
begin
    // CONVOLUTION
    sum = 0;
    for (i = 0; i < 5; i = i + 1) begin
        for (j = 0; j < 5; j = j + 1) begin
            sum = sum + conv_kernel(i, j) * conv_temp[i][j];
        end
    end
    
    // RELU
    if (sum < 0)
        res = 0;
    else
        res = sum;
end    
endtask

task FullyTask(input integer idx, output reg signed [31:0] res);
reg signed [31:0] sum;
integer i;
begin
    sum = 0;
    for (i = 0; i < 24 * 24; i = i + 1) begin
        sum = sum + fc_kernel(idx, i) * conv_res[i / 24][i % 24];
    end

    res = sum;
end
endtask

task ResultTask(output reg [3:0] out);
integer i, idx;
begin
    idx = 0;
    for (i = 1; i < 10; i = i + 1) begin
        if (fc_res[i] > fc_res[idx])
            idx = i;
    end

    out = idx;
end
endtask

endmodule
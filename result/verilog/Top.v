`timescale 1ns / 1ps

module Top();

reg CLK, nRST, START, X, Y;
reg[199:0] IMGIN;

wire DONE;
wire[3:0] OUT;

simpleCNN sCNN(.CLK(CLK), .nRST(nRST), .START(START), .X(X), .Y(Y), .IMGIN());

always
    #5 CLK = ~CLK;

initial
begin
    CLK = 0;
    #15 START = 1;
    #5 START = 0;
end
    

initial
begin
    nRST = 0; START = 0;
    $monitor("X = %d, Y = %d, DONE = %d, OUT = %d", X, Y, DONE, OUT);
    #10 nRST = 1;
end

// image입력(값 제대로 읽어들이는지 확인)
initial
begin
    $readmemh("image.mem", IMGIN);
    $display("Image data:");
    for (int i = 0; i < 200; i = i + 1)
        $write("%h ", IMGIN[i]);
    $write("\n");
end

/*integer i;
initial
begin
    for (i = 0; i < 200; i = i + 1)
    begin
        $write("%b ", IMGIN[i]);
    end
    $write("\n");
end*/


// label입력

endmodule

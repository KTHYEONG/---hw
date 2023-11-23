`timescale 1ns / 1ps

module Top();

reg CLK, nRST, START;
reg[4:0] X, Y;
reg[199:0] IMGIN;

wire DONE;
wire[3:0] OUT;

simpleCNN sCNN(.CLK(CLK), .nRST(nRST), .START(START), .X(X), .Y(Y), .IMGIN(IMGIN), .DONE(DONE), .OUT(OUT));

always
    #5 CLK = ~CLK;

initial
begin
    CLK = 0; X = 0; Y = 0;
    #30 START = 1;
    #10 START = 0;
end
    
initial
begin
    nRST = 0; START = 0;
    #20 nRST = 1;
end

// image 입력
integer fd;
always@(START)
begin
    if (START == 1)
    begin
        fd = $fopen("image.mem", "r");
        if (fd == 0)
        begin
            $display("Error: file cannot opend");
            $finish();
        end
        
        while(!($feof(fd))) begin
            #10 $fscanf(fd, "%50h", IMGIN);
            $display("image: %h", IMGIN);
            Y = Y + 1;
            if (Y == 29)
            begin
                X = X + 1;
                Y = 0;
            end
        end
        $fclose(fd);
    end
end

// label 입력
reg[3:0] label[99:0];
integer fr, i;
initial
begin
    i = 0;
    fr = $fopen("label.mem", "r");
    while (!($feof(fr)))
    begin
        $fscanf(fr, "%d", label[i]);
        i = i + 1;
    end
    i = 0;
    $fclose(fr);
end

// 정확도 체크
integer err;
initial err = 0;
always @(DONE)
begin
    if (DONE == 1)
    begin
        if (label[i] != OUT)
            err = err + 1;
        i = i + 1;
    end
end

initial
begin
    //#2000 $display("Accuracy: %d%%\n", (100 - err) / 100 * 100); 
    #3000 $finish;
end

endmodule
`timescale 1ns / 1ps

module stimulus();

reg CLK, nRST, START;
reg [4:0] X, Y;
reg [199:0] IMGIN;

wire DONE;
wire[3:0] OUT;

simpleCNN sCNN(.CLK(CLK), .nRST(nRST), .START(START), .X(X), .Y(Y), .IMGIN(IMGIN), .DONE(DONE), .OUT(OUT));

// 클럭 변화
always
    #5 CLK = ~CLK;

initial
begin
    CLK = 0; nRST = 0; START = 0;
    #20 nRST = 1;
    #10 START = 1;
    repeat(99) #5900 START = ~START;
end

// START 신호가 1이되면 IMGIN에 데이터 저장시작
reg check, first;
always@(posedge CLK or negedge nRST)
begin
    if (!nRST) begin
        X <= 0;
        Y <= 0;
        first <= 1;
        check <= 0;
    end
    else if (START) begin
        imgst(first);
        first <= 0;
        #5 START <= 0;
        check <= 1;
        #5 Y <= Y + 1;
    end

    if (check) begin
        imgst(first);

        // X, Y
        if (Y < 23) begin
            Y <= Y + 1;
        end
        else begin
            Y <= 0;
            if (X < 23) begin
                X <= X + 1;
            end
            else begin
                X <= 0;
                check <= 0;
                first <= 1;
                img_idx <= img_idx + 1;
            end
        end
    end
end

// IMGIN에 데이터 저장
// first -> 각 이미지마다 처음에 저장되는 부분에 에러가 있어 따로 처리
task imgst(input reg first);
integer i, j;
begin
    for (i = 0; i < 5; i = i + 1) begin
        for (j = 0; j < 5; j = j + 1) begin
            if (first)
                IMGIN[(i * 5 + j) * 8 +: 8] = MNIST_image[img_idx][(X + i) * 28 + (Y + j)];
            else
                IMGIN[(i * 5 + j) * 8 +: 8] = MNIST_image[img_idx][(X + i) * 28 + (Y + 1 + j)];
        end
    end
end
endtask

// MNIST 데이터를 저장
reg [7:0] MNIST_image[99:0][783:0];
reg [7:0] pixel;
integer fd, i;
integer img_idx;
initial
begin
    fd = $fopen("image.mem", "r");
    if (fd == 0) begin
        $display("Error: file cannot be opened");
        $finish();
    end
    
    // 100개의 MNIST 데이터 읽어들이기
    img_idx = 0;
    while (img_idx < 100) begin
        for (i = 0; i < 784; i = i + 1) begin
            $fscanf(fd, "%2h", pixel);
            MNIST_image[img_idx][i] = pixel;
        end
        img_idx = img_idx + 1;
    end
    img_idx = 0;
    $fclose(fd);
end

// label 입력
reg [3:0] label[99:0];
integer fr;
initial
begin
    i = 0;
    fr = $fopen("label.mem", "r");
    while (!($feof(fr)))
    begin
        $fscanf(fr, "%d", label[i]);
        i = i + 1;
    end
    $fclose(fr);
end

// 정확도 체크
integer err, label_idx;
initial
begin
    err = 0;
    label_idx = 0;
end
always @(DONE)
begin
    if (DONE == 1)
    begin
        if (label[label_idx] != OUT)
            err = err + 1;
        //$display("%d OUT/ANS: %d/%d", label_idx, OUT, label[label_idx]);
        label_idx = label_idx + 1;
    end
end

// Accuracy 계산 
always@(label_idx)
begin
    if (label_idx == 100) begin
        $display("Accuracy: %.2f%%\n", (100.0 - err) / 100.0 * 100.0); 
        $finish;
    end    
end

endmodule
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

	input			CLK;
	input			nRST;
	input			START;
	input			X;
	input			Y;
	input	[199:0]	IMGIN;
	
	output			DONE;
	output	[3:0]	OUT;


    `include "kernel.vh"

	// 상태를 나타내기 위한 state
	reg[1:0] state;
	parameter IDLE = 2'b00;
	parameter CONVOLUTION = 2'b01;
	parameter FULLY_CONNECTED = 2'b10;

	// convolution 및 fc의 끝나는 조건을 체크하기 위한 cnt
	reg[10:0] conv_cnt;
	reg[10:0] fc_cnt;

	reg[7:0] conv_res, fc_res, image_pixel;
	reg[7:0] kernel[4:0][4:0];

	// state에 따라 동작	
	always @(posedge CLK or negedge nRST) 
	begin
		if (!nRST)
			begin
				DONE<=0;
				OUT<=4'b0;
				state<=IDLE;
				conv_cnt<= 11'b0;
				fc_cnt<=11'b0;
			end
		else
		begin
			case (state)
				IDLE:
				begin
					if (START)
					begin
						state <= CONVOLUTION;
						conv_cnt <= 11'b0;
					end
				end

				CONVOLUTION:
				begin 
					image_pixel <= IMGIN[X + Y * 5];
					conv_res <= conv_kernel(image_pixel, kernel);
					conv_cnt <= conv_cnt + 1;

					// convolution이 끝나면 state -> fc로 변환
					if (conv_cnt == 576)
					begin 
						state <= FULLY_CONNECTED;
						fc_cnt <= 11'b0;
					end
				end

				FULLY_CONNECTED:
				begin
					fc_res <= fc_kernel(conv_res, kernel);
					fc_cnt <= fc_cnt + 1;
					
					if (fc_cnt == 576)
					begin
						DONE <= 1;
						OUT <= fc_res[3:0];
						state <= IDLE;
					end
				end

			endcase
		end
	end

endmodule

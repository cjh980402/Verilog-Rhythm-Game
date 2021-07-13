`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:42:34 11/27/2020 
// Design Name: 
// Module Name:    fnd_array 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module fnd_array (clk_1k, thous, hundreds, tens, ones, seg_com, seg_data);
input clk_1k;
input [3:0] thous; // õ�� �ڸ� bcd, fnd 1��° �ڸ�
input [3:0] hundreds; // ���� �ڸ� bcd, fnd 2��° �ڸ�
input [3:0] tens; // ���� �ڸ� bcd, fnd 3��° �ڸ�
input [3:0] ones; // ���� �ڸ� bcd, fnd 4��° �ڸ�
output reg [3:0] seg_com = 4'b0;
output reg [7:0] seg_data = 8'b0;

reg [1:0] cnt = 2'b00;

wire [7:0] seg_thous, seg_huns, seg_tens, seg_ones;
fnd_decoder f1000(thous, seg_thous);
fnd_decoder f100(hundreds, seg_huns);
fnd_decoder f10(tens, seg_tens);
fnd_decoder f1(ones, seg_ones);

always @ (posedge clk_1k) begin
	cnt <= cnt + 1 ;
end

// seg_com�� ���� 0�� element�� ���
always @ (posedge clk_1k) begin
	case (cnt)
		0: begin
			seg_com <= 4'b0111;
			seg_data <= seg_thous;
		end
		1: begin
			seg_com <= 4'b1011;
			seg_data <= seg_huns;
		end
		2: begin
			seg_com <= 4'b1101;
			seg_data <= seg_tens;
		end
		3: begin
			seg_com <= 4'b1110;
			seg_data <= seg_ones;
		end
	endcase
end

endmodule

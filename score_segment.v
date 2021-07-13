`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:41:28 11/27/2020 
// Design Name: 
// Module Name:    score_segment 
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
module score_segment(clk_1k, binary, seg_com, seg_data);
input clk_1k;
input [14:0] binary; // 0 ~ 9999 ����
output [3:0] seg_com;
output [7:0] seg_data;

reg [3:0] thous, hundreds, tens, ones;
// integer i;
reg [3:0] i;
always @ (binary) begin
	//set 1000's, 100's, 10's, and 1's to 0
	thous = 4'd0;
	hundreds = 4'd0;
	tens = 4'd0;
	ones = 4'd0;
	for (i=15; i>=1; i=i-1) begin // 1������ �������� ��Ʈ �̵� = �� 2��
	// �� �ڸ����� 5�̻��� �� 3�� ������
	// ���� : 5*2 = 10�ε� BCD���� 10�� �Ƿ��� ���� �� = 16�̹Ƿ� 2���Ҷ� 16�� �Ǵ� 8�� �������
		if (thous >= 5)
			thous = thous + 3;
		if (hundreds >= 5)
			hundreds = hundreds + 3;
		if (tens >= 5)
			tens = tens + 3;
		if (ones >= 5)
			ones = ones + 3;
		// 1ĭ�� �̵�
		thous = thous << 1;
		thous[0] = hundreds[3];
		hundreds = hundreds << 1;
		hundreds[0] = tens[3];
		tens = tens << 1;
		tens[0] = ones[3];
		ones = ones << 1;
		ones[0] = binary[i-1];
	end
end

fnd_array fa(clk_1k, thous, hundreds, tens, ones, seg_com, seg_data);

endmodule

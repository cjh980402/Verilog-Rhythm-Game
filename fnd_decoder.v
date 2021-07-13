`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:42:56 11/27/2020 
// Design Name: 
// Module Name:    fnd_decoder 
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
module fnd_decoder(bcd, out);
input [3:0] bcd;
output reg [7:0] out;

always @ (bcd) begin
	case (bcd) // 10���� 0~9
		4'b0000: out = 8'b11111100;
		4'b0001: out = 8'b01100000;
		4'b0010: out = 8'b11011010;
		4'b0011: out = 8'b11110010;
		4'b0100: out = 8'b01100110;
		4'b0101: out = 8'b10110110;
		4'b0110: out = 8'b10111110;
		4'b0111: out = 8'b11100000;
		4'b1000: out = 8'b11111110;
		4'b1001: out = 8'b11110110;
		default: out = 8'b00000000;
	endcase
end
endmodule

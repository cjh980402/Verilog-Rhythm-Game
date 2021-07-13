`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:58:17 12/04/2020 
// Design Name: 
// Module Name:    divide_clk 
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
module divide_clk(before_clk, rstn, cnt_max, state, line1, after_clk);
input before_clk, rstn;
input [2:0] state, line1;
input [8:0] cnt_max;
output reg after_clk = 1'b0;

reg [8:0] cnt_divide = 9'b0;
always @ (posedge before_clk or negedge rstn) begin // 분주 로직
	if(~rstn) begin
		cnt_divide <= 9'b0;
		after_clk <= 1'b0;
	end
	else if(cnt_divide >= cnt_max) begin
		cnt_divide <= 9'b0;
		after_clk <= ~after_clk; 
	end
	else if(state >= line1) begin // 출력이 시작된 이후부터 분주 시작
		cnt_divide <= cnt_divide + 1;
	end
end

endmodule

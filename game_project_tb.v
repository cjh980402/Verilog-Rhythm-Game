`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:45:27 11/27/2020
// Design Name:   game_project
// Module Name:   D:/Xilinx/game_project/game_project_tb.v
// Project Name:  game_project
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: game_project
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module game_project_tb;

	// Inputs
	reg clk_1Mhz;
	reg rstn;

	// Outputs
	wire lcd_e;
	wire lcd_rs;
	wire lcd_rw;
	wire [7:0] lcd_data;

	// Instantiate the Unit Under Test (UUT)
	game_project uut (
		.clk_1Mhz(clk_1Mhz), 
		.rstn(rstn), 
		.lcd_e(lcd_e), 
		.lcd_rs(lcd_rs), 
		.lcd_rw(lcd_rw), 
		.lcd_data(lcd_data)
	);

	initial begin
		// Initialize Inputs
		clk_1Mhz = 0;
		rstn = 1;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule


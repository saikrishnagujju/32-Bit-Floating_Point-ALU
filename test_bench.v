`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.12.2021 15:09:13
// Design Name: 
// Module Name: test_bench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module test_bench;
//All inputs
reg [7:0] X;            //This is the input X
reg [3:0] sel;          //This is for selecting function
reg clk;

//Outputs
wire [31:0] out;         //This is output in 32-bit IEEE-754 format


//Instantiating the main module
main_module M1 (clk, X, sel, out);

initial begin 
    clk = 1'b0;
end

always begin
    #5 clk = ~clk;
end

initial begin
    #5 sel = 4'b0000;  X = 8'b00000011;
    #5 sel = 4'b0001;  X = 8'b00000011;
    #5 sel = 4'b0010;  X = 8'b00000011;
    #5 sel = 4'b0011;  X = 8'b00000011;
    #5 sel = 4'b0100;  X = 8'b00000011;
    #5 sel = 4'b0101;  X = 8'b00000011;
    #5 sel = 4'b0110;  X = 8'b00000011;
    #5 sel = 4'b0111;  X = 8'b00000011;
    #5 sel = 4'b1000;  X = 8'b00000011;
end

endmodule

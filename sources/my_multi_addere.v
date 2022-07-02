`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/08 21:38:15
// Design Name: 
// Module Name: my_multi_addere
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


module my_multi_addere(
  input clk,
  input wire signed [15:0] a,
  input wire signed [15:0] b,
  input wire signed[35:0] c,
  output reg signed [35:0] p
    );

reg signed [35:0] m ;
//reg signed [15:0] a, b ;

always @(posedge clk)
begin
  // a1 <= a;
  // b1 <= b;
  m <= a*b;
  p <= m+c;
end
endmodule

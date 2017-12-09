// verilog register file
// synchronous writeEN, asynchronous read
// Two read addresses (SR1, SR2), one write address (DR)
`timescale 1ns/100ps
module regfile8x16
  (input clk,
   input rst,
   input writeEN,
   input [2:0] wrAddr,//=DR
   input [15:0] wrData, //=Buss
   input [2:0] rdAddrA,//=SR1
   output [15:0] rdDataA,//=Ra
   input [2:0] rdAddrB,//=SR2
   output [15:0] rdDataB);//=Rb

   reg [15:0] 	 regfile [0:7];

   assign rdDataA = regfile[rdAddrA];
   assign rdDataB = regfile[rdAddrB];

   always_ff @(posedge clk) begin
      if (rst) begin
	 	regfile[0] <= 0;
	 	regfile[1] <= 0;
	 	regfile[2] <= 0;
	 	regfile[3] <= 0;
	 	regfile[4] <= 0;
	 	regfile[5] <= 0;
	 	regfile[6] <= 0;
	 	regfile[7] <= 0;
      end else begin
	 	if (writeEN) regfile[wrAddr] <= wrData;
      end 
   end
endmodule

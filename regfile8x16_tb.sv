`timescale 1ns/100ps
module regfile8x16_tb();
	
	bit clk;

	reg [2:0] wrAddr, rdAddrA, rdAddrB;
	reg [15:0] rdDataA, rdDataB, wrData;
	reg rst, writeEN;
	

	regfile8x16 DUT(
		.clk(clk),
		.rst(rst),
		.writeEN(writeEN),
		.wrAddr(wrAddr),
		.wrData(wrData),
		.rdAddrA(rdAddrA),
		.rdAddrB(rdAddrB),
		.rdDataA(rdDataA),
		.rdDataB(rdDataB)
	);
		
	initial forever #10ns clk = ~clk;
	initial begin
		wrAddr	= 0;	
		wrData	= 0;	
		rdAddrA	= 0;	
		rdAddrB	= 0;	
		rst		= 1;
		#40
	
		rst		= 0;
		#40 
		if(rdDataA != 0 ) 
			$display("ERROR rdDataA should be 0 but is %d",rdDataA);
		else if(rdDataB != 0 ) 
			$display("ERROR rdDataB should be 0 but is %d",rdDataB);
		else
			$display("Reset is Successful!");
		writeEN	= 1;
		wrAddr	= 2;	
		wrData	= 15;	
		rdAddrA	= 2;	
		rdAddrB	= 0;
		#40
		writeEN = 0;
		#20
		if(rdDataA != 15 ) 
			$display("ERROR rdDataA should be 15 but is %d",rdDataA);
		else if(rdDataB != 0 ) 
			$display("ERROR rdDataB should be 0 but is %d",rdDataB);
		else
			$display("Data write and read is Successful!");
	
		writeEN	= 1;
		wrAddr	= 4;	
		wrData	= 8;	
		rdAddrA	= 4;	
		rdAddrB	= 2;
		#40
		writeEN = 0;
		#20
		if(rdDataA != 8 ) 
			$display("ERROR rdDataA should be 8 but is %d",rdDataA);
		else if(rdDataB != 15 ) 
			$display("ERROR rdDataB should be 15 but is %d",rdDataB);
		else
			$display("Data write and read is Successful!");
	

	end


	
		

endmodule

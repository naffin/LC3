`timescale 1ns/100ps
module eab_tb();

	reg [10:0] IR;
	reg [15:0] Ra, PC;
	reg [1:0] selEAB2;
	reg selEAB1;
	wire [15:0] eabOut;

	eab DUT(
		.IR(IR), 
		.Ra(Ra),
		.PC(PC),
		.selEAB2(selEAB2),
		.selEAB1(selEAB1),
		.eabOut(eabOut)
	);

	initial begin
		IR = 11'b00000111111;
		Ra = 16'h0000;
		PC = 16'h000F;
		selEAB1 = 0;
		selEAB2 = 2'b10;
		#20
		$display("IR = %b",IR);
		$display("PC = %b",PC);	
		// eabOut = PC + IR[8:0] = 1010000
		if(eabOut != 16'b0000000001001110)
			$display("ERROR: eabOut should be 0000000001001110 but instead is %B",eabOut);

		IR = 11'b00000111111;
		Ra = 16'h0000;
		PC = 16'h00FF;
		selEAB1 = 0;
		selEAB2 = 2'b10;
		#20
		$display("IR = %b",IR);
		$display("PC = %b",PC);	
		// eabOut = PC + IR[8:0] = 1010000
		if(eabOut != 318)
			$display("ERROR: eabOut should be 318 but instead is %d",eabOut);
		
		IR = 11'b00000111111;
		Ra = 16'h0008;
		PC = 16'h00FF;
		selEAB1 = 1;
		selEAB2 = 2'b10;
		#20
		$display("IR = %b",IR);
		$display("PC = %b",PC);	
		// eabOut = PC + IR[8:0] = 1010000
		if(eabOut != 71)
			$display("ERROR: eabOut should be 71 but instead is %d",eabOut);
		
		IR = 11'b00000111111;
		Ra = 16'h0008;
		PC = 16'h00FF;
		selEAB1 = 1;
		selEAB2 = 2'b00;
		#20
		$display("IR = %b",IR);
		$display("PC = %b",PC);	
		// eabOut = PC + IR[8:0] = 1010000
		if(eabOut != 8)
			$display("ERROR: eabOut should be 8 but instead is %d",eabOut);

		IR = 11'b11000000001; // = -511 after sign extension
		Ra = 16'h0008;// = 8
		PC = 16'h000F;// = 15
		selEAB1 = 0;
		selEAB2 = 2'b11;
		#20
		$display("IR = %d",IR);
		$display("PC = %b",PC);	
		$display("eabOut = %d",$signed(eabOut));
		if($signed(eabOut) != -496)
			$display("ERROR: eabOut should be -496 but instead is %d",eabOut);


		$finish;

	end

endmodule	

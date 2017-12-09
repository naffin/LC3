module eab(IR, Ra, PC, selEAB1, selEAB2, eabOut);
    input [10:0] IR;
    input [15:0] Ra;
    input [15:0] PC;
    input selEAB1;
    input [1:0] selEAB2;
    output [15:0] eabOut;
    
    wire [15:0] adder1, adder2, sext0, sext1, sext2;
    
    assign sext0 = {{5{IR[10]}}, IR[10:0]}; 
    assign sext1 = {{7{IR[8]}}, IR[8:0]}; 
    assign sext2 = {{9{IR[5]}}, IR[5:0]};
	
	assign adder1 = (selEAB2 == 0)? 16'h0000:(selEAB2 == 1)? sext2:(selEAB2 == 2)? sext1:sext0;
	assign adder2 = (selEAB1 == 0)? PC:Ra;

	assign eabOut = adder1 + adder2;

endmodule

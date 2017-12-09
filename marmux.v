//
//
//

module marmux(
	  input [7:0] IR,
	  input [15:0] eabOut,
	  input selMAR,
	  output [15:0] MARMUXOut
	);

	wire sext;
	assign sext = {{8{IR[7]}}, IR[7:0]};
	assign MARMUXOut = (selMAR == 0) ? eabOut : sext;

endmodule

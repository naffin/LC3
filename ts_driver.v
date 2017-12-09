module ts_driver (din, dout, en);
	input [15:0] din;
	output [15:0] dout;
	input en;

	assign dout = en ? din : 16'hZZZZ;
endmodule
	
	

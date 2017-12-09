// Program counter Verilog
//

module pc(
	input 	clk, rst, ldPC,
	input 	[1:0] selPC,
	input 	[15:0] eabOut,
	input 	[15:0] PCOut,
	output 	[15:0] Buss
	);

	wire 	[15:0] pcInc;
	wire 	[15:0] muxOut;
	reg		[15:0] PCreg;
	
	assign pcInc = PCOut + 1;
	// 3-to-1 mux
	assign muxOut = (selPC == 0)? pcInc : (selPC == 1)? eabOut : PCOut;
	assign PCOut = PCreg;
	
	
	always_ff@ (posedge clk) begin// synchronous reset
		if (rst) begin
			PCreg <= 0;
		end
		else if (ldPC) begin
			PCreg <= muxOut;
		end
	end

endmodule

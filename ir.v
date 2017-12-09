// IR Verilog
//

module ir(
	input 	clk, rst, ldIR,
	input 	[15:0] Buss,
	output reg [15:0] IR
	);
	
	always@ (posedge clk) begin// synchronous reset
		if (rst) begin
			IR <= 16'b0;
		end
		else if (ldIR) begin
			IR = Buss;
		end
	end

endmodule

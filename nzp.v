// NZP flags verilog


module nzp(
	input 	clk, rst, flagWE,
	input 	[15:0] Buss,
	output reg N, Z, P
	);
	
	
	always@ (posedge clk) begin// synchronous reset
		if (rst) begin
			N <= 1'b0;
			P <= 1'b0;
			Z <= 1'b0;
		end
		else if (flagWE) begin
			if(Buss[15] == 1'b1) begin
				N <= 1;
				P <= 0;
				Z <= 0;
			end
			else if (Buss == 0) begin
				N <= 0;
				P <= 0;
				Z <= 1;
			end
			else begin
				N <= 0;
				P <= 1;
				Z <= 0;
			end
		end
	end

endmodule

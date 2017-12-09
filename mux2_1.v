module mux21 (sel, d, q);
	input [1:0] d;
	input sel;
	output q;

	assign q = sel ? d[1]:d[0];

endmodule 

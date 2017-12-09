// 16 bit ALU
// add, and, not, pass
//

package bit16;
	parameter int dataWidth = 16;
	typedef logic [dataWidth-1:0] data_t;
endpackage // bit16

module alu (
	  input [4:0] IR,
	  input IR_5,
	  input [1:0] ALUctrl,
	  input [15:0] Rb, Ra,
	  output [15:0] ALUOut
	);
	
	import bit16::*;

	data_t sext;
	always_comb assign sext = {{11{IR[4]}},IR[4:0]};
	data_t opb;
	assign opb = IR_5 ? sext : Rb;

	assign ALUOut[15:0] = (ALUctrl == 2'b00) ? (Ra + opb) : (ALUctrl == 2'b01) ? (Ra & opb) : (ALUctrl == 2'b10) ? ~Ra : Ra; 

endmodule

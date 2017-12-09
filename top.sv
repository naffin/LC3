// data path verilog
//

module top(
	inout [15:0] Buss,
	input rst, clk
	);
	reg enaMARM, enaPC, enaMDR, enaALU,
	  flagWE, ldIR, ldPC, selEAB1,
	  selMAR, regWE;
	reg [1:0] selEAB2, selPC;
	reg [2:0] DR, SR1, SR2;
	reg [1:0] ALUctrl;	
	wire N, Z, P, TB;
	wire [15:0] eabOut, Ra, Rb;
	wire [15:0] PCOut, ALUOut;
	wire [15:0] IR, MARMUXOut, mdrOut;
	wire [7:0] zext;
	reg selMDR, ldMDR, ldMAR, memWE;

	assign zext =  {{8{IR[7]}}, IR[7:0]};
	assign MARMUXOut = (selMAR) ? zext : eabOut;

	pc pc_1 (.*);
	eab eab_1(.IR(IR[10:0]), .PC(PCOut), .*);
	regfile8x16 regfile(.*, .writeEN(regWE), .wrAddr(DR), .wrData(Buss), .rdAddrA(SR1),
		 .rdAddrB(SR2), .rdDataA(Ra), .rdDataB(Rb));
	nzp nzp_1 (.*);
	alu alu_1(.IR(IR[4:0]), .IR_5(IR[5]), .*);
	ir ir_1(.*);
	memory my_mem(.reset(rst), .*);

	//===========================
	// tri-state buffers
	//===========================
	
	ts_driver tsd_1(.din(MARMUXOut), .dout(Buss), .en(enaMARM));
	ts_driver tsd_2(.din(PCOut), .dout(Buss), .en(enaPC));
	ts_driver tsd_3(.din(ALUOut), .dout(Buss), .en(enaALU));
	ts_driver tsd_4(.din(mdrOut), .dout(Buss), .en(enaMDR));
	
	parameter size = 5;

	typedef enum {IDLE, FET0, FET1, FET2, DECODE, AND, ADD, NOT, 
				JSR0, JSR1, JSRR1, BR, LD0, LD1, LD2, ST0, ST1, ST2, JMP, TRAP0, TRAP1, TRAP2} state_type;
	state_type state, next_state; 

	wire [3:0] opCode;
	assign opCode = IR[15:12];
	assign TB = (N & IR[11]) |  (Z & IR[10]) | (P & IR[9]);

	// State Machine
	always @ (state or opCode) begin
	 //next_state = 5'b00001;
	 next_state = FET0;
	 unique case(state) 
	   	IDLE :  	next_state = FET0;
	   	FET0:		next_state = FET1; 
	   	FET1:		next_state = FET2; 
	   	FET2:		next_state = DECODE;
	   	DECODE:		unique case(opCode)
						4'b0000:	next_state = BR;  
						4'b0001:	next_state = ADD; 
						4'b0010:	next_state = LD0; 
						4'b0011:	next_state = ST0; 
						4'b0100:	next_state = JSR0; 
						4'b0101:	next_state = AND; 
						4'b0110:	next_state = FET0; // not implemented LDR; 
						4'b0111:	next_state = FET0; // not implemented STR; 
						4'b1000:	next_state = FET0; // not implemented RTI; 
						4'b1001:	next_state = NOT; 
						4'b1010:	next_state = FET0; // not implemented LDI; 
						4'b1011:	next_state = FET0; // not implemented STI; 
						4'b1100:	next_state = JMP; 
						4'b1101:	next_state = FET0; // RESERVED, treat as a NOP; 
						4'b1110:	next_state = FET0; // not implemented LEA; 
						4'b1111:	next_state = TRAP0; 
						default: 	next_state = FET0;
					endcase 
		ADD: 		next_state = FET0;
		AND: 		next_state = FET0;
		NOT: 		next_state = FET0;
		LD0: 		next_state = LD1;
		LD1: 		next_state = LD2;
		LD2: 		next_state = FET0;
		ST0: 		next_state = ST1;
		ST1: 		next_state = ST2;
		ST2: 		next_state = FET0;
		BR: 		next_state = FET0;
		JMP: 		next_state = FET0;
		JSR0: begin
			if(IR[11] == 1) next_state = JSR1;
			else next_state = JSRR1;
			end
		JSR1: 		next_state = FET0;
		JSRR1: 		next_state = FET0;
		TRAP0: 		next_state = FET0;
		
	   default : next_state = FET0;
	  endcase
	end
	
	//----------------Sequential Logic--------------------
	always @ (posedge clk) begin 
	  if (rst == 1'b1) begin
	    state <=    IDLE;
	  end else begin
	    state <=    next_state;
	  end
	end

	//--------------------Output Logic--------------------
	always @ (state) begin
		if (rst == 1'b1) begin
			enaPC <= 1'b0;
			ldMAR <= 1'b0;
			ldPC  <= 1'b0;
			ldMDR <= 1'b0;
			enaMDR <= 1'b0;
			ldIR <= 1'b0;
			enaALU <= 1'b0;
			enaMARM <= 1'b0;	
			regWE <= 1'b0;
			// Don't think anything needs to happend here
		end
		else begin
		// reset signals
		enaPC <= 1'b0;
		ldMAR <= 1'b0;
		ldPC  <= 1'b0;
		ldMDR <= 1'b0;
		enaMDR <= 1'b0;
		ldIR <= 1'b0;
		enaALU <= 1'b0;
		enaMARM <= 1'b0;	
		regWE <= 1'b0;
		memWE <= 1'b0;
		  unique case(state)
			IDLE : 	begin
					// nothing here
				end
	   		FET0:  	begin
					enaPC <= 1'b1;
					ldMAR <= 1'b1;
				end
	   		FET1:  	begin
					selPC <= 2'b00;
					ldPC  <= 1'b1;
					selMDR<= 1'b1;
					ldMDR <= 1'b1;
				end	
	   		FET2:  	begin
					enaMDR<= 1'b1;
					ldIR  <= 1'b1;
				end
	   		DECODE:	begin
					// no outputs	
				end
	   		ADD:begin
					SR1 <= IR[8:6];	
					SR2 <= IR[2:0];	
					DR <= IR[11:9];
					ALUctrl <= 2'b00;
					enaALU	<= 1'b1;	
					regWE <= 1'b1;	
					flagWE <= 1'b1;	
				end
	   		NOT:begin
					SR1 <= IR[8:6];	
					DR <= IR[11:9];
					ALUctrl <= 2'b10;
					enaALU	<= 1'b1;
					regWE <= 1'b1;	
					flagWE <= 1'b1;	
				end
			AND:begin
					SR1 <= IR[8:6];	
					SR2 <= IR[2:0];	
					DR <= IR[11:9];
					ALUctrl <= 2'b01;
					enaALU	<= 1'b1;
					regWE <= 1'b1;	
					flagWE <= 1'b1;	
				end
			LD0:begin // MEMORY to REGFILE
					// send address to memory
					selEAB2 <= 2'b10; 	// load in sign extended PCoffset9
					selEAB1 <= 1'b0;  	// load in current PC
					selMAR <= 1'b0; 	// select output of PC+PCoffset9 to drive Buss
					enaMARM <= 1'b1;	
					ldMAR <= 1'b1;
				end
			LD1:begin
					// write data from memory to MDR reg
					selMDR <= 1'b1;		// sel data from memory
					ldMDR  <= 1'b1;		// load data from memory into MDR
				end
			LD2:begin
					// write data from MDR to regfile
					regWE <= 1'b1;	
					enaMDR <= 1'b1;		// drive MDR data onto bus
					DR <= IR[11:9];
					flagWE <= 1'b1;	
				end
			ST0:begin //REGFILE to MEMORY
					// send address to memory
					selEAB2 <= 2'b10; 	// load in sign extended PCoffset9
					selEAB1 <= 1'b0;  	// load in current PC
					selMAR <= 1'b0; 	// select output of PC+PCoffset9 to drive Buss
					enaMARM <= 1'b1;	
					ldMAR <= 1'b1;
				end
			ST1:begin
					// write data from regfile to memory
					enaALU <= 1'b1;		
					ALUctrl <= 2'b11;
					selMDR <= 1'b0;		// sel data from Buss
					ldMDR  <= 1'b1;	
					SR1 <= IR[11:9];
				end
			ST2:begin
					memWE <= 1'b1;
				end
			BR:begin
					selPC <= 2'b01;
					selEAB2 <= 2'b10;		
					selEAB1 <= 1'b0;	
					ldPC <= TB;	
				end
			JMP:begin // loads next instruction address from regfile
					SR1 <= IR[8:6];
					selPC <= 2'b01;
					selEAB2 <= 2'b00;		
					selEAB1 <= 1'b1;	
					ldPC <= 1'b1;	
				end
			JSR0:begin // loads current PC value into memory at reg[7]
					DR <= 3'b111;
					regWE <= 1'b1;	
					enaPC <= 1'b1;
				end
			JSR1:begin // loads given sext 11 bit addr into PC
					selPC <= 2'b01;
					selEAB1 <= 1'b0;	
					selEAB2 <= 2'b11;		
					ldPC <= 1'b1;	
				end
			JSRR1:begin 
					selPC <= 2'b01;
					selEAB1 <= 1'b1;	
					selEAB2 <= 2'b00;		
					ldPC <= 1'b1;	
				end
			TRAP0:begin 
					selPC <= 2'b01;
					selEAB1 <= 1'b1;	
					selEAB2 <= 2'b00;		
					ldPC <= 1'b1;	
				end
		   default : begin
					end
		  endcase
		end
	end // End Of Block OUTPUT_LOGIC

endmodule
	
	
		

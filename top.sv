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

	typedef enum logic [3:0] { 
				AND=4'b0101, 
				ADD=4'b0001, 
				NOT=4'b1001, 
				JSR=4'b0100,
				BR=4'b0000, 
				LD=4'b0010,
				LDI=4'b1010,
				LDR=4'b0110,
				LEA=4'b1110,
				ST=4'b0011,
				STI=4'b1011,
				STR=4'b0111, 
				JMP=4'b1100, 
				TRAP=4'b1111,
				RTI=4'b1000,
				RESERVED=4'b1101} Opcode;

	typedef enum {IDLE, FET0, FET1, FET2, DECODE,
				AND0, ADD0, NOT0, JSR0, JSR1, JSRR1,
				BR0, LD0_ST0, LD1, LD2, LDI0_STI0, LDI1_STI1, LDI2_STI2, 
				LDR0_STR0, LEA0, ST1, ST2, JMP0, 
				TRAP0, TRAP1, TRAP2, RTI0} State;

	State state, next_state; 

	wire Opcode opCode;
	assign opCode = IR[15:12];
	assign TB = (N & IR[11]) |  (Z & IR[10]) | (P & IR[9]);

	// State Machine
	always @ (state or opCode) begin
	 next_state = FET0;
	 case(state) 
	   	IDLE :  	next_state = FET0;
	   	FET0:		next_state = FET1; 
	   	FET1:		next_state = FET2; 
	   	FET2:		next_state = DECODE;
	   	DECODE:		case(opCode)
						BR     :	next_state = BR0;  
						ADD    :	next_state = ADD0; 
						LD 	   :	next_state = LD0_ST0; 
						ST 	   :	next_state = LD0_ST0;  
						JSR	   :	next_state = JSR0; 
						AND    :	next_state = AND0; 
						LDR	   :	next_state = LDR0_STR0; 
						STR	   :	next_state = LDR0_STR0; 
						RTI	   :	next_state = FET0; // treat as a NOP 
						NOT    :	next_state = NOT0; 
						LDI	   :	next_state = LDI0_STI0; 
						STI	   :	next_state = LDI0_STI0;
						JMP    :	next_state = JMP0; 
						RESERVED:	next_state = FET0; // RESERVED, treat as a NOP; 
						LEA	   :	next_state = LEA0; 
						TRAP   :	next_state = TRAP0; 
						default: 	next_state = FET0;
					endcase 
		ADD0: 		next_state = FET0;
		AND0: 		next_state = FET0;
		NOT0: 		next_state = FET0;
		LD0_ST0:begin
			if(opCode == LD)
			 	next_state = LD1;
			if(opCode == ST)
			 	next_state = ST1;
			end
		LD1: 		next_state = LD2;
		LD2: 		next_state = FET0;
		ST1: 		next_state = ST2;
		ST2: 		next_state = FET0;
		LDI0_STI0:	next_state = LDI1_STI1;
		LDI1_STI1:	next_state = LDI2_STI2;
		LDI2_STI2: begin	
			if(opCode == LDI)
				next_state = LD1;
			if(opCode == STI)
				next_state = ST1;
			end
		LDR0_STR0 : begin	
			if(opCode == LDR)
				next_state = LD1;
			if(opCode == STI)
				next_state = ST1;
			end
		BR0: 		next_state = FET0;
		JMP0: 		next_state = FET0;
		JSR0: begin
			if(IR[11] == 1) next_state = JSR1;
			else next_state = JSRR1;
			end
		JSR1: 		next_state = FET0;
		JSRR1: 		next_state = FET0;
		TRAP0: 		next_state = FET0;
		LEA0: 		next_state = FET0;
		
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
	   		ADD0:begin
					SR1 <= IR[8:6];	
					SR2 <= IR[2:0];	
					DR <= IR[11:9];
					ALUctrl <= 2'b00;
					enaALU	<= 1'b1;	
					regWE <= 1'b1;	
					flagWE <= 1'b1;	
				end
	   		NOT0:begin
					SR1 <= IR[8:6];	
					DR <= IR[11:9];
					ALUctrl <= 2'b10;
					enaALU	<= 1'b1;
					regWE <= 1'b1;	
					flagWE <= 1'b1;	
				end
			AND0:begin
					SR1 <= IR[8:6];	
					SR2 <= IR[2:0];	
					DR <= IR[11:9];
					ALUctrl <= 2'b01;
					enaALU	<= 1'b1;
					regWE <= 1'b1;	
					flagWE <= 1'b1;	
				end
			LD0_ST0:begin // MEMORY to REGFILE
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
			LDI0_STI0:begin // MAR <- PC+off9
					ldMAR <= 1'b1;
					enaMARM <= 1'b1;
					selEAB2 <= 2'b10;
					selEAB1 <= 1'b0;
				end
			LDI1_STI1:begin // MDR <- Mem[MAR] 
					selMDR <= 1'b1;
					ldMDR <= 1'b1;
				end
			LDI2_STI2:begin // MAR <- MDR 
					ldMAR <= 1'b1;
					enaMDR<= 1'b1;
				end
			LDR0_STR0:begin // MAR <- MDR 
					selEAB2 <= 2'b01;	
					selPC <= 1'b1;	
					enaMARM <= 1'b1;
					ldMAR<= 1'b1;
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
			BR0:begin
					selPC <= 2'b01;
					selEAB2 <= 2'b10;		
					selEAB1 <= 1'b0;	
					ldPC <= TB;	
				end
			JMP0:begin 
					SR1 <= IR[8:6];
					selPC <= 2'b01;
					selEAB2 <= 2'b00;		
					selEAB1 <= 1'b1;	
					ldPC <= 1'b1;	
				end
			JSR0:begin 
					DR <= 3'b111;
					regWE <= 1'b1;	
					enaPC <= 1'b1;
				end
			JSR1:begin 
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
					enaMARM <= 1'b1;
					selMAR <= 1'b1;
					ldMAR <= 1'b1;
				end
			TRAP1:begin 
					selMDR <= 1'b1;		// sel data from memory
					ldMDR  <= 1'b1;		// load data from memory into MDR
					enaPC <= 1'b1;
					regWE <= 1'b1;
					DR <= 3'b111;
				end
			TRAP2:begin 
					enaMDR <= 1'b1;
					selPC <= 2'b10;
				end
			LEA0:begin // DR <– PC+off9
					DR <= IR[11:9];
					regWE <= 1'b1;	
					selEAB1 <= 1'b0;
					selEAB2 <= 2'b10;
					selMAR <= 1'b0;
					enaMARM <= 1'b1;
				end
		   default : begin
					end
		  endcase
		end
	end // End Of Block OUTPUT_LOGIC

endmodule

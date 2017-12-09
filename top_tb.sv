`timescale 1ns/1ns
`default_nettype none
module top_tb();
	int addition = 0;
	wire [15:0] Buss;
	logic clk, rst;
	logic [3:0] state, inst;
	logic [1:0] SR_DR;
	logic [4:0] Imm;
	logic [15:0] value, grab_ir, arg1, arg2, arg3, arg4, memAddr, PCvalue, PCvalue_before;
	logic [15:0] sextPCoffset, instAddr;
	int numOfInst = 0;		
	int numErrors= 0;	
	integer FP;
	integer fgetsResult;
	integer sscanfResult;
	integer NowInSeconds;
	reg [8*10:1] str;	

	localparam [3:0] 	ADD 	= 4'b0001,
						NOT 	= 4'b1001,
						AND 	= 4'b0101,
						LD	 	= 4'b0010,
						ST 		= 4'b0011,
						JMP 	= 4'b1100,
						BR  	= 4'b0000,
						JSR 	= 4'b0100;
	
	// Helper function to print out current state for debugging
	function automatic printState(logic [4:0] stateBits);
		case(stateBits)
			5'b00000 : $display("IDLE,  %0t",$time);
			5'b00001 : $display("FET0, %0t",$time); 
			5'b00010 : $display("FET1,  %0t",$time);
			5'b00011 : $display("FET2,  %0t",$time);
			5'b00100 : $display("DECODE,  %0t",$time);
			5'b00101 : $display("AND, %0t",$time);
			5'b00110 : $display("ADD, %0t",$time);
			5'b00111 : $display("NOT, %0t",$time);
			5'b01000 : $display("JSR, %0t",$time);	
			5'b01001 : $display("BR, %0t",$time);
			5'b01010 : $display("LD0, %0t",$time); 
			5'b01011 : $display("ST0, %0t",$time);
			5'b01100 : $display("JMP_RET, %0t",$time);	
			5'b11010 : $display("LD1, %0t",$time);
			5'b11011 : $display("LD2, %0t",$time);
			5'b11100 : $display("ST1, %0t",$time);
			5'b11101 : $display("ST2, %0t",$time);
			5'b11110 : $display("JSR1, %0t",$time);
			default :  $display("INVALID STATE, %0t",$time);
		endcase
	endfunction 	

	// Fetch an instruction from memory and execute it
	task fetchInst();
		//$display("Fetch new instruction");
		@(negedge clk); // FET1
		@(negedge clk); // FET2
		@(negedge clk); // DECODE
		@(negedge clk); // INST
		state = DUT.IR[15:12];
		//$display("DUT.state=%b and state=%b",DUT.IR[15:12],state);
		if (state == ST || state == LD)begin
			grab_ir = DUT.IR;
			memAddr = DUT.MARMUXOut;
			SR_DR = DUT.IR[11:9];
			//printState(DUT.state); // INST
			@(negedge clk); // LD1/ST1
			@(negedge clk); // LD2/ST2
			@(negedge clk); // return to FET0
	 		CTRLgolden(grab_ir, memAddr, SR_DR);
		end
		if (state == ADD || state == AND || state == NOT )begin
			grab_ir = DUT.IR;
			arg1 = DUT.regfile.regfile[DUT.IR[8:6]];
			arg2 = DUT.regfile.regfile[DUT.IR[2:0]];
			Imm = DUT.IR[4:0];
			//printState(DUT.state); // INST
			@(negedge clk); // return to FET0
			ALUgolden(grab_ir, arg1, arg2, Imm);
		end
		if(state == JMP || state == BR) begin
			grab_ir = DUT.IR;
			arg1 = DUT.regfile.regfile[DUT.IR[8:6]];
			PCvalue_before = DUT.PCOut;
			//printState(DUT.state); // INST
			@(negedge clk); // return to FET0
			PCvalue = DUT.PCOut;	
			BR_JMPgolden(grab_ir,PCvalue,PCvalue_before,arg1);
		end
		if(state == JSR) begin
			grab_ir = DUT.IR;
			arg1 = DUT.PCOut;
			//printState(DUT.state); // INST
			@(negedge clk); // JSR1
			// make sure current PC value was stored correctly in reg[7]
			arg2 = DUT.regfile.regfile[7];
			arg3 = {{5{grab_ir[10]}},{grab_ir[10:0]}} + arg1;
			@(negedge clk); // return to FET0
			arg4 = DUT.PCOut;
			JSRgolden(grab_ir,arg4,arg1,arg2,arg3);
		end
	endtask

	// Perform global reset	
	task reset;
		$display("reset");
		rst = 0;
		@(negedge clk);
		//printState(DUT.state); 
		rst = 1; // IDLE
		@(negedge clk);
		if(DUT.state != 5'b00000 ) begin// IDLE 
			$display("ERROR STATE, should be 00000 but instead is %b at %0t",DUT.state,$time);
			numErrors = numErrors + 1;
		end
		//printState(DUT.state); 
		rst = 0;
		@(negedge clk); // in IDLE but go to FET0 and wait to fetch inst.
		//printState(DUT.state); 
	endtask	

	// Golden function for JSR operation
	function automatic logic [15:0] JSRgolden(logic [15:0] ir, PCvalue, PCvalue_before, reg_7, PCin);
		$display("JSR    %b",ir);
		if (reg_7 != PCvalue_before) begin // currecnt PC value was not stored correctly in reg[7]
			$display("ERROR after JSR0: current PC value was not stored correctly in reg[7]");
			$display("PC value = %b but reg[7] = %b", PCvalue_before, reg_7); 
			numErrors = numErrors + 1;
		end
		if (PCvalue != PCin) begin // PC not correctly loaded from PCoffset11
			$display("ERROR after JSR1:  PC not correctly loaded from PCoffset11");
			$display("PC value = %b but PCoffset+PCvalue=%b",PCvalue,PCin);
			numErrors = numErrors + 1;
		end
	endfunction 

	// Golden function for BR and JMP operations	
	function automatic logic [15:0] BR_JMPgolden(logic [15:0] ir, PCvalue, PCvalue_before, arg1);
		inst = ir[15:12];
		sextPCoffset = {{7{ir[8]}},{ir[8:0]}};
		instAddr = sextPCoffset + PCvalue_before;
		if (inst == JMP) begin
			$display("JMP   %b",ir);
			$display("JMP to inst %d = %b",DUT.regfile.regfile[ir[8:6]],DUT.my_mem.my_memory[DUT.regfile.regfile[ir[8:6]]]);
			if (PCvalue != arg1) begin
				$display("ERROR after JMP, reg[%d] = %b, but PCOut = %b should be equal",ir[8:6],arg1,PCvalue);
				numErrors = numErrors + 1;
			end
		end	
		if (inst == BR) begin
			$display("BR    %b",ir);
			if ((DUT.N && ir[11]) || (DUT.Z && ir[10]) || (DUT.P && ir[9])) begin
				$display("branch taken");
				if (PCvalue !=  instAddr) begin
					$display("ERROR after BR, PCout=%b but should be %b", PCvalue, instAddr);
					numErrors = numErrors + 1;
				end
			end
		end
	endfunction

	// Golden function for ST and LD operations
	function automatic logic [15:0] CTRLgolden(logic [15:0] ir, memAddr, logic [2:0] SR_DR);
		inst = ir[15:12];
		if (inst == ST) begin
			$display("ST    %b",ir);
			// check that memory has same value as from source register
			if(DUT.my_mem.my_memory[memAddr] != DUT.regfile.regfile[SR_DR]) begin
				$display("ERROR After ST, reg[%d] = %b but mem[%d] = %b",SR_DR,DUT.regfile.regfile[SR_DR],memAddr, DUT.my_mem.my_memory[memAddr]);
				numErrors = numErrors + 1;
			end
		end
		else if (inst == LD) begin
			$display("LD    %b",ir);
			if(DUT.regfile.regfile[SR_DR] != DUT.regfile.regfile[SR_DR]) begin
				$display("ERROR After LD, reg[%d] = %b but mem[%d] = %b",SR_DR,DUT.regfile.regfile[SR_DR],memAddr, DUT.my_mem.my_memory[memAddr]);
				numErrors = numErrors + 1;
			end
		end
	endfunction

	// Golden function for ALU operations
	function automatic logic [15:0] ALUgolden(logic [15:0] ir, agr1, arg2, logic [4:0] Imm);
		inst = ir[15:12];
		if ((inst == ADD) && (ir[5] == 0)) begin
			$display("ADD    %b",ir);
			value = arg1 + arg2;
			if(DUT.regfile.regfile[ir[11:9]]  != value) begin 
				$display("ERROR After ADD, reg[%d] = %b but should be %b",ir[11:9],DUT.regfile.regfile[ir[11:9]], value);
				numErrors = numErrors + 1;
			end
		end
		else if ((inst == ADD) && (ir[5] == 1)) begin
			$display("ADD + Imm   %b",ir);
			value = arg1 + { {11{Imm[4]}},Imm[4:0]};
			if(DUT.regfile.regfile[ir[11:9]] != value) begin
				$display("ERROR After ADD, reg[%d] = %b but should be %b",ir[11:9], DUT.regfile.regfile[ir[11:9]], value);
				numErrors = numErrors + 1;
			end
		end
		else if (inst == AND && (ir[5] == 0)) begin
			$display("AND    %b",ir);
			value = arg1 & arg2;
			if(DUT.regfile.regfile[ir[11:9]] != value) begin
				$display("ERROR After AND, reg[%d] = %b but should be %b",ir[11:9], DUT.regfile.regfile[ir[11:9]], value);
				numErrors = numErrors + 1;
			end
		end
		else if (inst == AND && (ir[5] == 1)) begin
			$display("AND + Imm    %b",ir);
			value = arg1 & {{11{Imm[4]}},Imm[4:0]};
			if(DUT.regfile.regfile[ir[11:9]] != value) begin
				$display("ERROR After ADD, reg[%d] = %b but should be %b",ir[11:9] ,DUT.regfile.regfile[ir[11:9]], value);
				numErrors = numErrors + 1;
			end
		end
		else begin // inst = NOT
			$display("NOT    %b",ir);
			value = ~arg1;
			if(DUT.regfile.regfile[ir[11:9]] != value)  begin
				$display("ERROR After NOT, reg[%d] = %b but should be %b",ir[11:9], DUT.regfile.regfile[ir[11:9]], value);
				numErrors = numErrors + 1;
			end
		end
	endfunction

	// DUT instantiation
	top DUT(
		.Buss(Buss), .clk(clk), .rst(rst)
	);
		
	// Generate a clock
	initial begin
		clk = 0;
		forever #10ns clk = ~clk;
	end

	initial begin
		//$monitor("SR1=%b, SR2=%b, N=%b, Z=%b, P=%b", DUT.SR1, DUT.SR2, DUT.N, DUT.Z, DUT.P);
		//$monitor("Buss=%b",Buss);
		//$monitor("state=%b",printState(DUT.state));
		$timeformat(-9, 2, " ns", 20);
	
		
		reset();	
		for (int i=0; i < 60; i++) begin
			numOfInst = numOfInst +1;
			//$display("Fetch new instruction");
			fetchInst();
		end

		$display("Test Completed with %0d errors",numErrors);
		$display("Simulation time: %0t", $time);
		
		$system("date +%s > now_in_seconds");                                                   

		// open the file for reading
		FP = $fopen("now_in_seconds","r");
		
		// get a string from the open file - "fgetsResult" should be a 1 - you can test 
		// that for completeness if you'd like
		fgetsResult = $fgets(str,FP);
		
		// convert the string to an integer - "sscanfResult" should also be a 1, and
		// you can test that, too, 
		sscanfResult = $sscanf(str,"%d",NowInSeconds);
		
			
		//$finish;
	end

endmodule

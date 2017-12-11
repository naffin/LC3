############################################################################
## Purpose: Makefile for Chap_6_Randomization/homework_solution
## Author: Chris Spear
##
## REVISION HISTORY:
## $Log: Makefile,v $
## Revision 1.1  2011/05/29 19:10:04  tumbush.tumbush
## Check into cloud repository
##
## Revision 1.2  2011/03/20 20:16:58  Greg
## Fixed path of Makefile
##
## Revision 1.1  2011/03/20 19:09:52  Greg
## Initial check in
##
############################################################################

VERILOG_FILES = memory.v regfile8x16.sv eab.v ir.v pc.sv nzp.v ts_driver.v marmux.v mux4_1.v mux2_1.v alu.sv top.sv top_tb.sv
ASSERTION_FILES = bindfiles.sv lc3_asserts.sv
TOPLEVEL = top_tb bindfiles

help:
	@echo "Make targets:"
	@echo "> make vcs          	# Compile and run with VCS"
	@echo "> make questa_gui   	# Compile and run with Questa in GUI mode"
	@echo "> make questa_batch 	# Compile and run with Questa in batch mode"
	@echo "> make clean        	# Clean up all intermediate files"
	@echo "> make tar          	# Create a tar file for the current directory"
	@echo "> make help         	# This message"

#############################################################################
# VCS section
VCS_FLAGS = -sverilog -debug  -l comp.log
vcs:	simv
		./simv -l sim.log

simv:   ${VERILOG_FILES} ${ASSERTION_FILES} clean
		mkdir work
		vlogan ${VCS_FLAGS} ${VERILOG_FILES}
		vcs ${TOPLEVEL}

#############################################################################
# Questa section
questa_gui: 
		vlib work
		vmap work work
		vlog ${VERILOG_FILES} 
		vsim -novopt -coverage -t ps -do "view wave;do wave.do;run -all" ${TOPLEVEL}

questa_batch: ${VERILOG_FILES} ${ASSERTION_FILES} clean
		vlib work
		vmap work work
		vlog -sv ${VERILOG_FILES} ${ASSERTION_FILES}
		vsim -c -coverage -t ps -novopt -do "run -all" ${TOPLEVEL}

#############################################################################
# Housekeeping

DIR = $(shell basename `pwd`)

tar:	clean
		cd ..; \
		tar cvf ${DIR}.tar ${DIR}

clean:
		@# VCS Stuff
		@rm -rf simv* csrc* *.log *.key vcdplus.vpd *.log .vcsmx_rebuild vc_hdrs.h .vlogan*
		@# Questa stuff
		@rm -rf work transcript vsim.wlf
		@# Unix stuff
		@rm -rf  *~ core.*

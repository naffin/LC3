//----------------------------------------------------------------------
// This File: fifo1.sv
//
// Copyright 2003-2016 Sunburst Design, Inc.
//
// Sunburst Design (Provo, UT): 
//            cliffc@sunburst-design.com
//            www.sunburst-design.com
//----------------------------------------------------------------------

module fifo1 (
  output logic [7:0] dout, 
  output logic       full, empty,
  input  logic       write, read, clk, rst_n,
  input  logic [7:0] din);

  logic [7:0] fifomem [0:15];
  logic [3:0] wptr, rptr;
  logic [4:0] cnt;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      wptr  <= '0;
      rptr  <= '0;
      cnt   <= '0;
      empty <= '1;
      full  <= '0;
    end
    else 
      case ({write, read})
        2'b00: ;     // no fifo write or read
        2'b01: begin // fifo read
                 full <= '0;
				 if (cnt>0) begin 
					cnt  <= cnt  - 1;
                 	rptr <= rptr + 1;
				 end
                 if (cnt<2) empty <= '1;
               end
        2'b10: begin // fifo write
                 empty <= '0;
                 if (cnt<16) begin
                   wptr <= wptr + 1;
                   cnt  <= cnt  + 1;
                 end
                 if (cnt>14) full <= '1;
               end
        2'b11: // fifo write & read
               if (full) begin
                 rptr  <= rptr + 1;
                 cnt   <= cnt  - 1;
				 full <= '0;
               end
               else if (empty) begin
                 wptr  <= wptr + 1;
                 cnt   <= cnt  + 1;
				 empty <= '0;
               end
               else begin
                 wptr  <= wptr + 1;
                 rptr  <= rptr + 1;
               end
      endcase

  // FIFO synchronous memory write operation
  always_ff @(posedge clk)
    if (write && ((cnt <16) || ((cnt==16) && read)))
      fifomem[wptr] <= din;

  assign dout = fifomem[rptr];
endmodule

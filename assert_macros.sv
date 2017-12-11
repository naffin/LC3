`ifndef ASSERT_MACROS
`define ASSERT_MACROS

`define assert_clk_xrst(arg) \
	assert property (@(posedge clk) disable iff (!rst) arg)

`define assert_clk(arg) \
	assert property (@(posedge clk) arg)

`endif

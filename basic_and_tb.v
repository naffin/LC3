`timescale 1ns/1ns
module basic_and_tb();
   
  reg [3:0] a, b;
  wire [3:0] out;
   
  basic_and #(.WIDTH(4)) DUT (
    .a(a),
    .b(b),
    .out(out)
  );
   
  initial begin
    a = 4'b0000;
    b = 4'b0000;
    #20
    if(out != 4'b0000)
	$display("ERROR: out should equal 0000 but equals %b",out);
    a = 4'b1111;
    b = 4'b0101;
    #20
    a = 4'b1100;
    b = 4'b1111;
    #20
    a = 4'b1100;
    b = 4'b0011;
    #20
    a = 4'b1100;
    b = 4'b1010;
    #20
    $display (
	"a=%d, b=%d",
	a, b
    );
    $display (
	"out=%b,",
	out
    );
    $finish;
  end
   
endmodule

/*
* A testbench for the counter module
*/

`timescale 1 ns / 1 ps

module counter_tb ();
  reg        clk = 0;
  reg        en = 0;
  reg        rst = 0;
  wire [4:0] count;
  wire       max_val;

  counter #(
      .MAX_VALUE(16),
      .BIT_WIDTH(5)
  ) c (
      .clk(clk),
      .en(en),
      .rst(rst),
      .count(count),
      .max_val(max_val)
  );

  always begin
    #1 clk = ~clk;
  end

  initial begin
    #1 rst = 1;
    #1 rst = 0;
    en = 1;
    #100 $finish;
  end

  initial begin
    $dumpfile("counter.vcd");
    $dumpvars(0, counter_tb);
  end

endmodule

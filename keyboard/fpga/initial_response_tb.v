/*
* A testbench for the initial_response module
*/

`timescale 1 ns / 1 ps

module initial_response_tb ();
  reg  clk = 0;
  reg  rst = 0;
  reg  reset_required = 0;
  wire ps2_clk_pull_down;
  wire ps2_data_pull_down;

  reset_required #(
      .MAX_VALUE(16),
      .BIT_WIDTH(5)
  ) r (
      .reset_required(reset_required),
      .clk(clk),
      .rst(rst),
      .ps2_clk_pull_down(ps2_clk_pull_down),
      .ps2_data_pull_down(ps2_data_pull_down)
  );

  always begin
    #1 clk = ~clk;
  end

  initial begin
    #1 rst = 1;
    #1 rst = 0;
    reset_required = 0;
    #25 $finish;
  end

  initial begin
    $dumpfile("initial_response.vcd");
    $dumpvars(0, initial_response_tb);
  end

endmodule

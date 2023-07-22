/*
* A testbench for the initial_response module
*/

`timescale 1 ns / 1 ps

module reset_keyboard_tb ();
  reg            ps2_data = 1;
  reg            ps2_clock = 1;
  reg            rst = 0;
  reg            clk = 0;
  wire    [10:0] data;
  wire           data_latch;
  wire           reset_required;
  wire           release_key;
  wire           extended_code;

  reg     [10:0] read_data      [0:0];
  integer        i;
  integer        j;

  receiver #() r (
      .ps2_data(ps2_data),
      .ps2_clk(ps2_clock),
      .rst(rst),
      .data(data),
      .data_latch(data_latch),
      .reset_required(reset_required),
      .release_key(release_key),
      .extended_code(extended_code)
  );

  initial_response #(
      .MAX_COUNT(15),
      .BIT_WIDTH(4)
  ) ir (
      .clk(clk),
      .rst(rst),
      .reset_required(reset_required)
  );

  always begin
    #1 clk = ~clk;
  end

  initial begin
    #1 rst = 1;
    #1 rst = 0;

    $readmemb("testbenches/io/reset_keyboard_io.txt", read_data);

    for (j = 0; j < 11; j = j + 1) begin
      #2 ps2_data = read_data[0][10-j];
      #1 ps2_clock = 0;
      #1 ps2_clock = 1;
      #4;
    end

    #50 $finish;
  end

  initial begin
    $dumpfile("reset_keyboard.vcd");
    $dumpvars(0, reset_keyboard_tb);
  end

endmodule

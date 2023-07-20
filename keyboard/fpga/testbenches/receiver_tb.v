/*
* A testbench for the initial_response module
*/

`timescale 1 ns / 1 ps

module receiver_tb ();
  reg            ps2_data = 1;
  reg            ps2_clock = 1;
  reg            rst = 0;
  wire    [10:0] data;
  wire           data_latch;
  wire           reset_required;
  wire           release_key;
  wire           extended_code;

  reg     [10:0] read_data      [0:3];
  integer        i;
  integer        j;

  receiver #() r (
      .ps2_data(ps2_data),
      .ps2_clk(ps2_clk),
      .rst(rst),
      .data(data),
      .data_latch(data_latch),
      .reset_required(reset_required),
      .release_key(release_key),
      .extended_code(extended_code)
  );

  initial begin
    #1 rst = 1;
    #1 rst = 0;

    $readmemb("testbenches/io/receiver_io.txt", read_data);

    for (i = 0; i < 4; i = i + 1) begin
      for (j = 0; j < 11; j = j + 1) begin
        #2 ps2_data = read_data[i][j];
        #1 ps2_clock = 0;
        #1 ps2_clock = 1;
        #4;
      end
      #10;
    end

    #10 $finish;
  end

  initial begin
    $dumpfile("receiver.vcd");
    $dumpvars(0, receiver_tb);
  end

endmodule

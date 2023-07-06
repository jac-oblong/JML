/*
* Toplevel design of the keyboard module
*/

module toplevel 
(
  input               ps2_data,  // ps2 keyboard data line
                      ps2_clk,  // ps2 keyboard clock line
                      clk,
                      rst,
                      cpu_ack, // line used by cpu to acknoledge interrupt

  output  reg         cpu_intr,  // line used to interrupt the cpu
          reg [7:0]   ascii_out,  // ascii charactercode to send to cpu
          reg         ps2_data_pulldown,
          reg         ps2_clk_pulldown
);

  wire modified_clk;


endmodule

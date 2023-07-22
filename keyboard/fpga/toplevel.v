/*
* Toplevel design of the keyboard module
*/

module toplevel (
    input ps2_data,  // ps2 keyboard data line
    input ps2_clk,   // ps2 keyboard clock line
    input clk,
    input rst,
    //input cpu_ack, // line used by cpu to acknoledge interrupt

    //output reg       cpu_intr,           // line used to interrupt the cpu
    //output reg [7:0] ascii_out,          // ascii charactercode to send to cpu
    output ps2_data_pulldown,
    output ps2_clk_pulldown
);

  wire reset_required;

  receiver #() rec (
      .ps2_data(ps2_data),
      .ps2_clk(ps2_clk),
      .rst(rst)
  );

  initial_response #(
      .MAX_COUNT(2700),  // 27MHz clock, and need to hold ps2 clk low for 100us
      .BIT_WIDTH(12)
  ) init_resp (
      .reset_required(reset_required),
      .clk(clk),
      .rst(rst),
      .ps2_data_pulldown(ps2_data_pulldown),
      .ps2_clk_pulldown(ps2_clk_pulldown)
  );

endmodule

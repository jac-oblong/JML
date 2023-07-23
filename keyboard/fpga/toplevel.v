/*
* Toplevel design of the keyboard module
*/

module toplevel (
    input ps2_data,  // ps2 keyboard data line
    input ps2_clk,   // ps2 keyboard clock line
    input clk,

    output ps2_data_pulldown,
    output ps2_clk_pulldown
);

  wire reset_required;

  receiver #() rec (
      .ps2_data(ps2_data),
      .ps2_clk(ps2_clk),
      .reset_required(reset_required)
  );

  reset_keyboard #() rst_kb (
      .reset_required(reset_required),
      .clk(clk),
      .ps2_data_pulldown(ps2_data_pulldown),
      .ps2_clk_pulldown(ps2_clk_pulldown)
  );

endmodule

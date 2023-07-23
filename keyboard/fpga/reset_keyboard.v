/*
* This module controls the initial response to the keyboard necessary for the
* resetting of the PERIBOARD ps/2 keyboard. (sends code 0xFF)
*
* inputs : reset_required should go high when the keyboard sends code 0xAA and
*           code 0xFF needs to be sent
*          clk is the clock signal
*          rst will reset the module
*/

module reset_keyboard #(
) (
    input reset_required,  // code 0xAA recieved
    input clk,

    output     ps2_clk_pulldown,
    output reg ps2_data_pulldown
);

  localparam MAX_COUNT_CLK = 2700;  // 27MHz clk, need ps2 clk held low for 100us
  localparam MAX_COUNT_DATA = 270;

  reg        counting = 0;
  reg [11:0] count;

  assign ps2_clk_pulldown = counting;

  always @(posedge clk) begin
    // start counting and pull down ps2_clk
    if (counting) begin
      count = count + 1;
      if (count == MAX_COUNT_CLK) begin
        counting <= 0;
        count <= 0;
      end
      if (count == MAX_COUNT_DATA) begin
        ps2_data_pulldown <= 0;
      end
    end else if (reset_required) begin
      counting <= 1;
      count <= 0;
      ps2_data_pulldown <= 1;
    end
  end

endmodule

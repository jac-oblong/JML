/*
* This module controls the initial response to the keyboard necessary for the
* resetting of the PERIBOARD ps/2 keyboard. (sends code 0xFF)
*
* inputs : reset_required should go high when the keyboard sends code 0xAA and
*           code 0xFF needs to be sent
*          clk is the clock signal
*          rst will reset the module
*/

module initial_response #(
    parameter MAX_COUNT = 1,  // number of clk ticks to keep ps2_clk low
    parameter BIT_WIDTH = 1   // number of bits needed for MAX_COUNT
) (
    input reset_required,  // code 0xAA recieved
    clk,
    rst,  // reset count to 0

    output reg ps2_clk_pulldown,
    output reg ps2_data_pulldown
);

  reg                  c1_en;
  reg                  c1_rst;
  wire                 c1_max_val;
  wire [BIT_WIDTH-1:0] c1_count;

  counter #(
      .BIT_WIDTH(BIT_WIDTH),
      .MAX_VALUE(MAX_COUNT)
  ) c1 (
      .en(c1_en),
      .clk(clk),
      .rst(c1_rst),
      .max_val(c1_max_val),
      .count(c1_count)
  );

  always @(posedge reset_required) begin
    // start counting and pull down ps2_clk
    c1_en <= 1;
    ps2_clk_pulldown <= 1;
  end

  always @(posedge clk) begin
    // always reset counter if this module is reset
    c1_rst <= rst;
    if (rst) begin
      c1_en <= 0;
      ps2_clk_pulldown <= 0;
      ps2_data_pulldown <= 0;
    end

    if (c1_en) begin
      // if reached MAX_COUNT, stop counting
      if (c1_max_val) begin
        c1_en <= 0;
        c1_rst <= 1;
        ps2_clk_pulldown <= 0;
      end
    end

    // never want to pull data line low
    ps2_data_pulldown <= 0;
  end

endmodule

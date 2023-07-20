/*
* This module controls the initial response to the keyboard necessary for the
* resetting of the PERIBOARD ps/2 keyboard. (sends code 0xFF)
*/

module  initial_response 
#(
  parameter   MAX_COUNT       = 1, // number of clk ticks to keep ps2_clk low
  parameter   BIT_WIDTH       = 1  // number of bits needed for MAX_COUNT
)
(
  input             reset_required, // code 0xAA recieved
                    clk,
                    rst, // reset count to 0
  
  output    reg     ps2_clk_pulldown,
  output    reg     ps2_data_pulldown
);
  
  reg                   c1_en;
  reg                   c1_rst;
  reg                   c1_max_val;
  reg [BIT_WIDTH-1:0]   c1_count;

  counter c1(
    .en(c1_en),
    .clk(clk),
    .rst(c1_rst),
    .max_val(c1_max_val),
    .count(c1_count),
    .BIT_WIDTH(BIT_WIDTH),
    .MAX_VALUE(MAX_COUNT)
  );

  always @(posedge clk) begin 
    c1_rst <= rst; // always reset counter if this module reset
    if (rst) begin 
      c1_en <= 0;
    end
    // start counting and pull down ps2_clk
    if (reset_required) begin 
      c1_en <= 1;
      ps2_clk_pulldown <= 1;
    end

    // while counting, count
    if (c1_en) begin
      // if reached MAX_COUNT, stop counting
      if (c1_max_val) begin
        c1_en <= 0;
        c1_rst <= 1;
        ps2_clk_pulldown <= 0;
      end
    end

    // never want to drive data low, only message sent to keyboard is 0xFF
    ps2_data_pulldown <= 0;
  
  end 

endmodule

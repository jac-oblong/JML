/*
* This module controls the initial response to the keyboard necessary for the
* resetting of the PERIBOARD ps/2 keyboard. (sends code 0xFF)
*/

module  initial_response #(
  parameter   MAX_COUNT       = 1, // number of clk ticks to keep ps2_clk low
  parameter   BIT_WIDTH       = 4  // number of bits needed for MAX_COUNT
)
(
  input             reset_required, // code 0xAA recieved
                    clk,
  
  output    reg     ps2_clk_pulldown,
            reg     ps2_data_pulldown
);
  
  reg   [BIT_WIDTH:0]   count;
  reg                   counting;

  always @(posedge clk) begin 
    // start counting and pull down ps2_clk
    if (reset_required) begin 
      counting <= 1;
      ps2_clk_pulldown <= 1;
    end

    // while counting, count
    if (counting) begin
      count <= count + 1;
      // if reached MAX_COUNT, stop counting
      if (count >= MAX_COUNT) begin
        count <= 0;
        counting <= 0;
        ps2_clk_pulldown <= 0;
      end
    end
  end 

  // never want to drive data low, only message sent to keyboard is 0xFF
  always @(*) begin 
    ps2_data_pulldown = 0;
  end

endmodule

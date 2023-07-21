/*
* Basic counter module
*
* Has enable, reset, and clock inputs
*
* max_val output goes high **after** MAX_VALUE has been reached and the
* counter has been reset to 0. So, when max_val is high, the counter is
* currently at 0, except when reset by rst
*/

module counter #(
    parameter MAX_VALUE = 1,
    parameter BIT_WIDTH = 1
) (
    input en,
    clk,
    rst,

    output reg                 max_val,
    output reg [BIT_WIDTH-1:0] count
);

  always @(posedge clk, posedge rst) begin
    if (rst) begin
      max_val <= 0;
      count   <= 0;
    end

    if (en && !rst) begin
      count <= count + 1;
      // MAX_VALUE reached
      if (count == MAX_VALUE - 1) begin
        max_val <= 1;
        count   <= 0;
      end else begin
        max_val <= 0;
      end
    end
  end

endmodule

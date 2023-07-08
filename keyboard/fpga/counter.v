/*
* Basic counter module
* Has enable, reset, and clock inputs
* outputs when overflow occurs and when above max value
*/

module counter 
#(
  parameter     MAX_VALUE = 1,
  parameter     BIT_WIDTH = 1
) (
  input                         en,
                                clk,
                                rst,

  output  reg                   overflow,
  output  reg                   max_val,
  output  reg [BIT_WIDTH-1:0]   count
);

  reg [BIT_WIDTH:0] count_temp; // temp var to make detect overflow

  always @ (posedge clk, posedge rst) begin 
    if (rst) begin 
      overflow <= 0;
      max_val <= 0;
      count <= 0;
      count_temp <= 1;
    end 

    if (en && !rst) begin 
      count <= count_temp[BIT_WIDTH-1:0];
      count_temp <= count_temp + 1;
      // MAX_VALUE reached
      if (count == MAX_VALUE) begin 
        max_val <= 1;
      end 
      if (count_temp[BIT_WIDTH]) begin 
        overflow <= 1;
        count_temp[BIT_WIDTH] <= 0;
      end
    end
  end

endmodule

/*
* This module contains the "receiver" used to translate the ps/2 keyboard data
* into a format that the rest of the system can use
*/

module receiver
#(

) (
  input               ps2_data,
                      ps2_clk,
                      rst,
  output  reg [10:0]  data,
          reg         data_latch, // used to latch data into other modules
          reg         reset_required, // used when 0xAA received
          reg         release_key, // used when 0xF0 received
          reg         extended_code // used when 0xE0 received
);

  reg                 c1_en = 1;
  reg                 c1_max_val;
  reg                 c1_overflow;
  reg   [3:0]         c1_count;

  counter c1(
    .en(c1_en),
    .clk(ps2_clk),
    .rst(rst),
    .max_val(c1_max_val),
    .overflow(c1_overflow),
    .count(c1_count),
    .MAX_VALUE(11),
    .BIT_WIDTH(4)
  );

  always @ (negedge ps2_clk, posedge c1_max_val) begin 
    reset_required <= 0;
    release_key <= 0;
    extended_code <= 0;
    data_latch <= 0;

    if (!ps2_clk) begin
      data <= data << 1;
      data[0] <= ps2_data;
    end 

    if (c1_max_val) begin 
      if (data[8:1] == 8'hAA) begin 
        reset_required <= 1;
      end else if (data[8:1] == 8'hFF) begin 
      end else if (data[8:1] == 8'hF0) begin 
        release_key <= 1;
      end else if (data[8:1] == 8'hE0) begin 
        extended_code <= 1;
      end else begin 
        data_latch <= 1;
      end
    end
  end

endmodule

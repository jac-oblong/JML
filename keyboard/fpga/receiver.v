/*
* This module contains the "receiver" used to translate the ps/2 keyboard data
* into a format that the rest of the system can use
*/

module receiver (
    input ps2_data,
    input ps2_clk,

    output reg reset_required  // used when 0xAA received
);
  reg [10:0] data;

  always @(negedge ps2_clk) begin
    data <= {data[9:0], ps2_data};
  end

  always @* begin
    if (data == 11'b00101010111) begin
      reset_required <= 1;
    end else begin
      reset_required <= 0;
    end
  end

endmodule


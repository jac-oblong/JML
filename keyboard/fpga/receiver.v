/*
* This module contains the "receiver" used to translate the ps/2 keyboard data
* into a format that the rest of the system can use
*/

module receiver (
    input ps2_data,
    input ps2_clk,

    output       reset_required,  // when 0xAA received
    output       release_key,     // when 0xF0 received
    output       extended_code,   // when 0xE0 received
    output [7:0] data_out,
    output       data_valid       // when 11 bits read in
);

  reg [10:0] data = 0;
  reg [ 4:0] count = 0;

  assign reset_required = (data == 11'b00101010111 && count == 11);
  assign release_key = (data == 11'b00000111111 && count == 11);
  assign extended_code = (data == 11'b00000011101 && count == 11);
  assign data_valid = (count == 11);

  // data has lsb at [9] and msb at [2], need to swap that for data_out
  assign data_out[0] = data[9];
  assign data_out[1] = data[8];
  assign data_out[2] = data[7];
  assign data_out[3] = data[6];
  assign data_out[4] = data[5];
  assign data_out[5] = data[4];
  assign data_out[6] = data[3];
  assign data_out[7] = data[2];

  always @(negedge ps2_clk) begin
    data <= {data[9:0], ps2_data};
    // if count equals 11, should be reset to 0 and add 1, so just reset to 1
    if (count == 11) begin
      count <= 1;
    end else begin
      count <= count + 1;
    end
  end

endmodule


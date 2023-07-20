/*
* This module contains the "receiver" used to translate the ps/2 keyboard data
* into a format that the rest of the system can use
*/

module receiver (
    input ps2_data,
    input ps2_clk,
    input rst,

    output reg [10:0] data,
    output reg        data_latch,      // used to latch data into other modules
    output reg        reset_required,  // used when 0xAA received
    output reg        release_key,     // used when 0xF0 received
    output reg        extended_code    // used when 0xE0 received
);

  reg        c1_en = 1;
  wire       c1_max_val;
  wire [3:0] c1_count;

  counter #(
      .MAX_VALUE(11),
      .BIT_WIDTH(4)
  ) c1 (
      .en(c1_en),
      .clk(ps2_clk),
      .rst(rst),
      .max_val(c1_max_val),
      .count(c1_count)
  );

  always @(negedge ps2_clk, posedge c1_max_val) begin
    // shift in new bit
    if (!ps2_clk) begin
      data <= data << 1;
      data[0] <= ps2_data;
    end

    // set appropriate signal if 11 bits clocked in
    // bits come in lsb first, so data[8] is lsb
    if (c1_max_val) begin
      if (data[8:1] == 8'h55) begin  // 0xAA is actual code, but 0x55 cause of bit ordering
        reset_required <= 1;
      end else if (data[8:1] == 8'h0F) begin  // 0xF0
        release_key <= 1;
      end else if (data[8:1] == 8'h07) begin  // 0xE0
        extended_code <= 1;
      end else begin
        data_latch <= 1;
      end

      // else set all output signals to 0
    end else begin
      reset_required <= 0;
      release_key <= 0;
      extended_code <= 0;
      data_latch <= 0;
    end
  end

endmodule


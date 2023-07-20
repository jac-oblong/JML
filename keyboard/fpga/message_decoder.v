/*
* This module will decode the message received, and output the corresponding
* ascii code. This will then make it's way to the cpu
*/

module message_decoder #(

) (
    input [7:0] message_in,
    input       message_latch,
    input       release_key,
    input       extended_code,

    output reg [7:0] ascii_out,
    output reg       ascii_latch
);

  reg [7:0] scan_code;
  reg       released;
  reg       extended;
  reg       caps_lock;
  reg       shift;

  always @(posedge release_key) begin
    released <= 1;
  end

  always @(posedge extended_code) begin
    extended <= 1;
  end

  always @(posedge message_latch) begin
    scan_code <= message_in;

    if (released && extended) begin

    end else
    if (released) begin

    end else
    if (extended) begin

    end else begin

    end

    // reset these flags
    released <= 0;
    extended <= 0;
  end

endmodule

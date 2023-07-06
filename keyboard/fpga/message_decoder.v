/*
* This module will decode the message received, and output the corresponding
* ascii code. This will then make it's way to the cpu
*/

module message_decoder
#(

) (
  input       [7:0]     message_in,
                        message_latch,
                        release_key,
                        extended_code,

  output  reg [7:0]     ascii_out,
          reg           ascii_latch
);
  
  reg [7:0]     scan_code;
  reg           shift;
  reg           ctrl;
  reg           alt;

endmodule

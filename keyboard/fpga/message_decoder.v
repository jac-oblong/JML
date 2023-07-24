/*
* Converts the ps/2 scancode input into ascii character output
*/

module message_decoder (
    input [7:0] scancode,
    input       scancode_valid,
    input       release_key,
    input       extended_code,

    output reg [7:0] ascii,
    output reg       ascii_valid
);

  reg shift = 0;
  reg caps_lock = 0;
  reg ctrl = 0;
  reg alt = 0;

  reg [7:0] scancode_to_ascii[256];

endmodule

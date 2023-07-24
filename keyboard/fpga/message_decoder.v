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

  /* release_key and extended_code will disappear when next code comes in,
  * which is guaranteed, so need to save them */
  reg released = 0;
  reg extended = 0;

  reg [7:0] scancode_to_ascii[256];

  always @(posedge release_key) begin
    released <= 1;
  end

  always @(posedge extended_code) begin
    extended <= 1;
  end

  always @(posedge scancode_valid) begin
    if ((scancode == 8'h12 || scancode == 8'h59) && ~extended) begin
      shift <= ~released;
    end else if (scancode == 8'h58 && ~extended && ~released) begin
      caps_lock <= ~caps_lock;
    end else if (scancode == 8'h14) begin  // extended or not
      ctrl <= ~released;
    end else if (scancode == 8'h11) begin  // extended or not
      alt <= ~released;
    end else begin
      ascii <= scancode_to_ascii[scancode];
    end
  end

endmodule

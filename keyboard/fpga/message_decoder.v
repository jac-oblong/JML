/*
* Converts the ps/2 scancode input into ascii character output
*/

module message_decoder (
    input [7:0] scancode,
    input       scancode_valid,

    output reg [7:0] ascii,
    output reg       ascii_valid,
    output           reset_required,
    output reg       ctrl,
    output reg       alt
);

  // used for telling when to capitalize, etc
  reg shift = 0;
  reg caps_lock = 0;

  // used for getting codes longer than 1 byte
  reg released = 0;
  reg extended = 0;

  // similar to using a rom instead of a complex logic circuit
  reg [7:0] scancode_to_ascii[256];


  assign reset_required = (scancode == 8'hAA);

  always @(posedge scancode_valid) begin
    case (scancode)
      8'hF0: released <= 1;

      8'hE0: extended <= 1;

      8'h11: begin
        alt <= ~released;  // extended does not matter
        extended <= 0;
        released <= 0;
      end

      8'h14: begin
        ctrl <= ~released;  // extended does not matter
        extended <= 0;
        released <= 0;
      end

      8'h12: begin
        if (~extended) begin
          shift <= ~released;
          released <= 0;
        end
      end

      8'h59: begin
        if (~extended) begin
          shift <= ~released;
          released <= 0;
        end
      end

      8'h58: begin
        if (~extended && ~released) begin
          caps_lock <= ~caps_lock;
        end
      end

      default: begin
        ascii <= scancode_to_ascii[scancode];
      end

    endcase
  end

endmodule

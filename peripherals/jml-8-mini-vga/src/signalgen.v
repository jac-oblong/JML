// generates signal timing for VGA 640x480 60Hz standard (25.175MHz clock)
// also puts red/green/blue/luminence in high impedance state

module signalgen (
    input clk,

    output vsync,
    output hsync
);

   reg [9:0] vertical_count = 0;
   reg [9:0] horizontal_count = 0;

   assign hsync = (horizontal_count < 656 || horizontal_count >= 752);
   assign vsync = (vertical_count < 490 || vertical_count >= 492);

   always @(posedge clk) begin
      if (horizontal_count == 799) begin
         horizontal_count <= 0;
         if (vertical_count == 524) vertical_count <= 0;
         else vertical_count <= vertical_count + 1;
      end else horizontal_count <= horizontal_count + 1;
   end

endmodule

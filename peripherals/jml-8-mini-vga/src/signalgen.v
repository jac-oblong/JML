// generates signal timing for VGA 640x480 60Hz standard (25.175MHz clock)
// also puts red/green/blue/luminence in high impedance state

module signalgen (
    input clk,

    output           vsync,
    output           hsync,
    output           visible,
    output reg [9:0] vertcount = 0,
    output reg [9:0] horicount = 0

);

   assign hsync   = (horicount < 656 || horicount >= 752);
   assign vsync   = (vertcount < 490 || vertcount >= 492);
   assign visible = (horicount < 640 && vertcount < 480);

   always @(posedge clk) begin
      if (horicount == 799) begin
         horicount <= 0;
         if (vertcount == 524) vertcount <= 0;
         else vertcount <= vertcount + 1;
      end else horicount <= horicount + 1;
   end

endmodule

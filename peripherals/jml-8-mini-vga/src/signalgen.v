/*
 * generates signal timing for VGA stardard specified by "vgaspec.vh"
 */

module signalgen (
    input clk,

    output                        vsync,
    output                        hsync,
    output                        visible,        // in visible region of screen
    output reg [HCOUNT_BITSREQ:0] horicount = 0,
    output reg [VCOUNT_BITSREQ:0] vertcount = 0
);

   `include "vgaspecs.vh"

   assign hsync   = (horicount < HSYNC_BEGIN || horicount >= HSYNC_END);
   assign vsync   = (vertcount < VSYNC_BEGIN || vertcount >= VSYNC_END);
   assign visible = (horicount < HRESOLUTION && vertcount < VRESOLUTION);

   always @(posedge clk) begin
      // reset horicount
      if (horicount == HTOTAL - 1) begin
         horicount <= 0;

         // vertcount control
         if (vertcount == VTOTAL - 1) vertcount <= 0;
         else vertcount <= vertcount + 1;

      end else horicount <= horicount + 1;
   end

endmodule

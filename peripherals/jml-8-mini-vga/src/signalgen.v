/*
 * generates signal timing for VGA stardard specified by "vgaspec.vh"
 */

module signalgen (
    input clk,

    output                    vsync,
    output                    hsync,
    output                    visible,    // in visible region of screen
    output                    startline,  // should be starting this line
    output [HCOUNT_BITSREQ:0] horicount,
    output [HCOUNT_BITSREQ:0] vertcount
);

   `include "vgaspecs.vh"

   reg [HCOUNT_BITSREQ:0] row = 0;
   reg [HCOUNT_BITSREQ:0] col = 0;
   wire hvisible, vvisible;

   assign hsync = (col < HSYNC_BEGIN || col >= HSYNC_END);
   assign vsync = (row < VSYNC_BEGIN || row >= VSYNC_END);

   assign hvisible = (col < HRESOLUTION);
   assign vvisible = (row < VRESOLUTION);
   assign visible = hvisible && vvisible;

   assign startline = ((col >= HTOTAL - 4) && (row < VRESOLUTION - 1))
                      || ((col >= HTOTAL - 4) && (row == VTOTAL - 1))
                      || ((col < HRESOLUTION - 4) && (row < VRESOLUTION));

   assign horicount = col;
   assign vertcount = (row == VRESOLUTION - 1) ? 0 : row + 1;

   // horizontal and vertical count
   always @(posedge clk) begin
      // reset horicount
      if (col == HTOTAL - 1) begin
         col <= 0;

         // vertcount control
         if (row == VTOTAL - 1) row <= 0;
         else row <= row + 1;

      end else begin
         col <= col + 1;
      end
   end  // always @ (posedge clk)

endmodule

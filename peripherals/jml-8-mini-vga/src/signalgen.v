/*
 * generates signal timing for VGA stardard specified by "vgaspec.vh"
 */

module signalgen (
    input clk,

    output                        vsync,
    output                        hsync,
    output                        visible,        // in visible region of screen
    output                        prepline,       // should be preparing the next line
    output reg [HCOUNT_BITSREQ:0] horicount = 0,
    output reg [HCOUNT_BITSREQ:0] vertcount = 0
);

   `include "vgaspecs.vh"

   reg [HCOUNT_BITSREQ:0] row = 0;
   reg [HCOUNT_BITSREQ:0] col = 0;
   wire hvisible, vvisible;
   wire hprepline, vprepline;
   wire reset_vertcount;

   assign hsync = (col < HSYNC_BEGIN || col >= HSYNC_END);
   assign vsync = (row < VSYNC_BEGIN || row >= VSYNC_END);

   assign hvisible = (col > HVISIBLE_BEGIN && col <= HVISIBLE_END);
   assign vvisible = (row > VVISIBLE_BEGIN && row <= VVISIBLE_END);
   assign visible = hvisible && vvisible;

   assign hprepline = (col > HPREPLINE_BEGIN && col <= HPREPLINE_END);
   assign vprepline = (row > VPREPLINE_BEGIN && row <= VPREPLINE_END);
   assign prepline = hprepline && vprepline;

   assign reset_vertcount = (row == VVISIBLE_BEGIN) || (row == VVISIBLE_END);


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

   // what we show to outside world (for preparing video)
   always @(posedge clk) begin
      if (prepline) begin
         horicount <= horicount + 1;
      end
      if (col == 0) begin
         horicount <= 0;
         if (reset_vertcount) vertcount <= 0;
         else vertcount <= vertcount + 1;
      end
   end

endmodule

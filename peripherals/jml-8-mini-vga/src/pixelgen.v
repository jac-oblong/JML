module pixelgen (
    input                    clk,
    input                    visible,
    input                    startline,
    input [HCOUNT_BITSREQ:0] horicount,
    input [HCOUNT_BITSREQ:0] vertcount,

    output pixel
);

   `include "vgaspecs.vh"

   wire [7:0] character;
   wire [7:0] pixels_nextline;
   wire [7:0] pixels_thisline;

   reg [2:0] counter = 0;
   reg [7:0] pixels = 0;
   reg [DUALPORT_BITSREQ:0] w_addr = HTILES;
   reg [DUALPORT_BITSREQ:0] r_addr = 0;

   assign pixel = pixels[0];

   charrom #() character_rom (
       .addr(character),
       .row(vertcount[2:0]),
       .pixels(pixels_nextline)
   );

   videoram #() video_ram (
       .visible  (visible),
       .horicount(horicount),
       .vertcount(vertcount),
       .character(character)
   );

   dualport #() dual_port_ram (
       .w_clk (clk),
       .r_clk (clk),
       .w_en  (visible),
       .r_en  (startline),
       .w_addr(w_addr),
       .r_addr(r_addr),
       .w_data(pixels_nextline),
       .r_data(pixels_thisline)
   );

   always @(posedge clk) counter <= counter + 1;

   always @(posedge clk) begin
      if (visible && counter == 2) begin
         w_addr <= w_addr + 1;
      end

      if ((startline || visible) && counter == 2) begin
         r_addr <= r_addr + 1;
      end
   end

   always @(posedge clk) begin
      if (startline || visible) begin
         if (counter == 0) pixels <= pixels_thisline;
         else pixels <= (pixels >> 1);
      end
   end

endmodule

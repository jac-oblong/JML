module pixelgen (
    input                    clk,
    input                    prepline,
    input [HCOUNT_BITSREQ:0] nextline,
    input [HCOUNT_BITSREQ:0] horicount,

    output pixel
);

   `include "vgaspecs.vh"

   wire [7:0] character;
   wire [7:0] pixels_nextline;
   wire [7:0] pixels_thisline;

   reg [2:0] counter = 0;
   reg [15:0] pixels = 0;
   reg [DUALPORT_BITSREQ:0] w_addr = HTILES;
   reg [DUALPORT_BITSREQ:0] r_addr = 0;

   assign pixel = pixels[0];

   charrom #() character_rom (
       .addr(character),
       .row(nextline[2:0]),
       .pixels(pixels_nextline)
   );

   videoram #() video_ram (
       .prepline (prepline),
       .horicount(horicount),
       .vertcount(nextline),
       .character(character)
   );

   dualport #() dual_port_ram (
       .w_clk (clk),
       .r_clk (clk),
       .w_en  (prepline),
       .r_en  (prepline),
       .w_addr(w_addr),
       .r_addr(r_addr),
       .w_data(pixels_nextline),
       .r_data(pixels_thisline)
   );

   always @(posedge clk) counter <= counter + 1;

   always @(posedge clk) begin
      if (prepline && counter == 4) begin
         w_addr <= w_addr + 1;
         r_addr <= r_addr + 1;
      end
   end

   always @(posedge clk) begin
      if (prepline) begin
         if (counter == 0) begin
            pixels <= {pixels_thisline, pixels[8:1]};
         end else begin
            pixels <= pixels >> 1;
         end
      end else pixels <= 0;
   end

endmodule

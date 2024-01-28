module toplevel (
    input clk,

    output vsync,
    output hsync,
    output red,
    output green,
    output blue,
    output lum
);

   wire pixel;
   wire visible;
   reg [7:0] character = 65;
   wire [9:0] vertcount;
   wire [9:0] horicount;

   assign red   = pixel;
   assign green = pixel;
   assign blue  = pixel;
   assign lum   = pixel;

   always @(posedge horicount[2]) begin
      if (character == 65) character <= 32;
      if (character == 32) character <= 65;
   end

   signalgen #() signal_generator (
       .clk(clk),
       .vsync(vsync),
       .hsync(hsync),
       .visible(visible),
       .vertcount(vertcount),
       .horicount(horicount)
   );

   chargen #() character_generator (
       .clk(clk),
       .character(character),
       .vertcount(vertcount[2:0]),
       .pixel(pixel)
   );

endmodule

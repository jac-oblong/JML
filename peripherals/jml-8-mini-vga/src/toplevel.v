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
   wire [7:0] character;
   wire [9:0] vertcount;
   wire [9:0] horicount;

   assign red   = pixel;
   assign green = pixel;
   assign blue  = pixel;
   assign lum   = pixel;

   signalgen #() signal_generator (
       .clk(clk),
       .vsync(vsync),
       .hsync(hsync),
       .visible(visible),
       .vertcount(vertcount),
       .horicount(horicount)
   );

   pixelgen #() character_generator (
       .clk(clk),
       .character(character),
       .vertoffset(vertcount[2:0]),
       .pixel(pixel)
   );

   videocont #() video_controller (
       .visible  (visible),
       .horicount(horicount[9:3]),
       .vertcount(vertcount[8:3]),
       .character(character)
   );

endmodule

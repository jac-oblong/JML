module toplevel (
    input clk,
    //input write,
    //input iorq,
    //input [1:0] chipsel,
    //input [7:0] data,

    output vsync,
    output hsync,
    output red,
    output green,
    output blue,
    output lum
);

   `include "vgaspecs.vh"

   wire pixel;
   wire visible;
   wire [HCOUNT_BITSREQ:0] horicount;
   wire [VCOUNT_BITSREQ:0] vertcount;

   assign red   = visible ? pixel : 0;
   assign green = visible ? pixel : 0;
   assign blue  = visible ? pixel : 0;
   assign lum   = visible ? pixel : 0;

   signalgen #() signal_generator (
       .clk(clk),
       .vsync(vsync),
       .hsync(hsync),
       .visible(visible),
       .horicount(horicount),
       .vertcount(vertcount)
   );

   pixelgen #() pixel_generator (
       .clk(clk),
       .visible(visible),
       .horicount(horicount),
       .nextline(vertcount),
       .pixel(pixel)
   );

endmodule

module toplevel (
    input clk,
    input write,
    input iorq,
    input [1:0] chipsel,
    input [7:0] data,

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
   wire datavalid;
   wire [7:0] configdata;
   wire [HCOUNT_BITSREQ:0] horicount;
   wire [VCOUNT_BITSREQ:0] vertcount;

   assign red   = pixel;
   assign green = pixel;
   assign blue  = pixel;
   assign lum   = pixel;

   signalgen #() signal_generator (
       .clk(clk),
       .vsync(vsync),
       .hsync(hsync),
       .visible(visible),
       .horicount(horicount),
       .vertcount(vertcount)
   );

   videoram #() video_ram (
       .visible(visible),
       .horicount(horicount),
       .vertcount(vertcount),
       .pixel(pixel)
   );

   z80interface #() z80_interface (
       .clk(clk),
       .write(write),
       .iorq(iorq),
       .chipsel(chipsel),
       .datain(data),
       .dataout(configdata),
       .valid(datavalid)
   );

endmodule

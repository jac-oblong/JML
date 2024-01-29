module pixelgen (
    input       clk,
    input [7:0] character,
    input [2:0] vertoffset,

    output pixel
);

   reg  [2:0] index = 0;
   wire [7:0] pixels;

   assign pixel = pixels[index];

   always @(posedge clk) index <= index + 1;

   charrom #() character_rom (
       .addr(character),
       .row(vertoffset),
       .pixels(pixels)
   );

endmodule

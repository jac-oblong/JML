module chargen (
    input        clk,
    input  [7:0] character,
    input  [2:0] vertcount,
    output       pixel
);

   reg  [2:0] index = 0;
   wire [7:0] pixels;

   assign pixel = pixels[index];

   always @(posedge clk) index <= index + 1;

   charmem #() character_rom (
       .clk(clk),
       .addr(character),
       .row(vertcount[2:0]),
       .pixels(pixels)
   );

endmodule

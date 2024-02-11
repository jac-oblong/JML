/*
 * At the beginning of the current line, prepares all pixels for the next line
 */

module videoram (
    input                    visible,
    input [HCOUNT_BITSREQ:0] horicount,
    input [VCOUNT_BITSREQ:0] vertcount,

    output pixel
);

   `include "vgaspecs.vh"

   // videoram holds all which character to be displayed
   reg ram[VRESOLUTION-1:0][HRESOLUTION-1:0];
   initial $readmemb("videoram.txt", ram, 0);

   assign pixel = visible ? ram[vertcount][horicount] : 0;

endmodule

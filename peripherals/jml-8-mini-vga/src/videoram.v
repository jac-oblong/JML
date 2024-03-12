/*
 * At the beginning of the current line, prepares all pixels for the next line
 */

module videoram (
    input                    prepline,
    input [HCOUNT_BITSREQ:0] horicount,
    input [VCOUNT_BITSREQ:0] vertcount,

    output [7:0] character
);

   `include "vgaspecs.vh"

   // videoram holds all which character to be displayed
   reg [7:0] ram[VTILES][HTILES];
   initial $readmemh("videoram.txt", ram, 0);

   wire [HTILES_BITSREQ:0] horioffset;
   wire [VTILES_BITSREQ:0] vertoffset;

   assign horioffset = horicount[HCOUNT_BITSREQ:3];
   assign vertoffset = vertcount[VCOUNT_BITSREQ-1:3];

   assign character  = prepline ? ram[vertoffset][horioffset] : 0;

endmodule

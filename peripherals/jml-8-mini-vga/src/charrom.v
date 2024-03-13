module charrom (
    input [7:0] addr,
    input [2:0] row,

    output [7:0] pixels
);

   reg [7:0] chars[0:255][0:7];

   initial $readmemh("charrom.txt", chars, 0);

   assign pixels = chars[addr][row];

endmodule

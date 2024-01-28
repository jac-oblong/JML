module charmem (
    input            clk,
    input      [7:0] addr,
    input      [2:0] row,
    output reg [7:0] pixels
);

   reg [7:0] chars[255:0][7:0];

   initial $readmemh("charmem.txt", chars, 0);

   always @(posedge clk) begin
      pixels <= chars[addr][row];
   end

endmodule

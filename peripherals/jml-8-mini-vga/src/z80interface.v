/*
 * Allows data to pass through when selected by the z80
 */

module z80interface (
    input       clk,
    input       write,
    input       iorq,
    input [1:0] chipsel,
    input [7:0] datain,

    output reg [7:0] dataout,
    output reg       valid
);

   always @(posedge clk) begin
      if (~(write || iorq || chipsel[0] || chipsel[1])) begin
         dataout <= datain;
         valid   <= 1;
      end else valid <= 0;
   end

endmodule

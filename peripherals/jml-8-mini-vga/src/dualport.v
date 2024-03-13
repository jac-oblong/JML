module dualport (
    input                           w_clk,
    input                           r_clk,
    input                           w_en,
    input                           r_en,
    input      [DUALPORT_BITSREQ:0] w_addr,
    input      [DUALPORT_BITSREQ:0] r_addr,
    input      [               7:0] w_data,
    output reg [               7:0] r_data
);

   `include "vgaspecs.vh"

   reg [7:0] mem[0:DUALPORT_SIZE];

   always @(posedge w_clk) begin
      if (w_en) mem[w_addr] <= w_data;
   end

   always @(posedge r_clk) begin
      if (r_en) r_data <= mem[r_addr];
   end

endmodule

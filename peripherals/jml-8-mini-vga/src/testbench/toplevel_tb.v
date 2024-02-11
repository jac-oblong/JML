`timescale 1 ns / 1 ns

module test ();
   reg  clk = 0;
   wire hsync;
   wire vsync;
   wire red;
   wire green;
   wire blue;
   wire lum;

   toplevel #() t (
       .clk  (clk),
       .vsync(vsync),
       .hsync(hsync),
       .red  (red),
       .green(green),
       .blue (blue),
       .lum  (lum)
   );

   always begin
      #1 clk = ~clk;
   end

   initial begin
      $dumpfile("waveform/toplevel.vcd");
      $dumpvars(0, test);
   end

   initial begin
      #1000000 $finish;
   end

endmodule

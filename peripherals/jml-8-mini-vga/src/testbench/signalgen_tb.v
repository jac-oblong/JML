`timescale 1 ns / 1 ns

module test ();
   reg  clk = 0;
   wire hsync;
   wire vsync;

   signalgen #() signal_generator (
       .clk  (clk),
       .vsync(vsync),
       .hsync(hsync)
   );

   always begin
      #1 clk = ~clk;
   end

   initial begin
      $dumpfile("waveform/signalgen.vcd");
      $dumpvars(0, test);
   end

   initial begin
      #1000000 $finish;
   end

endmodule

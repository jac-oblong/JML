module toplevel (
    input clk,

    output vsync,
    output hsync,
    output red,
    output green,
    output blue,
    output lum
);

   reg [9:0] hori_counter = 0;
   reg [5:0] quart_counter = 0;
   reg [3:0] counter = 0;

   always @(posedge clk) begin
      if (hori_counter == 799) begin
         hori_counter <= 0;
         quart_counter <= 0;
         counter <= 0;
      end else begin
         hori_counter <= hori_counter + 1;
         if (quart_counter == 39) begin
            quart_counter <= 0;
            counter <= counter + 1;
         end else quart_counter <= quart_counter + 1;
      end
   end

   assign red   = counter[0] ? counter[0] : 1'bZ;
   assign green = counter[1] ? counter[1] : 1'bZ;
   assign blue  = counter[2] ? counter[2] : 1'bZ;
   assign lum   = counter[3] ? counter[3] : 1'bZ;

   signalgen #() signal_generator (
       .clk  (clk),
       .vsync(vsync),
       .hsync(hsync)
   );

endmodule

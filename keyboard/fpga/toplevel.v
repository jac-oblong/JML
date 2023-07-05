/*
* Toplevel design of the keyboard module
*/

module toplevel (
    input        ps2_data,  // ps2 keyboard data line
    ps2_clk,  // ps2 keyboard clock line
    clk,
    output       cpu_intr,  // line used to interrupt the cpu
    output [7:0] ascii_out  // ascii charactercode to send to cpu
);

  wire modified_clk;


endmodule

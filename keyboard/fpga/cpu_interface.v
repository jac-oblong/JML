/*
* communicates with the cpu, generating an interrupt, and sending the data
*/

module cpu_interface (
    input [7:0] ascii,
    input       ascii_valid,
    input       ctrl,
    input       alt,

    output reg [7:0] data_lines,
    output reg       cpu_interrupt
);

endmodule

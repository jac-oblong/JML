module videocont (
    input visible,
    input [6:0] horicount,
    input [5:0] vertcount,

    output [7:0] character
);

   reg [7:0] videoram[59:0][79:0];

   initial $readmemh("videoram.txt", videoram, 0);

   assign character = visible ? videoram[vertcount][horicount] : 0;


endmodule

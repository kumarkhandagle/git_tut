module barrel_shifter (
    input  [7:0] data_in,
    input  [2:0] shift,
    output [7:0] data_out
);

assign data_out = data_in << shift;

endmodule

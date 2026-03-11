`timescale 1ns/1ps

module barrel_shifter_tb;

reg  [7:0] data_in;
reg  [2:0] shift;
wire [7:0] data_out;

barrel_shifter uut (
    .data_in(data_in),
    .shift(shift),
    .data_out(data_out)
);

initial begin

    $display("DATA_IN SHIFT DATA_OUT");

    data_in = 8'b00001111; shift = 3'b000; #10;
    $display("%b  %d  %b", data_in, shift, data_out);

    data_in = 8'b00001111; shift = 3'b001; #10;
    $display("%b  %d  %b", data_in, shift, data_out);

    data_in = 8'b00001111; shift = 3'b010; #10;
    $display("%b  %d  %b", data_in, shift, data_out);

    data_in = 8'b00001111; shift = 3'b011; #10;
    $display("%b  %d  %b", data_in, shift, data_out);

    data_in = 8'b10101010; shift = 3'b100; #10;
    $display("%b  %d  %b", data_in, shift, data_out);

    $finish;

end

endmodule

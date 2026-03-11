`timescale 1ns/1ps

module tb_up_down_counter;

reg clk;
reg reset;
reg up_down;
wire [15:0] count;

up_down_counter_16bit uut (
    .clk(clk),
    .reset(reset),
    .up_down(up_down),
    .count(count)
);

/* clock generation */
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    reset = 1;
    up_down = 1;
    #10;

    reset = 0;

    /* count up */
    up_down = 1;
    #100;

    /* count down */
    up_down = 0;
    #100;

    /* reset again */
    reset = 1;
    #10;
    reset = 0;

    #50;
    $finish;

end

endmodule

module adder (
    input  [1:0] a,
    input  [1:0] b,
    input        cin,
    output [2:0] sum,
    output       cout
);

assign {cout, sum} = a + b + cin;


endmodule
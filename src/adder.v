module adder (
    input      clk,
    input  [1:0] a,
    input  [1:0] b,
    input        cin,
    output [1:0] sum,
    output       cout
);

//assign {cout, sum} = a + b + cin;
reg [2:0] t_sum;
always@(posedge clk)
begin
t_sum <= a + b;
end

assign sum  <= t_sum;
assign cout <= t_sum[2];


endmodule
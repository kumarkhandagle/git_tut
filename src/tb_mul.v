`timescale 1ns/1ps

module multiplier_tb;

reg  [7:0] a;
reg  [7:0] b;
wire [15:0] product;

multiplier uut (
    .a(a),
    .b(b),
    .product(product)
);

initial begin
    $display("A B PRODUCT");

    a = 8'd3; b = 8'd4; #10;
    $display("%d %d %d", a, b, product);

    a = 8'd5; b = 8'd6; #10;
    $display("%d %d %d", a, b, product);

    a = 8'd10; b = 8'd12; #10;
    $display("%d %d %d", a, b, product);

    a = 8'd15; b = 8'd2; #10;
    $display("%d %d %d", a, b, product);

    $finish;
end

endmodule

`timescale 1ns/1ps

module tb_adder;

reg  [3:0] a;
reg  [3:0] b;
reg        cin;

wire [3:0] sum;
wire       cout;

integer errors = 0;

adder uut (
    .a(a),
    .b(b),
    .cin(cin),
    .sum(sum),
    .cout(cout)
);

// Task to check expected result
task check;
    input [3:0] exp_sum;
    input       exp_cout;
begin
    if ({cout, sum} !== {exp_cout, exp_sum}) begin
        $display("FAIL: a=%b b=%b cin=%b | Expected=%b_%b Got=%b_%b",
                 a, b, cin, exp_cout, exp_sum, cout, sum);
        errors = errors + 1;
    end
    else begin
        $display("PASS: a=%b b=%b cin=%b", a, b, cin);
    end
end
endtask

initial begin
    // Test 1
    a=3; b=5; cin=0; #1;
    check(8,0);

    // Test 2
    a=15; b=1; cin=0; #1;
    check(0,1);

    // Test 3
    a=10; b=5; cin=1; #1;
    check(1,1);

    // Final result
    if (errors == 0) begin
        $display("ALL TESTS PASSED");
        $finish;
    end
    else begin
        $display("TEST FAILED. Errors = %0d", errors);
        $fatal;  // Causes simulator to return non-zero exit code
    end
end

endmodule
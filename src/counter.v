
module up_down_counter_16bit (
    input clk,
    input reset,
    input up_down,          // 1 = up count, 0 = down count
    output reg [15:0] count
);

always @(posedge clk or posedge reset)
begin
    if (reset)
        count <= 16'd0;
    else begin
        if (up_down)
            count <= count + 1;
        else
            count <= count - 1;
    end
end

endmodule

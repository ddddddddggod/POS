module cursor_ctrl (
    input wire clk,
    input wire rst_n,
    input wire btn_up,
    input wire btn_down,
    input wire btn_left,
    input wire btn_right,
    output reg [2:0] cursor_x,
    output reg [3:0] cursor_y
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cursor_x <= 0;
            cursor_y <= 0;
        end else begin
            if (btn_up && cursor_y > 0)
                cursor_y <= cursor_y - 1;
            else if (btn_down && cursor_y < 3)
                cursor_y <= cursor_y + 1;
            else if (btn_left && cursor_x > 0)
                cursor_x <= cursor_x - 1;
            else if (btn_right && cursor_x < 2)
                cursor_x <= cursor_x + 1;
        end
    end
endmodule

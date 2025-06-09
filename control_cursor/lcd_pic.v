module lcd_pic(
    input wire clk_in,
    input wire sys_rst_n,
    input wire [10:0] pix_x,
    input wire [10:0] pix_y,
    input wire [3:0] cursor_x,
    input wire [3:0] cursor_y,
    output reg [23:0] pix_data
);

    parameter BTN_W = 60;
    parameter BTN_H = 60;
    parameter GAP_X = 20;
    parameter GAP_Y = 20;
    parameter ORIGIN_X = 100;
    parameter ORIGIN_Y = 150;

    localparam RED    = 24'hFF0000,
               ORANGE = 24'hFFA500,
               GRAY   = 24'hBEBEBE,
               WHITE  = 24'hFFFFFF,
               BLACK  = 24'h000000,
               YELLOW = 24'hFFFF00;

    reg in_button;
    reg [3:0] btn_row;
    reg [3:0] btn_col;

    integer row, col;
    reg [11:0] btn_left, btn_right;
    reg [11:0] btn_top, btn_bottom;

    always @(*) begin
        in_button = 0;
        btn_row = 0;
        btn_col = 0;
        for (row = 0; row < 4; row = row + 1) begin
            for (col = 0; col < 3; col = col + 1) begin
                btn_left   = ORIGIN_X + col * (BTN_W + GAP_X);
                btn_right  = btn_left + BTN_W;
                btn_top    = ORIGIN_Y + row * (BTN_H + GAP_Y);
                btn_bottom = btn_top + BTN_H;
                if (pix_x >= btn_left && pix_x < btn_right &&
                    pix_y >= btn_top && pix_y < btn_bottom) begin
                    in_button = 1;
                    btn_row = row;
                    btn_col = col;
                end
            end
        end
    end

    always @(*) begin
        if (!sys_rst_n)
            pix_data = BLACK;
        else if (in_button && (btn_row == cursor_y && btn_col == cursor_x))
            pix_data = ORANGE;
        else if (in_button)
            pix_data = GRAY;
        else if (pix_y < 100)
            pix_data = YELLOW;
        else
            pix_data = WHITE;
    end
endmodule

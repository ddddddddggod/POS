module lcd_top (
    input wire sys_clk,
    input wire sys_rst_n,
    input wire btn_up,
    input wire btn_down,
    input wire btn_left,
    input wire btn_right,
    output wire [23:0] rgb_lcd,
    output wire hsync,
    output wire vsync,
    output wire lcd_clk,
    output wire lcd_de,
    output wire lcd_ud,
    output wire lcd_bl
);
    wire lcd_clk_33m;
    wire locked;
    wire rst_n;

    wire [10:0] pix_x;
    wire [10:0] pix_y;
    wire [23:0] pix_data;
    wire [2:0] cursor_x;
    wire [3:0] cursor_y;

    assign rst_n = sys_rst_n & locked;
    assign lcd_ud = 1'b0;

    // 클럭 생성기
    clk_wiz_0 clk_wiz_0_inst (
        .reset(~sys_rst_n),
        .clk_in1(sys_clk),
        .clk_out1(lcd_clk_33m),
        .locked(locked)
    );

    // 버튼 펄스 생성기
    wire btn_up_pulse, btn_down_pulse, btn_left_pulse, btn_right_pulse;

    button_pulse u_btn_up   (.clk(lcd_clk_33m), .rst_n(rst_n), .btn_raw(btn_up),   .btn_pulse(btn_up_pulse));
    button_pulse u_btn_down (.clk(lcd_clk_33m), .rst_n(rst_n), .btn_raw(btn_down), .btn_pulse(btn_down_pulse));
    button_pulse u_btn_left (.clk(lcd_clk_33m), .rst_n(rst_n), .btn_raw(btn_left), .btn_pulse(btn_left_pulse));
    button_pulse u_btn_right(.clk(lcd_clk_33m), .rst_n(rst_n), .btn_raw(btn_right),.btn_pulse(btn_right_pulse));

    // 커서 제어
    cursor_ctrl cursor_ctrl_inst (
        .clk(lcd_clk_33m),
        .rst_n(rst_n),
        .btn_up(btn_up_pulse),
        .btn_down(btn_down_pulse),
        .btn_left(btn_left_pulse),
        .btn_right(btn_right_pulse),
        .cursor_x(cursor_x),
        .cursor_y(cursor_y)
    );

    // LCD 컨트롤
    lcd_ctrl lcd_ctrl_inst (
        .clk_in(lcd_clk_33m),
        .sys_rst_n(rst_n),
        .data_in(pix_data),
        .data_req(),
        .pix_x(pix_x),
        .pix_y(pix_y),
        .rgb_lcd_24b(rgb_lcd),
        .hsync(hsync),
        .vsync(vsync),
        .lcd_clk(lcd_clk),
        .lcd_de(lcd_de),
        .lcd_bl(lcd_bl)
    );

    // 픽셀 색상
    lcd_pic lcd_pic_inst (
        .clk_in(lcd_clk_33m),
        .sys_rst_n(rst_n),
        .pix_x(pix_x),
        .pix_y(pix_y),
        .cursor_x(cursor_x),
        .cursor_y(cursor_y),
        .pix_data(pix_data)
    );
endmodule

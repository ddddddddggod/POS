`timescale 1ns / 1ps

module lcd_top(
    input wire sys_clk,
    input wire sys_rst_n,

    // 버튼 입력
    input wire btn_up,
    input wire btn_down,
    input wire btn_left,
    input wire btn_right,
    input wire btn_center,  // Enter 버튼

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
    wire [3:0] cursor_x, cursor_y;
    wire [7:0] btn_char;
    wire btn_valid;

    // FSM 내부 출력 → lcd_pic 연결용
    wire [7:0] disp_char0;
    wire [7:0] disp_char1;
    wire [7:0] op_char;
    wire [7:0] input_val;
    wire [15:0] result;
    wire calc_done;

    // 리셋 조건
    assign rst_n = (sys_rst_n & locked);
    assign lcd_ud = 1'b0;

    // PLL (33MHz)
    clk_wiz_0 clk_wiz_0_inst (
        .reset(~sys_rst_n),
        .clk_in1(sys_clk),
        .clk_out1(lcd_clk_33m),
        .locked(locked)
    );

    // 커서 제어
    cursor_ctrl cursor_ctrl_inst (
        .clk(lcd_clk_33m),
        .rst_n(rst_n),
        .btn_up(btn_up),
        .btn_down(btn_down),
        .btn_left(btn_left),
        .btn_right(btn_right),
        .cursor_x(cursor_x),
        .cursor_y(cursor_y)
    );

    // 버튼 입력 처리
    button_input button_input_inst (
        .clk(lcd_clk_33m),
        .rst_n(rst_n),
        .cursor_x(cursor_x),
        .cursor_y(cursor_y),
        .btn_enter(btn_center),
        .btn_char(btn_char),
        .btn_valid(btn_valid)
    );

    // 계산 FSM
    calc_fsm calc_fsm_inst (
        .clk(lcd_clk_33m),
        .rst_n(rst_n),
        .btn_valid(btn_valid),
        .btn_char(btn_char),
        .disp_char0(disp_char0),
        .disp_char1(disp_char1),
        .op_char(op_char),
        .input_val(input_val),
        .result_value(result),     // 수정된 포트명
        .result_valid(calc_done)   // 수정된 포트명
    );

    // LCD 픽셀 생성
    lcd_pic lcd_pic_inst (
        .clk_in(lcd_clk_33m),
        .sys_rst_n(rst_n),
        .pix_x(pix_x),
        .pix_y(pix_y),
        .cursor_x(cursor_x),
        .cursor_y(cursor_y),
        .input_val(input_val),
        .result(result),
        .op_char(op_char),
        .calc_done(calc_done),
        .pix_data(pix_data)
    );

    // LCD 출력 제어
    lcd_ctrl lcd_ctrl_inst (
        .clk_in(lcd_clk_33m),
        .sys_rst_n(rst_n),
        .data_in(pix_data),
        .data_req(), // 사용하지 않음
        .pix_x(pix_x),
        .pix_y(pix_y),
        .rgb_lcd_24b(rgb_lcd),
        .hsync(hsync),
        .vsync(vsync),
        .lcd_clk(lcd_clk),
        .lcd_de(lcd_de),
        .lcd_bl(lcd_bl)
    );

endmodule



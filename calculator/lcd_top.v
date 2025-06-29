`timescale 1ns / 1ps

module lcd_top(
    input wire sys_clk,
    input wire sys_rst_n,

    input wire btn_up,
    input wire btn_down,
    input wire btn_left,
    input wire btn_right,
    input wire btn_center,

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

    wire [255:0] disp_str_flat;       // ? 128 → 256비트 (32자 입력)
    wire [7:0] op_char;
    wire [15:0] input_val;
    wire [31:0] result;               // ? 16 → 32비트
    wire calc_done;

    assign rst_n = (sys_rst_n & locked);
    assign lcd_ud = 1'b0;

    // PLL for 33MHz LCD clock
    clk_wiz_0 clk_wiz_0_inst (
        .reset(~sys_rst_n),
        .clk_in1(sys_clk),
        .clk_out1(lcd_clk_33m),
        .locked(locked)
    );

    // Cursor control
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

    // Button input handler
    button_input button_input_inst (
        .clk(lcd_clk_33m),
        .rst_n(rst_n),
        .cursor_x(cursor_x),
        .cursor_y(cursor_y),
        .btn_enter(btn_center),
        .btn_char(btn_char),
        .btn_valid(btn_valid)
    );

    // Calculator FSM
    calc_fsm calc_fsm_inst (
        .clk(lcd_clk_33m),
        .rst_n(rst_n),
        .btn_valid(btn_valid),
        .btn_char(btn_char),
        .disp_str_flat(disp_str_flat),  // ? 확장 반영
        .op_char(op_char),
        .input_val(input_val),
        .result_value(result),          // ? 32비트
        .result_valid(calc_done)
    );

    // LCD UI Rendering
    lcd_pic lcd_pic_inst (
        .clk_in(lcd_clk_33m),
        .sys_rst_n(rst_n),
        .pix_x(pix_x),
        .pix_y(pix_y),
        .cursor_x(cursor_x),
        .cursor_y(cursor_y),
        .disp_str_flat(disp_str_flat),  // ? 256비트 입력
        .result(result),                // ? 32비트 결과
        .calc_done(calc_done),
        .pix_data(pix_data)
    );

    // LCD Signal Output
    lcd_ctrl lcd_ctrl_inst (
        .clk_in(lcd_clk_33m),
        .sys_rst_n(rst_n),
        .data_in(pix_data),
        .data_req(), // unused
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

`timescale 1ns / 1ps

module lcd_pic(
    input wire clk_in,
    input wire sys_rst_n,
    input wire [10:0] pix_x,
    input wire [10:0] pix_y,
    input wire [3:0] cursor_x,
    input wire [3:0] cursor_y,

    input wire [7:0] input_val,
    input wire [15:0] result,
    input wire [7:0] op_char,
    input wire calc_done,

    output reg [23:0] pix_data_ui
);

    // 위치 및 크기 설정
    localparam BTN_W = 60, BTN_H = 60;
    localparam GAP_X = 20, GAP_Y = 20;
    localparam ORIGIN_X = 100, ORIGIN_Y = 150;
    localparam FONT_W = 8, FONT_H = 8;

    // 색상 정의
    localparam RED    = 24'hFF0000,
               ORANGE = 24'hFFA500,
               GRAY   = 24'hBEBEBE,
               WHITE  = 24'hFFFFFF,
               BLACK  = 24'h000000,
               YELLOW = 24'hFFFF00;

    // 버튼 위치 계산
    reg in_button;
    reg [3:0] btn_row, btn_col;
    integer row, col;
    reg [11:0] btn_left, btn_right, btn_top, btn_bottom;

    always @(*) begin
        in_button = 0;
        btn_row = 0;
        btn_col = 0;
        for (row = 0; row < 4; row = row + 1) begin
            for (col = 0; col < 4; col = col + 1) begin
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

    // 버튼 내 문자 매핑
    reg [7:0] char_code;
    always @(*) begin
        case ({btn_row, btn_col})
            8'h00: char_code = "1";  8'h01: char_code = "2";  8'h02: char_code = "3";  8'h03: char_code = "+";
            8'h10: char_code = "4";  8'h11: char_code = "5";  8'h12: char_code = "6";  8'h13: char_code = "-";
            8'h20: char_code = "7";  8'h21: char_code = "8";  8'h22: char_code = "9";  8'h23: char_code = "*";
            8'h30: char_code = "C";  8'h31: char_code = "0";  8'h32: char_code = "=";  8'h33: char_code = " ";
            default: char_code = 8'd0;
        endcase
    end

    // 버튼 안 문자 위치
    reg [10:0] char_left, char_top;
    wire [3:0] font_x = (pix_x - char_left) >> 1;
    wire [3:0] font_y = (pix_y - char_top) >> 1;
    wire [7:0] font_bits;

    always @(*) begin
        char_left = ORIGIN_X + btn_col * (BTN_W + GAP_X) + 18;
        char_top  = ORIGIN_Y + btn_row * (BTN_H + GAP_Y) + 18;
    end

    font_rom font_rom_inst (
        .clk(clk_in),
        .char_code(char_code),
        .row(font_y),
        .font_line(font_bits)
    );

    // 결과 문자열 구성
    reg [7:0] result_str[0:31];
    reg [7:0] current_char;
    reg [10:0] txt_x, txt_y;
    reg [3:0] font_x_res, font_y_res;
    wire [7:0] font_line_res;
    reg is_result_area;
    integer i;

    font_rom font_rom_result (
        .clk(clk_in),
        .char_code(current_char),
        .row(font_y_res),
        .font_line(font_line_res)
    );

    always @(*) begin
        for (i = 0; i < 32; i = i + 1)
            result_str[i] = " ";

        if (input_val != 0) begin
            result_str[0] = input_val;
            result_str[1] = " ";
        end
        if (op_char != 0) begin
            result_str[2] = op_char;
            result_str[3] = " ";
        end
        if (calc_done) begin
            result_str[4] = "=";
            result_str[5] = " ";
            result_str[6]  = ((result / 10000) % 10) + "0";
            result_str[7]  = ((result / 1000) % 10) + "0";
            result_str[8]  = ((result / 100) % 10) + "0";
            result_str[9]  = ((result / 10) % 10) + "0";
            result_str[10] = (result % 10) + "0";
        end
    end

    // LCD 픽셀 색 결정
    always @(*) begin
        pix_data_ui = WHITE;
        is_result_area = 0;
        font_x_res = 0;
        font_y_res = 0;
        current_char = 0;

        if (!sys_rst_n)
            pix_data_ui = BLACK;
        else if (pix_y < 100)
            pix_data_ui = YELLOW;
        else begin
            // 결과 출력 영역 (폰트 2배 확대)
            txt_x = ORIGIN_X + 4 * (BTN_W + GAP_X) + 40;
            txt_y = ORIGIN_Y;

            for (i = 0; i < 16; i = i + 1) begin
                if (pix_x >= txt_x + i * FONT_W * 2 &&
                    pix_x <  txt_x + i * FONT_W * 2 + FONT_W * 2 &&
                    pix_y >= txt_y &&
                    pix_y <  txt_y + FONT_H * 2) begin
                    font_x_res = (pix_x - (txt_x + i * FONT_W * 2)) >> 1;
                    font_y_res = (pix_y - txt_y) >> 1;
                    current_char = result_str[i];
                    is_result_area = 1;
                end
            end

            if (is_result_area && font_line_res[7 - font_x_res])
                pix_data_ui = RED;
            else if (pix_x >= char_left && pix_x < char_left + 16 &&
                     pix_y >= char_top && pix_y < char_top + 16 &&
                     font_x < 8 && font_y < 8 &&
                     font_bits[7 - font_x])
                pix_data_ui = BLACK;
            else if (in_button && (btn_row == cursor_y && btn_col == cursor_x))
                pix_data_ui = ORANGE;
            else if (in_button)
                pix_data_ui = GRAY;
            else
                pix_data_ui = WHITE;
        end
    end

endmodule

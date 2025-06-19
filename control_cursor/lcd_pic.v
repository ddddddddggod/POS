`timescale 1ns / 1ps

module lcd_pic(
    input wire clk_in,
    input wire sys_rst_n,
    input wire [10:0] pix_x,
    input wire [10:0] pix_y,
    input wire [3:0] cursor_x,
    input wire [3:0] cursor_y,

    input wire [15:0] input_val_a,
    input wire [15:0] input_val_b,
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

    // 버튼 안 문자 매핑
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

    // 결과 문자열 출력용 문자 1개씩
    reg [7:0] current_char;
    wire [3:0] font_x_res;
    wire [3:0] font_y_res;
    wire [7:0] font_line_res;
    reg is_result_area;
    reg [10:0] txt_x, txt_y;
    integer i;

    assign font_x_res = (pix_x - txt_x) >> 1;
    assign font_y_res = (pix_y - txt_y) >> 1;

    font_rom font_rom_result (
        .clk(clk_in),
        .char_code(current_char),
        .row(font_y_res),
        .font_line(font_line_res)
    );

    // 자리수 숫자 구하는 함수 (0: 1의 자리, 1: 10의 자리 ...)
    function [7:0] get_digit_char;
        input [15:0] val;
        input [2:0] digit_idx;
        reg [15:0] tmp;
        begin
            tmp = val;
            case (digit_idx)
                3'd0: get_digit_char = (tmp % 10) + "0";
                3'd1: get_digit_char = ((tmp / 10) % 10) + "0";
                3'd2: get_digit_char = ((tmp / 100) % 10) + "0";
                3'd3: get_digit_char = ((tmp / 1000) % 10) + "0";
                3'd4: get_digit_char = ((tmp / 10000) % 10) + "0";
                default: get_digit_char = " ";
            endcase
        end
    endfunction

    always @(*) begin
        pix_data_ui = WHITE;
        is_result_area = 0;
        current_char = " ";

        if (!sys_rst_n) begin
            pix_data_ui = BLACK;
        end else if (pix_y < 100) begin
            pix_data_ui = YELLOW;
        end else begin
            // 결과 표시 시작 좌표
            txt_x = ORIGIN_X + 4 * (BTN_W + GAP_X) + 40;
            txt_y = ORIGIN_Y;

            // 19글자(0~18)까지 위치별로 문자 출력
            for (i = 0; i < 19; i = i + 1) begin
                if (pix_x >= txt_x + i * FONT_W * 2 &&
                    pix_x <  txt_x + i * FONT_W * 2 + FONT_W * 2 &&
                    pix_y >= txt_y &&
                    pix_y <  txt_y + FONT_H * 2) begin

                    case (i)
                        // input_val_a 최대 5자리 (앞자리부터 출력, 없으면 공백)
                        0: current_char = (input_val_a >= 10000) ? get_digit_char(input_val_a,4) : " ";
                        1: current_char = (input_val_a >= 1000)  ? get_digit_char(input_val_a,3) : " ";
                        2: current_char = (input_val_a >= 100)   ? get_digit_char(input_val_a,2) : " ";
                        3: current_char = (input_val_a >= 10)    ? get_digit_char(input_val_a,1) : " ";
                        4: current_char = (input_val_a > 0)      ? get_digit_char(input_val_a,0) : " ";

                        5: current_char = " "; // 공백

                        // 연산자 출력
                        6: current_char = (op_char != 0) ? op_char : " ";

                        7: current_char = " "; // 공백

                        // input_val_b 최대 5자리
                        8:  current_char = (input_val_b >= 10000) ? get_digit_char(input_val_b,4) : " ";
                        9:  current_char = (input_val_b >= 1000)  ? get_digit_char(input_val_b,3) : " ";
                        10: current_char = (input_val_b >= 100)   ? get_digit_char(input_val_b,2) : " ";
                        11: current_char = (input_val_b >= 10)    ? get_digit_char(input_val_b,1) : " ";
                        12: current_char = (input_val_b > 0)      ? get_digit_char(input_val_b,0) : " ";

                        // '=' 출력 (계산 완료 시에만)
                        13: current_char = (calc_done) ? "=" : " ";

                        // 결과 최대 5자리 출력 (계산 완료 시에만)
                        14: current_char = (calc_done) ? get_digit_char(result,4) : " ";
                        15: current_char = (calc_done) ? get_digit_char(result,3) : " ";
                        16: current_char = (calc_done) ? get_digit_char(result,2) : " ";
                        17: current_char = (calc_done) ? get_digit_char(result,1) : " ";
                        18: current_char = (calc_done) ? get_digit_char(result,0) : " ";

                        default: current_char = " ";
                    endcase

                    is_result_area = 1;
                end
            end

            // 문자 픽셀 그리기 (결과 영역)
            if (is_result_area && font_line_res[7 - font_x_res])
                pix_data_ui = RED;
            // 버튼 문자 그리기
            else if (pix_x >= char_left && pix_x < char_left + 16 &&
                     pix_y >= char_top && pix_y < char_top + 16 &&
                     font_x < 8 && font_y < 8 &&
                     font_bits[7 - font_x])
                pix_data_ui = BLACK;
            // 커서 위치 오렌지 표시
            else if (in_button && (btn_row == cursor_y && btn_col == cursor_x))
                pix_data_ui = ORANGE;
            else if (in_button)
                pix_data_ui = GRAY;
            else
                pix_data_ui = WHITE;
        end
    end

endmodule

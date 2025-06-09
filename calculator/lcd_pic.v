`timescale 1ns / 1ps

module lcd_pic(
    input wire clk_in,
    input wire sys_rst_n,
    input wire [10:0] pix_x,
    input wire [10:0] pix_y,
    output reg [23:0] pix_data
);

    //--------------------------------------------
    // 버튼 매핑 (계산기 UI)
    //--------------------------------------------
    parameter BTN_W = 60;
    parameter BTN_H = 60;
    parameter GAP_X = 20;
    parameter GAP_Y = 20;
    parameter ORIGIN_X = 100;
    parameter ORIGIN_Y = 150;

    //--------------------------------------------
    // 색상 정의
    //--------------------------------------------
    localparam RED    = 24'hFF0000,
               ORANGE = 24'hFFA500,
               GRAY   = 24'hBEBEBE,
               WHITE  = 24'hFFFFFF,
               BLACK  = 24'h000000,
               YELLOW = 24'hFFFF00;

    // 커서 위치 (임시 고정: 숫자 5 위치)
    wire [3:0] cursor_x = 1;
    wire [3:0] cursor_y = 1;

    //--------------------------------------------
    // 버튼 탐지
    //--------------------------------------------
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

    //--------------------------------------------
    // 문자 코드 매핑
    //--------------------------------------------
    reg [7:0] char_code;
    always @(*) begin
        case ({btn_row, btn_col})
            8'h00: char_code = "1";
            8'h01: char_code = "2";
            8'h02: char_code = "3";
            8'h10: char_code = "4";
            8'h11: char_code = "5";
            8'h12: char_code = "6";
            8'h20: char_code = "7";
            8'h21: char_code = "8";
            8'h22: char_code = "9";
            8'h30: char_code = "+";
            8'h31: char_code = "0";
            8'h32: char_code = "=";
            default: char_code = 8'd0;
        endcase
    end

    //--------------------------------------------
    // 문자 좌표 및 출력 여부
    //--------------------------------------------
    reg [10:0] char_left, char_top;
    wire [3:0] font_x = (pix_x - char_left) >> 1; // 확대 표시: 2x 스케일
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

    //--------------------------------------------
    // 픽셀 색상 출력
    //--------------------------------------------
    always @(*) begin
        if (!sys_rst_n)
            pix_data = BLACK;
        else if (pix_y < 100)
            pix_data = YELLOW;
        else if (pix_x >= char_left && pix_x < char_left + 16 &&
                 pix_y >= char_top  && pix_y < char_top + 16 &&
                 font_x < 8 && font_y < 8 &&
                 font_bits[7 - font_x])
            pix_data = BLACK; // 글자 출력 (확대됨)
        else if (in_button && (btn_row == cursor_y && btn_col == cursor_x))
            pix_data = ORANGE;  // 커서 강조
        else if (in_button)
            pix_data = GRAY;    // 일반 버튼
        else
            pix_data = WHITE;   // 배경
    end

endmodule

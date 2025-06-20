`timescale 1ns / 1ps

module lcd_pic(
    input wire clk_in,
    input wire sys_rst_n,
    input wire [10:0] pix_x,
    input wire [10:0] pix_y,
    input wire [3:0] cursor_x,
    input wire [3:0] cursor_y,

    input wire [255:0] disp_str_flat,  // 입력 문자열 (32자)
    input wire [31:0] result,          // ✅ 연산 결과 (10자리까지 지원)
    input wire calc_done,              // '=' 눌렸는지 여부

    output reg [23:0] pix_data
);

    // 문자열 배열로 분해
    wire [7:0] disp_str [0:31];
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : UNPACK
            assign disp_str[i] = disp_str_flat[i*8 +: 8];
        end
    endgenerate

    // 위치 설정
    localparam BTN_W = 60, BTN_H = 60;
    localparam GAP_X = 20, GAP_Y = 20;
    localparam ORIGIN_X = 100, ORIGIN_Y = 150;
    localparam FONT_W = 8, FONT_H = 8;
    localparam TEXT_X = ORIGIN_X + 4 * (BTN_W + GAP_X) + 40;
    localparam INPUT_Y1 = ORIGIN_Y;
    localparam INPUT_Y2 = ORIGIN_Y + 20;
    localparam RESULT_Y = ORIGIN_Y + 50;

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
        for (row = 0; row < 4; row = row + 1)
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

    // 버튼 문자 매핑
    reg [7:0] char_code;
    always @(*) begin
        case ({btn_row, btn_col})
            8'h00: char_code = "1";  8'h01: char_code = "2";  8'h02: char_code = "3";  8'h03: char_code = "+";
            8'h10: char_code = "4";  8'h11: char_code = "5";  8'h12: char_code = "6";  8'h13: char_code = "-";
            8'h20: char_code = "7";  8'h21: char_code = "8";  8'h22: char_code = "9";  8'h23: char_code = "*";
            8'h30: char_code = "C";  8'h31: char_code = "0";  8'h32: char_code = "=";  8'h33: char_code = "B";
            default: char_code = 8'd0;
        endcase
    end

    // 폰트 좌표 계산
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

    // 입력 및 결과 문자열 표시용
    reg [7:0] current_char;
    wire [3:0] font_x_disp = (pix_x - TEXT_X) >> 1;
    wire [3:0] font_y1 = (pix_y - INPUT_Y1) >> 1;
    wire [3:0] font_y2 = (pix_y - INPUT_Y2) >> 1;
    wire [3:0] font_y_result = (pix_y - RESULT_Y) >> 1;
    wire [7:0] font_line_disp1, font_line_disp2, font_line_result;

    font_rom font_rom_disp1 (
        .clk(clk_in), .char_code(current_char), .row(font_y1), .font_line(font_line_disp1)
    );
    font_rom font_rom_disp2 (
        .clk(clk_in), .char_code(current_char), .row(font_y2), .font_line(font_line_disp2)
    );
    font_rom font_rom_result (
        .clk(clk_in), .char_code(current_char), .row(font_y_result), .font_line(font_line_result)
    );

    integer k;

    always @(*) begin
        pix_data = WHITE;
        current_char = " ";

        if (!sys_rst_n)
            pix_data = BLACK;
        else if (pix_y < 100)
            pix_data = YELLOW;
        else begin
            // 첫 줄 입력 (0~15)
            for (k = 0; k < 16; k = k + 1) begin
                if (pix_x >= TEXT_X + k * 16 && pix_x < TEXT_X + (k + 1) * 16 &&
                    pix_y >= INPUT_Y1 && pix_y < INPUT_Y1 + 16) begin
                    current_char = disp_str[k];
                    if (font_line_disp1[7 - font_x_disp])
                        pix_data = RED;
                end
            end
            // 둘째 줄 입력 (16~31)
            for (k = 0; k < 16; k = k + 1) begin
                if (pix_x >= TEXT_X + k * 16 && pix_x < TEXT_X + (k + 1) * 16 &&
                    pix_y >= INPUT_Y2 && pix_y < INPUT_Y2 + 16) begin
                    current_char = disp_str[k + 16];
                    if (font_line_disp2[7 - font_x_disp])
                        pix_data = RED;
                end
            end

            // ✅ 결과 출력 (최대 10자리)
            if (calc_done) begin
                for (k = 0; k < 10; k = k + 1) begin
                    if (pix_x >= TEXT_X + k * 16 && pix_x < TEXT_X + (k + 1) * 16 &&
                        pix_y >= RESULT_Y && pix_y < RESULT_Y + 16) begin
                        case (k)
                            0: current_char = (result / 1000000000) % 10 + "0";
                            1: current_char = (result / 100000000) % 10 + "0";
                            2: current_char = (result / 10000000) % 10 + "0";
                            3: current_char = (result / 1000000) % 10 + "0";
                            4: current_char = (result / 100000) % 10 + "0";
                            5: current_char = (result / 10000) % 10 + "0";
                            6: current_char = (result / 1000) % 10 + "0";
                            7: current_char = (result / 100) % 10 + "0";
                            8: current_char = (result / 10) % 10 + "0";
                            9: current_char = result % 10 + "0";
                        endcase
                        if (font_line_result[7 - font_x_disp])
                            pix_data = RED;
                    end
                end
            end

            // 버튼 폰트 출력
            if (pix_x >= char_left && pix_x < char_left + 16 &&
                pix_y >= char_top && pix_y < char_top + 16 &&
                font_x < 8 && font_y < 8 && font_bits[7 - font_x])
                pix_data = BLACK;
            else if (in_button && (btn_row == cursor_y && btn_col == cursor_x))
                pix_data = ORANGE;
            else if (in_button)
                pix_data = GRAY;
        end
    end

endmodule

`timescale 1ns / 1ps

module lcd_top(
    input wire sys_clk,
    input wire sys_rst_n,

    // ? 버튼 입력 추가
    input wire btn_up,
    input wire btn_down,
    input wire btn_left,
    input wire btn_right,

    input wire [7:0] dip_sw,  // DIP 스위치 입력 (최소 1비트 사용)

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

    wire [10:0] pix_x;  // 800 해상도면 11비트
    wire [10:0] pix_y;  // 480 해상도면 11비트로 통일
    wire [23:0] pix_data;
    wire [3:0] cursor_x, cursor_y;

    // Reset active when locked and switch is ON
    assign rst_n = (sys_rst_n & locked);

    // LCD UP/DOWN 설정 고정
    assign lcd_ud = 1'b0;
    
    wire [23:0] pix_data_ui;   // 숫자패드 UI 화면 픽셀 데이터
    wire [23:0] pix_data_img;  // 이미지 화면 픽셀 데이터

    reg display_mode;  // 0: 숫자패드 UI, 1: 이미지 표시

    // 33MHz 클럭 생성기
    clk_wiz_0 clk_wiz_0_inst (
        .reset(~sys_rst_n),
        .clk_in1(sys_clk),
        .clk_out1(lcd_clk_33m),
        .locked(locked)
    );

    // 커서 컨트롤 모듈
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
    
        // DIP 스위치로 display_mode 제어
    always @(posedge lcd_clk_33m or negedge rst_n) begin
        if (!rst_n)
            display_mode <= 1'b0;
        else
            display_mode <= dip_sw[0];  // SW0 == 1이면 이미지 표시
    end

    // display mode에 따른 픽셀 데이터 선택
    assign pix_data = (display_mode == 1'b0) ? pix_data_ui : pix_data_img;

    // LCD 픽셀 생성
    lcd_pic lcd_pic_inst (
        .clk_in(lcd_clk_33m),
        .sys_rst_n(rst_n),
        .pix_x(pix_x),
        .pix_y(pix_y),
        .cursor_x(cursor_x),       // ? 전달
        .cursor_y(cursor_y),       // ? 전달
        .pix_data_ui(pix_data_ui)
    );

    // LCD 제어 모듈
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
    
    // 이미지 화면
    lcd_pic_image lcd_pic_image_inst (
        .clk_in(lcd_clk_33m),
        .sys_rst_n(rst_n),
        .pix_x(pix_x),
        .pix_y(pix_y),
        .pix_data(pix_data_img)
    );
endmodule

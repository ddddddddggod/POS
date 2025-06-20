`timescale 1ns / 1ps

module lcd_top(
    input wire sys_clk,
    input wire sys_rst_n,

    input wire btn_up,
    input wire btn_down,
    input wire btn_left,
    input wire btn_right,
    input wire btn_center,

    input wire [7:0] dip_sw,
    output wire [3:0] led,

    output wire [23:0] rgb_lcd,
    output wire hsync,
    output wire vsync,
    output wire lcd_clk,
    output wire lcd_de,
    output wire lcd_ud,
    output wire lcd_bl
);

    // === Clock & Reset ===
    wire lcd_clk_33m;
    wire locked;
    wire rst_n = sys_rst_n & locked;

    assign lcd_ud = 1'b0;
    assign led = ~dip_sw[5:2];

    clk_wiz_0 clk_wiz_0_inst (
        .reset(~sys_rst_n),
        .clk_in1(sys_clk),
        .clk_out1(lcd_clk_33m),
        .locked(locked)
    );

    // === Cursor Control ===
    wire [3:0] cursor_x, cursor_y;
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

    // === Button Input ===
    wire [7:0] btn_char;
    wire btn_valid;
    button_input button_input_inst (
        .clk(lcd_clk_33m),
        .rst_n(rst_n),
        .cursor_x(cursor_x),
        .cursor_y(cursor_y),
        .btn_enter(btn_center),
        .btn_char(btn_char),
        .btn_valid(btn_valid)
    );

    // === Mode Select from dip_sw[7] ===
    wire mode_sel = dip_sw[7];  // 0: 메뉴 가격 합산 모드, 1: 직접 입력 계산 모드

    // === FSM Calculator ===
    wire [127:0] disp_str_flat;
    wire [7:0] op_char;
    wire [15:0] input_val;
    wire [23:0] result;
    wire calc_done;

    calc_fsm calc_fsm_inst (
        .clk(lcd_clk_33m),
        .rst_n(rst_n),
        .btn_valid(btn_valid),
        .btn_char(btn_char),
        .mode_sel(mode_sel),       // mode_sel 신호 추가
        .disp_str_flat(disp_str_flat),
        .op_char(op_char),
        .result_value(result),
        .result_valid(calc_done),
        .input_val(input_val)
    );

    // === Display Mode Select ===
    reg display_mode;
    always @(posedge lcd_clk_33m or negedge rst_n) begin
        if (!rst_n) display_mode <= 1'b0;
        else display_mode <= dip_sw[0];
    end

    // === Menu Price (DIP Switch) ===
    reg [15:0] menu_prices [0:3];
    initial begin
        menu_prices[0] = 16'd10000;
        menu_prices[1] = 16'd7000;
        menu_prices[2] = 16'd7000;
        menu_prices[3] = 16'd4000;
    end

    wire [3:0] dip_selected = ~dip_sw[5:2];

    function integer count_ones;
        input [3:0] bits;
        integer i;
        begin
            count_ones = 0;
            for (i = 0; i < 4; i = i + 1)
                count_ones = count_ones + bits[i];
        end
    endfunction

    wire [3:0] num_selected = count_ones(dip_selected);

    reg [15:0] first_price, second_price, sum_price;
    reg [1:0] found_count;
    integer idx;
    always @(*) begin
        sum_price = 0;
        first_price = 0;
        second_price = 0;
        found_count = 0;
        for (idx = 0; idx < 4; idx = idx + 1) begin
            if (dip_selected[idx]) begin
                sum_price = sum_price + menu_prices[idx];
                if (found_count == 0) begin
                    first_price = menu_prices[idx];
                    found_count = 1;
                end else if (found_count == 1) begin
                    second_price = menu_prices[idx];
                    found_count = 2;
                end
            end
        end
    end

    // === ASCII 숫자 변환 Task ===
    reg [7:0] num_a0, num_a1, num_a2, num_a3, num_a4;
    reg [7:0] num_b0, num_b1, num_b2, num_b3, num_b4;

    task encode_number;
        input [15:0] number;
        output [7:0] d0, d1, d2, d3, d4;
        begin
            d0 = (number / 10000) % 10 + "0";
            d1 = (number / 1000) % 10 + "0";
            d2 = (number / 100) % 10 + "0";
            d3 = (number / 10) % 10 + "0";
            d4 = number % 10 + "0";
        end
    endtask

    // === Auto Display Handling ===
    reg [127:0] auto_disp_str_flat;
    reg [23:0] auto_result;
    reg auto_calc_done;

    always @(*) begin
        if (mode_sel == 0) begin
            // 메뉴 가격 합산 모드
            if (num_selected == 0) begin
                auto_disp_str_flat = disp_str_flat;
                auto_result = result;
                auto_calc_done = calc_done;
            end else if (num_selected == 1) begin
                encode_number(first_price, num_a0, num_a1, num_a2, num_a3, num_a4);
                auto_disp_str_flat = {
                    "=", " ",
                    num_a4, num_a3, num_a2, num_a1, num_a0,
                    " ", " ", " ", " ", " ", " ", " ", " "
                };
                auto_result = first_price;
                auto_calc_done = 1'b1;
            end else if (num_selected == 2) begin
                encode_number(first_price, num_a0, num_a1, num_a2, num_a3, num_a4);
                encode_number(second_price, num_b0, num_b1, num_b2, num_b3, num_b4);

                auto_disp_str_flat = {
                    "=", " ",
                    num_b4, num_b3, num_b2, num_b1, num_b0,
                    " ", "+", " ",
                    num_a4, num_a3, num_a2, num_a1, num_a0
                };
                auto_result = first_price + second_price;
                auto_calc_done = 1'b1;
            end else begin
                encode_number(sum_price, num_a0, num_a1, num_a2, num_a3, num_a4);
                auto_disp_str_flat = {
                    "=", " ",
                    num_a4, num_a3, num_a2, num_a1, num_a0,
                    " ", " ", " ", " ", " ", " ", " ", " ", " "
                };
                auto_result = sum_price;
                auto_calc_done = 1'b1;
            end
        end else begin
            // 직접 입력 계산 모드
            auto_disp_str_flat = disp_str_flat;
            auto_result = result;
            auto_calc_done = calc_done;
        end
    end

    wire [127:0] display_disp_str_flat = auto_disp_str_flat;
    wire [23:0]  display_result        = auto_result;
    wire         display_calc_done     = auto_calc_done;

    // === LCD Rendering (UI & Image) ===
    wire [10:0] pix_x, pix_y;
    wire [23:0] pix_data_ui, pix_data_img;
    wire [23:0] pix_data = (display_mode == 1'b0) ? pix_data_ui : pix_data_img;

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

    lcd_pic lcd_pic_inst (
        .clk_in(lcd_clk_33m),
        .sys_rst_n(rst_n),
        .pix_x(pix_x),
        .pix_y(pix_y),
        .cursor_x(cursor_x),
        .cursor_y(cursor_y),
        .disp_str_flat(display_disp_str_flat),
        .result(display_result),
        .calc_done(display_calc_done),
        .pix_data_ui(pix_data_ui)
    );

    lcd_pic_image lcd_pic_image_inst (
        .clk_in(lcd_clk_33m),
        .sys_rst_n(rst_n),
        .pix_x(pix_x),
        .pix_y(pix_y),
        .sw(dip_sw[5:2]),
        .pix_data(pix_data_img)
    );

endmodule

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

    wire lcd_clk_33m;
    wire locked;
    wire rst_n;
    wire [15:0] input_val_a;
    wire [15:0] input_val_b;

    wire [10:0] pix_x;
    wire [10:0] pix_y;
    wire [23:0] pix_data;
    wire [3:0] cursor_x, cursor_y;
    wire [7:0] btn_char;
    wire btn_valid;

    wire [7:0] disp_char0;
    wire [7:0] disp_char1;
    wire [7:0] op_char;
    wire [15:0] result;
    wire calc_done;

    assign rst_n = (sys_rst_n & locked);
    assign lcd_ud = 1'b0;
    assign led = ~dip_sw[5:2];

    wire [23:0] pix_data_ui;
    wire [23:0] pix_data_img;
    reg display_mode;

    // Clock generator
    clk_wiz_0 clk_wiz_0_inst (
        .reset(~sys_rst_n),
        .clk_in1(sys_clk),
        .clk_out1(lcd_clk_33m),
        .locked(locked)
    );

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

    always @(posedge lcd_clk_33m or negedge rst_n) begin
        if (!rst_n)
            display_mode <= 1'b0;
        else
            display_mode <= dip_sw[0];
    end

    assign pix_data = (display_mode == 1'b0) ? pix_data_ui : pix_data_img;

    button_input button_input_inst (
        .clk(lcd_clk_33m),
        .rst_n(rst_n),
        .cursor_x(cursor_x),
        .cursor_y(cursor_y),
        .btn_enter(btn_center),
        .btn_char(btn_char),
        .btn_valid(btn_valid)
    );

    // 가격 설정
    reg [15:0] menu_prices [0:3];
    initial begin
        menu_prices[0] = 16'd10000;
        menu_prices[1] = 16'd7000;
        menu_prices[2] = 16'd7000;
        menu_prices[3] = 16'd4000;
    end

    // DIP 스위치 처리
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

    reg [15:0] sum_price;
    reg [15:0] first_price;
    reg [15:0] second_price;
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

    // 자동 입력 및 연산 결과 생성
    reg [15:0] auto_input_val_a;
    reg [15:0] auto_input_val_b;
    reg [7:0] auto_op_char;
    reg auto_calc_done;
    reg [15:0] auto_result;

    always @(*) begin
        if (num_selected == 1) begin
            auto_input_val_a = sum_price;
            auto_input_val_b = 16'd0;
            auto_op_char = "+";
            auto_calc_done = 1'b0;
            auto_result = 16'd0;
        end else if (num_selected > 1) begin
            auto_input_val_a = first_price;
            auto_input_val_b = second_price;
            auto_op_char = "+";
            auto_calc_done = 1'b1;
            auto_result = first_price + second_price;
        end else begin
            auto_input_val_a = 16'd0;
            auto_input_val_b = 16'd0;
            auto_op_char = 8'd0;
            auto_calc_done = 1'b0;
            auto_result = 16'd0;
        end
    end

    // FSM 인스턴스
    calc_fsm calc_fsm_inst (
        .clk(lcd_clk_33m),
        .rst_n(rst_n),
        .btn_valid(btn_valid),
        .btn_char(btn_char),
        .disp_char0(disp_char0),
        .disp_char1(disp_char1),
        .op_char(op_char),
        .input_val_a(input_val_a),
        .input_val_b(input_val_b),
        .result_value(result),
        .result_valid(calc_done)
    );

    wire [15:0] display_input_val_a = (num_selected >= 1) ? auto_input_val_a : input_val_a;
    wire [15:0] display_input_val_b = (num_selected >= 2) ? auto_input_val_b : input_val_b;
    wire [7:0]  display_op_char     = (num_selected >= 1) ? auto_op_char     : op_char;
    wire        display_calc_done   = (num_selected >= 1) ? auto_calc_done   : calc_done;
    wire [15:0] display_result      = (num_selected >= 2) ? auto_result      : result;

    // lcd_pic 인스턴스
    lcd_pic lcd_pic_inst (
        .clk_in(lcd_clk_33m),
        .sys_rst_n(rst_n),
        .pix_x(pix_x),
        .pix_y(pix_y),
        .cursor_x(cursor_x),
        .cursor_y(cursor_y),
        .input_val_a(display_input_val_a),
        .input_val_b(display_input_val_b),
        .result(display_result),
        .op_char(display_op_char),
        .calc_done(display_calc_done),
        .pix_data_ui(pix_data_ui)
    );

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

    lcd_pic_image lcd_pic_image_inst (
        .clk_in(lcd_clk_33m),
        .sys_rst_n(rst_n),
        .pix_x(pix_x),
        .pix_y(pix_y),
        .sw(dip_sw[5:2]),
        .pix_data(pix_data_img)
    );

endmodule

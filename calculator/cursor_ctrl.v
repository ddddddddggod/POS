`timescale 1ns / 1ps

module cursor_ctrl (
    input wire clk,
    input wire rst_n,

    // 버튼 입력 (Active-Low)
    input wire btn_up,     
    input wire btn_down,   
    input wire btn_left,   
    input wire btn_right,  

    output reg [3:0] cursor_x,
    output reg [3:0] cursor_y
);

    // 버튼 디바운스용 이전 상태 저장
    reg btn_up_d, btn_down_d, btn_left_d, btn_right_d;

    // 상승 에지 검출
    wire up_pulse    = ~btn_up   & btn_up_d;
    wire down_pulse  = ~btn_down & btn_down_d;
    wire left_pulse  = ~btn_left & btn_left_d;
    wire right_pulse = ~btn_right& btn_right_d;

    // 이전 상태 저장
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_up_d    <= 1'b1;
            btn_down_d  <= 1'b1;
            btn_left_d  <= 1'b1;
            btn_right_d <= 1'b1;
        end else begin
            btn_up_d    <= btn_up;
            btn_down_d  <= btn_down;
            btn_left_d  <= btn_left;
            btn_right_d <= btn_right;
        end
    end

    // 커서 위치 업데이트 (x: 0~2, y: 0~3)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cursor_x <= 4'd1;
            cursor_y <= 4'd1;
        end else begin
            if (up_pulse    && cursor_y > 0) cursor_y <= cursor_y - 1;
            if (down_pulse  && cursor_y < 3) cursor_y <= cursor_y + 1;
            if (left_pulse  && cursor_x > 0) cursor_x <= cursor_x - 1;
            if (right_pulse && cursor_x < 2) cursor_x <= cursor_x + 1;
        end
    end

endmodule

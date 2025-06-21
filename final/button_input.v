`timescale 1ns / 1ps

module button_input (
    input wire clk,
    input wire rst_n,
    input wire btn_enter,             // Active-low 입력 (BTNC 등)
    input wire [3:0] cursor_x,
    input wire [3:0] cursor_y,
    output reg [7:0] btn_char,        // ASCII 코드 출력
    output reg       btn_valid        // 1클럭 펄스
);

    reg btn_enter_d;
    wire enter_pulse = ~btn_enter & btn_enter_d;  // rising edge (active-low)

    // 이전 버튼 상태 저장
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            btn_enter_d <= 1'b1;
        else
            btn_enter_d <= btn_enter;
    end

    // 커서 위치 → 문자 매핑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_char  <= 8'd0;
            btn_valid <= 1'b0;
        end else begin
            btn_valid <= 1'b0;
            if (enter_pulse) begin
                case ({cursor_y, cursor_x})
                    8'h00: btn_char <= "1";
                    8'h01: btn_char <= "2";
                    8'h02: btn_char <= "3";
                    8'h03: btn_char <= "+";
                    8'h10: btn_char <= "4";
                    8'h11: btn_char <= "5";
                    8'h12: btn_char <= "6";
                    8'h13: btn_char <= "-";
                    8'h20: btn_char <= "7";
                    8'h21: btn_char <= "8";
                    8'h22: btn_char <= "9";
                    8'h23: btn_char <= "*";
                    8'h30: btn_char <= "C";
                    8'h31: btn_char <= "0";
                    8'h32: btn_char <= "=";
                    8'h33: btn_char <= 8'h08;   // BACKSPACE (ASCII 8)
                    default: btn_char <= 8'd0;
                endcase
                btn_valid <= 1'b1;  // 1클럭 동안 High
            end
        end
    end

endmodule

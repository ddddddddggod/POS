`timescale 1ns / 1ps

module calc_fsm(
    input wire clk,
    input wire rst_n,
    input wire btn_valid,
    input wire [7:0] btn_char,     // '0' ~ '9', '+', '-', '*', '=', 'C'

    output reg [7:0] disp_char0,   // 가장 최근 문자
    output reg [7:0] disp_char1,   // 그 전 문자
    output reg [7:0] op_char,      // 연산자
    output reg [15:0] result_value,// 연산 결과
    output reg        result_valid,// 연산 완료 신호
    output reg [15:0] input_val    // 입력된 피연산자 (표시용)
);

    localparam S_IDLE  = 2'd0;
    localparam S_OPER  = 2'd1;
    localparam S_EQUAL = 2'd2;

    reg [1:0] state;
    reg [15:0] operand_a;
    reg [15:0] operand_b;
    reg input_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= S_IDLE;
            operand_a     <= 16'd0;
            operand_b     <= 16'd0;
            op_char       <= 8'd0;
            disp_char0    <= 8'd0;
            disp_char1    <= 8'd0;
            result_value  <= 16'd0;
            result_valid  <= 1'b0;
            input_val     <= 16'd0;
            input_ready   <= 1'b0;
        end else if (btn_valid) begin
            result_valid <= 1'b0;

            // 초기화
            if (btn_char == "C") begin
                state        <= S_IDLE;
                operand_a    <= 16'd0;
                operand_b    <= 16'd0;
                op_char      <= 8'd0;
                disp_char0   <= 8'd0;
                disp_char1   <= 8'd0;
                result_value <= 16'd0;
                input_val    <= 16'd0;
                input_ready  <= 1'b0;
            end else begin
                disp_char1 <= disp_char0;
                disp_char0 <= btn_char;

                case (state)
                    S_IDLE: begin
                        if (btn_char >= "0" && btn_char <= "9") begin
                            operand_a   <= (operand_a * 10) + (btn_char - "0");
                            input_val   <= (input_val * 10) + (btn_char - "0");
                            input_ready <= 1'b1;
                        end else if ((btn_char == "+" || btn_char == "-" || btn_char == "*") && input_ready) begin
                            op_char     <= btn_char;
                            state       <= S_OPER;
                            input_val   <= 16'd0; // 초기화해서 두 번째 피연산자 표시
                        end
                    end

                    S_OPER: begin
                        if (btn_char >= "0" && btn_char <= "9") begin
                            operand_b   <= (operand_b * 10) + (btn_char - "0");
                            input_val   <= (input_val * 10) + (btn_char - "0");
                        end else if (btn_char == "+" || btn_char == "-" || btn_char == "*") begin
                            op_char <= btn_char; // 연산자 변경 허용
                        end else if (btn_char == "=") begin
                            case (op_char)
                                "+": result_value <= operand_a + operand_b;
                                "-": result_value <= operand_a - operand_b;
                                "*": result_value <= operand_a * operand_b;
                                default: result_value <= 16'hFFFF;
                            endcase
                            result_valid <= 1'b1;
                            state        <= S_IDLE;
                        end
                    end
                endcase
            end
        end
    end
endmodule

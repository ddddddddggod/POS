`timescale 1ns / 1ps

module calc_fsm(
    input wire clk,
    input wire rst_n,
    input wire btn_valid,
    input wire [7:0] btn_char,     // '0' ~ '9', '+', '-', '*', '=', 'C'

    output reg [7:0] disp_char0,   // 가장 최근 문자
    output reg [7:0] disp_char1,   // 그 전 문자
    output reg [7:0] op_char,      // 연산자
    output reg [7:0] input_val,    // 첫 번째 피연산자 (입력용 표시)
    output reg [15:0] result_value, // 연산 결과
    output reg        result_valid  // 연산 완료 신호
);

    localparam S_IDLE  = 2'd0;
    localparam S_OPER  = 2'd1;
    localparam S_EQUAL = 2'd2;

    reg [1:0] state;
    reg [7:0] operand_a;
    reg [7:0] operand_b;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= S_IDLE;
            operand_a     <= 8'd0;
            operand_b     <= 8'd0;
            op_char       <= 8'd0;
            input_val     <= 8'd0;
            disp_char0    <= 8'd0;
            disp_char1    <= 8'd0;
            result_value  <= 16'd0;
            result_valid  <= 1'b0;
        end else if (btn_valid) begin
            result_valid <= 1'b0;

            if (btn_char == "C") begin
                state         <= S_IDLE;
                operand_a     <= 8'd0;
                operand_b     <= 8'd0;
                op_char       <= 8'd0;
                input_val     <= 8'd0;
                disp_char0    <= 8'd0;
                disp_char1    <= 8'd0;
                result_value  <= 16'd0;
            end else begin
                disp_char1 <= disp_char0;
                disp_char0 <= btn_char;

                case (state)
                    S_IDLE: begin
                        if (btn_char >= "0" && btn_char <= "9") begin
                            operand_a  <= btn_char - "0";
                            input_val  <= btn_char;
                            state      <= S_OPER;
                        end
                    end

                    S_OPER: begin
                        if (btn_char == "+" || btn_char == "-" || btn_char == "*") begin
                            op_char <= btn_char;
                            state   <= S_EQUAL;
                        end
                    end

                    S_EQUAL: begin
                        if (btn_char >= "0" && btn_char <= "9") begin
                            operand_b <= btn_char - "0";
                            case (op_char)
                                "+": result_value <= operand_a + (btn_char - "0");
                                "-": result_value <= operand_a - (btn_char - "0");
                                "*": result_value <= operand_a * (btn_char - "0");
                                default: result_value <= 16'hFFFF;
                            endcase
                            result_valid <= 1'b1;
                            state <= S_IDLE;
                        end
                    end
                endcase
            end
        end
    end

endmodule

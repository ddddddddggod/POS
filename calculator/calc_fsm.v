`timescale 1ns / 1ps

module calc_fsm(
    input wire clk,
    input wire rst_n,
    input wire btn_valid,
    input wire [7:0] btn_char,     // '0' ~ '9', '+', '-', '*', '=', 'C', 8'h08(BACKSPACE)

    output reg [255:0] disp_str_flat,   // 전체 입력 문자열 (32자)
    output reg [7:0] op_char,           // 현재 연산자
    output reg [31:0] result_value,     // 결과 값 (최대 8자리)
    output reg        result_valid,     // 결과 유효
    output reg [31:0] input_val         // 현재 입력 중인 숫자
);

    // FSM states
    localparam S_IDLE   = 3'd0;
    localparam S_NEXT   = 3'd1;
    localparam S_EVAL   = 3'd2;
    localparam S_EQUAL  = 3'd3;
    localparam S_CLEAR  = 3'd4;

    reg [2:0] state;

    reg [31:0] operand_stack [0:15];
    reg [7:0]  operator_stack [0:15];
    reg [4:0] operand_top;
    reg [4:0] operator_top;

    reg [5:0] disp_index;
    reg [7:0] disp_str [0:31];

    integer i;

    // 디스플레이 문자열 평탄화
    always @(*) begin
        for (i = 0; i < 32; i = i + 1)
            disp_str_flat[i*8 +: 8] = disp_str[i];
    end

    function [0:0] precedence;
        input [7:0] op;
        begin
            precedence = (op == "*") ? 1 : 0;
        end
    endfunction

    function [31:0] apply_operator;
        input [7:0] op;
        input [31:0] a, b;
        begin
            case (op)
                "+": apply_operator = a + b;
                "-": apply_operator = a - b;
                "*": apply_operator = a * b;
                default: apply_operator = 0;
            endcase
        end
    endfunction

    task eval_once;
        begin
            if (operand_top > 1 && operator_top > 0) begin
                operand_stack[operand_top - 2] <= apply_operator(
                    operator_stack[operator_top - 1],
                    operand_stack[operand_top - 2],
                    operand_stack[operand_top - 1]
                );
                operand_top  <= operand_top - 1;
                operator_top <= operator_top - 1;
            end
        end
    endtask

    task eval_all;
        integer j;
        begin
            for (j = 0; j < 15; j = j + 1) begin
                if (operator_top > 0) eval_once();
            end
        end
    endtask

    // 현재 연산자보다 우선순위가 높거나 같은 연산자들 먼저 계산
    task eval_priority_ops;
        input [7:0] new_op;
        integer k;
        begin
            for (k = 0; k < 15; k = k + 1) begin
                if (operator_top > 0 && precedence(operator_stack[operator_top - 1]) >= precedence(new_op)) begin
                    eval_once();
                end
            end
        end
    endtask

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= S_IDLE;
            operand_top   <= 0;
            operator_top  <= 0;
            op_char       <= 0;
            result_value  <= 0;
            result_valid  <= 0;
            input_val     <= 0;
            disp_index    <= 0;
            for (i = 0; i < 32; i = i + 1)
                disp_str[i] <= " ";
        end else if (btn_valid) begin
            result_valid <= 0;

            if (btn_char == 8'h08) begin  // BACKSPACE
                if (disp_index > 0) begin
                    disp_index <= disp_index - 1;
                    disp_str[disp_index - 1] <= " ";
                end
                if (input_val > 0)
                    input_val <= input_val / 10;
            end else begin
                if (disp_index < 32) begin
                    disp_str[disp_index] <= btn_char;
                    disp_index <= disp_index + 1;
                end

                case (state)
                    S_IDLE: begin
                        if (btn_char >= "0" && btn_char <= "9") begin
                            input_val <= input_val * 10 + (btn_char - "0");
                        end else if ((btn_char == "+" || btn_char == "-" || btn_char == "*") && input_val != 0) begin
                            operand_stack[operand_top] <= input_val;
                            operand_top <= operand_top + 1;
                            input_val <= 0;

                            eval_priority_ops(btn_char);

                            operator_stack[operator_top] <= btn_char;
                            operator_top <= operator_top + 1;
                        end else if (btn_char == "=" && input_val != 0) begin
                            operand_stack[operand_top] <= input_val;
                            operand_top <= operand_top + 1;
                            input_val <= 0;
                            state <= S_EQUAL;
                        end else if (btn_char == "C") begin
                            state <= S_CLEAR;
                        end
                    end

                    S_EQUAL: begin
                        eval_all();
                        if (operator_top == 0 && operand_top > 0) begin
                            result_value <= operand_stack[0];
                            result_valid <= 1'b1;
                            state <= S_NEXT;
                        end
                    end

                    S_NEXT: begin
                        if (btn_char >= "0" && btn_char <= "9") begin
                            operand_top <= 0;
                            operator_top <= 0;
                            disp_index <= 1;
                            for (i = 0; i < 32; i = i + 1)
                                disp_str[i] <= " ";
                            disp_str[0] <= btn_char;
                            input_val <= btn_char - "0";
                            state <= S_IDLE;
                        end else if (btn_char == "C") begin
                            state <= S_CLEAR;
                        end
                    end

                    S_CLEAR: begin
                        operand_top <= 0;
                        operator_top <= 0;
                        op_char <= 0;
                        input_val <= 0;
                        result_value <= 0;
                        result_valid <= 0;
                        disp_index <= 0;
                        for (i = 0; i < 32; i = i + 1)
                            disp_str[i] <= " ";
                        state <= S_IDLE;
                    end
                endcase
            end
        end
    end
endmodule


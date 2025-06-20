`timescale 1ns / 1ps

module calc_fsm(
    input wire clk,
    input wire rst_n,
    input wire btn_valid,
    input wire [7:0] btn_char,  // '0' ~ '9', '+', '-', '*', '=', 'C'
    input wire mode_sel,

    output reg [127:0] disp_str_flat,   // 디스플레이 문자열 (16자)
    output reg [7:0] op_char,           // 마지막 연산자
    output reg [23:0] result_value,     // 계산 결과
    output reg        result_valid,     // 결과 유효 신호
    output reg [15:0] input_val         // 현재 숫자 입력 중 값
);

    // FSM 상태
    localparam S_IDLE   = 3'd0;
    localparam S_INPUT  = 3'd1;
    localparam S_OP     = 3'd2;
    localparam S_EVAL   = 3'd3;
    localparam S_RESULT = 3'd4;
    localparam S_CLEAR  = 3'd5;

    reg [2:0] state;

    // 계산 스택
    reg [15:0] operand_stack [0:7];
    reg [7:0]  operator_stack [0:7];
    reg [3:0] operand_top;
    reg [3:0] operator_top;

    // 디스플레이 버퍼
    reg [7:0] disp_str [0:15];
    reg [4:0] disp_index;

    integer i;

    // 디스플레이 플래튼화
    always @(*) begin
        for (i = 0; i < 16; i = i + 1)
            disp_str_flat[i*8 +: 8] = disp_str[i];
    end

    // 연산자 우선순위 ( * > +,- )
    function [0:0] precedence;
        input [7:0] op;
        begin
            precedence = (op == "*") ? 1'b1 : 1'b0;
        end
    endfunction

    // 연산 수행 함수
    function [15:0] apply_operator;
        input [7:0] op;
        input [15:0] a, b;
        begin
            case (op)
                "+": apply_operator = a + b;
                "-": apply_operator = a - b;
                "*": apply_operator = a * b;
                default: apply_operator = 0;
            endcase
        end
    endfunction

    // 한 번 연산 수행
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

    // 초기화 작업
    task reset_all;
        begin
            operand_top   <= 0;
            operator_top  <= 0;
            input_val     <= 0;
            result_value  <= 0;
            result_valid  <= 0;
            disp_index    <= 0;
            for (i = 0; i < 16; i = i + 1)
                disp_str[i] <= " ";
            op_char <= 0;
        end
    endtask

    // FSM 메인 로직
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            reset_all();
        end else if (btn_valid) begin
            result_valid <= 0;

            if (btn_char == "C") begin
                state <= S_CLEAR;
            end else begin
                // 디스플레이 기록 (Clear 아닐 때만)
                if (disp_index < 16)
                    disp_str[disp_index] <= btn_char;
                if (btn_char != "C" && disp_index < 16)
                    disp_index <= disp_index + 1;
            end

            case (state)
                S_IDLE: begin
                    if (btn_char >= "0" && btn_char <= "9") begin
                        input_val <= btn_char - "0";
                        state <= S_INPUT;
                    end
                end

                S_INPUT: begin
                    if (btn_char >= "0" && btn_char <= "9") begin
                        input_val <= input_val * 10 + (btn_char - "0");
                    end else if (btn_char == "+" || btn_char == "-" || btn_char == "*") begin
                        // 숫자 스택에 넣기
                        operand_stack[operand_top] <= input_val;
                        operand_top <= operand_top + 1;
                        input_val <= 0;

                        // 연산자 우선순위 판단 후 처리
                        if (operator_top > 0 &&
                            precedence(operator_stack[operator_top - 1]) >= precedence(btn_char)) begin
                            op_char <= btn_char;
                            state <= S_EVAL;
                        end else begin
                            operator_stack[operator_top] <= btn_char;
                            operator_top <= operator_top + 1;
                            op_char <= btn_char;
                            state <= S_OP;
                        end
                    end else if (btn_char == "=") begin
                        // 등호 입력시 현재 숫자 스택에 넣고 계산 시작
                        operand_stack[operand_top] <= input_val;
                        operand_top <= operand_top + 1;
                        input_val <= 0;
                        op_char <= "=";
                        state <= S_EVAL;
                    end
                end

                S_OP: begin
                    // 연산자 등록 후 바로 IDLE로
                    state <= S_IDLE;
                end

                S_EVAL: begin
                    eval_once();
                    if (operator_top == 0 || op_char == "=" ||
                        precedence(operator_stack[operator_top - 1]) < precedence(op_char)) begin
                        if (op_char != "=") begin
                            operator_stack[operator_top] <= op_char;
                            operator_top <= operator_top + 1;
                            state <= S_IDLE;
                        end else begin
                            // 계산 완료, 결과 출력
                            result_value <= operand_stack[0];
                            result_valid <= 1;
                            state <= S_RESULT;
                        end
                    end
                end

                S_RESULT: begin
                    // 결과 후 새 입력 시 초기화 및 입력 재개
                    if (btn_char >= "0" && btn_char <= "9") begin
                        reset_all();
                        disp_str[0] <= btn_char;
                        disp_index <= 1;
                        input_val <= btn_char - "0";
                        state <= S_INPUT;
                    end else if (btn_char == "C") begin
                        reset_all();
                        state <= S_IDLE;
                    end
                end

                S_CLEAR: begin
                    reset_all();
                    state <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule

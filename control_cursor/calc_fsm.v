`timescale 1ns / 1ps

module calc_fsm(
    input wire clk,
    input wire rst_n,
    input wire btn_valid,
    input wire [7:0] btn_char,      // '0' ~ '9', '+', '-', '*', '=', 'C', BACKSPACE=8'h08
    input wire mode_sel,            // 0 = 메뉴 가격, 1 = 직접입력
    input wire [15:0] menu_val,     // 메뉴 가격 값

    output reg [255:0] disp_str_flat,
    output reg [7:0] op_char,
    output reg [31:0] result_value,
    output reg        result_valid,
    output reg [31:0] input_val
);

    localparam S_IDLE   = 3'd0;
    localparam S_NEXT   = 3'd1;
    localparam S_EVAL   = 3'd2;
    localparam S_EQUAL  = 3'd3;
    localparam S_CLEAR  = 3'd4;
    localparam S_MENU   = 3'd5;

    reg [2:0] state;

    reg [31:0] operand_stack [0:15];
    reg [7:0]  operator_stack [0:15];
    reg [4:0] operand_top;
    reg [4:0] operator_top;

    reg [5:0] disp_index;
    reg [7:0] disp_str [0:31];

    reg mode_sel_prev;

    integer i;

    // 디스플레이 문자열 평탄화
    always @(*) begin
        for (i = 0; i < 32; i = i + 1)
            disp_str_flat[i*8 +: 8] = disp_str[i];
    end

    function precedence;
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
            for (j = 0; j < 15; j = j + 1)
                if (operator_top > 0)
                    eval_once();
        end
    endtask

    task eval_priority_ops;
        input [7:0] new_op;
        integer k;
        begin
            for (k = 0; k < 15; k = k + 1)
                if (operator_top > 0 && precedence(operator_stack[operator_top - 1]) >= precedence(new_op))
                    eval_once();
        end
    endtask

    task clear_all;
        begin
            operand_top   <= 0;
            operator_top  <= 0;
            op_char       <= 0;
            result_value  <= 0;
            result_valid  <= 0;
            input_val     <= 0;
            disp_index    <= 0;
            for (i = 0; i < 32; i = i + 1)
                disp_str[i] <= " ";
        end
    endtask

    // 가격 표시용 함수
    task show_menu_price;
        reg [15:0] val;
        reg [3:0] digit;
        begin
            val = menu_val;
            for (i = 0; i < 32; i = i + 1)
                disp_str[i] <= " ";
            for (i = 0; i < 5; i = i + 1) begin
                digit = val % 10;
                disp_str[31 - i] <= digit + "0";
                val = val / 10;
            end
        end
    endtask

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            clear_all();
            mode_sel_prev <= 0;
        end else begin
            mode_sel_prev <= mode_sel;

            // mode_sel가 0 -> 1로 바뀌면 자동 초기화
            if (mode_sel == 1 && mode_sel_prev == 0) begin
                clear_all();
                state <= S_IDLE;
            end

            // 메뉴 가격 모드 (mode_sel == 0)
            if (mode_sel == 0) begin
                if (state != S_MENU) begin
                    show_menu_price();
                    result_valid <= 0;
                    state <= S_MENU;
                end
            end
            // 직접 입력 모드 (mode_sel == 1)
            else if (mode_sel == 1) begin
                case(state)
                    S_CLEAR: begin
                        clear_all();
                        state <= S_IDLE;
                    end

                    S_IDLE: begin
                        if (btn_valid) begin
                            result_valid <= 0;

                            if (btn_char == 8'h08) begin
                                if (disp_index > 0) begin
                                    disp_index <= disp_index - 1;
                                    disp_str[disp_index - 1] <= " ";
                                end
                                if (input_val > 0)
                                    input_val <= input_val / 10;
                            end else if (btn_char >= "0" && btn_char <= "9") begin
                                if (disp_index < 32) begin
                                    disp_str[disp_index] <= btn_char;
                                    disp_index <= disp_index + 1;
                                end
                                input_val <= input_val * 10 + (btn_char - "0");
                            end else if ((btn_char == "+" || btn_char == "-" || btn_char == "*") && input_val != 0) begin
                                operand_stack[operand_top] <= input_val;
                                operand_top <= operand_top + 1;
                                input_val <= 0;

                                eval_priority_ops(btn_char);

                                operator_stack[operator_top] <= btn_char;
                                operator_top <= operator_top + 1;

                                if (disp_index < 32) begin
                                    disp_str[disp_index] <= btn_char;
                                    disp_index <= disp_index + 1;
                                end
                            end else if (btn_char == "=" && input_val != 0) begin
                                operand_stack[operand_top] <= input_val;
                                operand_top <= operand_top + 1;
                                input_val <= 0;
                                state <= S_EQUAL;

                                if (disp_index < 32) begin
                                    disp_str[disp_index] <= btn_char;
                                    disp_index <= disp_index + 1;
                                end
                            end else if (btn_char == "C") begin
                                state <= S_CLEAR;
                            end
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
                        if (btn_valid) begin
                            if (btn_char >= "0" && btn_char <= "9") begin
                                clear_all();
                                disp_str[0] <= btn_char;
                                disp_index <= 1;
                                input_val <= btn_char - "0";
                                state <= S_IDLE;
                            end else if (btn_char == "C") begin
                                state <= S_CLEAR;
                            end
                        end
                    end

                    default: begin
                        state <= S_IDLE;
                    end
                endcase
            end
        end
    end

endmodule

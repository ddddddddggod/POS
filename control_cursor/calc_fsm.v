`timescale 1ns / 1ps

module calc_fsm(
    input wire clk,
    input wire rst_n,
    input wire btn_valid,
    input wire [7:0] btn_char,

    output reg [7:0] disp_char0,
    output reg [7:0] disp_char1,
    output reg [7:0] op_char,
    output reg [15:0] input_val_a,
    output reg [15:0] input_val_b,
    output reg [15:0] result_value,
    output reg result_valid
);

    // === [수정된 상태 정의] ===
    parameter IDLE     = 2'b00;
    parameter INPUT_A  = 2'b01;
    parameter INPUT_OP = 2'b10;
    parameter INPUT_B  = 2'b11;
    parameter DONE     = 2'b00;  // DONE은 상태 리셋에 사용 (겹치지 않도록 로직 내에서 주의)

    reg [1:0] current_state, next_state;

    // === 임시 저장 ===
    reg [15:0] temp_a;
    reg [15:0] temp_b;
    reg [7:0]  temp_op;

    // === 상태 전이 ===
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // === 상태 결정 ===
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE:
                if (btn_valid && btn_char >= "0" && btn_char <= "9")
                    next_state = INPUT_A;
            INPUT_A:
                if (btn_valid && (btn_char == "+" || btn_char == "-" || btn_char == "*"))
                    next_state = INPUT_OP;
            INPUT_OP:
                if (btn_valid && btn_char >= "0" && btn_char <= "9")
                    next_state = INPUT_B;
            INPUT_B:
                if (btn_valid && btn_char == "=")
                    next_state = DONE;
            DONE:
                if (btn_valid)
                    next_state = IDLE;
        endcase
    end

    // === 상태에 따른 동작 ===
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_val_a   <= 0;
            input_val_b   <= 0;
            op_char       <= 0;
            result_value  <= 0;
            result_valid  <= 0;
            disp_char0    <= 0;
            disp_char1    <= 0;
            temp_a        <= 0;
            temp_b        <= 0;
            temp_op       <= 0;
        end else if (btn_valid) begin
            case (current_state)
                IDLE: begin
                    if (btn_char >= "0" && btn_char <= "9") begin
                        temp_a <= btn_char - "0";
                        input_val_a <= btn_char - "0";
                        disp_char0 <= btn_char;
                    end
                    result_valid <= 0;
                end
                INPUT_A: begin
                    if (btn_char >= "0" && btn_char <= "9") begin
                        temp_a <= temp_a * 10 + (btn_char - "0");
                        input_val_a <= temp_a * 10 + (btn_char - "0");
                        disp_char0 <= btn_char;
                    end else if (btn_char == "+" || btn_char == "-" || btn_char == "*") begin
                        temp_op <= btn_char;
                        op_char <= btn_char;
                        disp_char1 <= btn_char;
                    end
                end
                INPUT_OP: begin
                    if (btn_char >= "0" && btn_char <= "9") begin
                        temp_b <= btn_char - "0";
                        input_val_b <= btn_char - "0";
                    end
                end
                INPUT_B: begin
                    if (btn_char >= "0" && btn_char <= "9") begin
                        temp_b <= temp_b * 10 + (btn_char - "0");
                        input_val_b <= temp_b * 10 + (btn_char - "0");
                    end else if (btn_char == "=") begin
                        case (op_char)
                            "+": result_value <= temp_a + temp_b;
                            "-": result_value <= temp_a - temp_b;
                            "*": result_value <= temp_a * temp_b;
                            default: result_value <= 16'd0;
                        endcase
                        result_valid <= 1;
                    end
                end
                DONE: begin
                    result_valid <= 0;
                    input_val_a <= 0;
                    input_val_b <= 0;
                    op_char <= 0;
                    temp_a <= 0;
                    temp_b <= 0;
                    temp_op <= 0;
                    disp_char0 <= 0;
                    disp_char1 <= 0;
                end
            endcase
        end
    end

endmodule

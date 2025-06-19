`timescale 1ns / 1ps

module calc_fsm(
    input wire clk,
    input wire rst_n,
    input wire btn_valid,
    input wire [7:0] btn_char,

    output reg [127:0] disp_str_flat,
    output reg [7:0] op_char,
    output reg [23:0] result_value,
    output reg        result_valid,
    output reg [15:0] input_val
);

    localparam S_IDLE  = 2'd0;
    localparam S_OPER  = 2'd1;
    localparam S_EQUAL = 2'd2;

    reg [1:0] state;
    reg [15:0] total;
    reg [15:0] temp_val;
    reg [15:0] mult_val;
    reg [7:0] prev_op;
    reg [4:0] disp_index;
    reg [7:0] disp_str [0:15];
    integer i;

    // Display flattener
    always @(*) begin
        for (i = 0; i < 16; i = i + 1)
            disp_str_flat[i*8 +: 8] = disp_str[i];
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            total <= 0;
            temp_val <= 0;
            mult_val <= 0;
            prev_op <= 0;
            result_value <= 0;
            result_valid <= 0;
            input_val <= 0;
            disp_index <= 0;
            for (i = 0; i < 16; i = i + 1)
                disp_str[i] <= " ";
        end else if (btn_valid) begin
            result_valid <= 0;

            // Clear
            if (btn_char == "C") begin
                state <= S_IDLE;
                total <= 0;
                temp_val <= 0;
                mult_val <= 0;
                prev_op <= 0;
                result_value <= 0;
                input_val <= 0;
                disp_index <= 0;
                for (i = 0; i < 16; i = i + 1)
                    disp_str[i] <= " ";
            end else begin
                // Update display
                if (disp_index < 16) begin
                    disp_str[disp_index] <= btn_char;
                    disp_index <= disp_index + 1;
                end

                case (state)
                    S_IDLE: begin
                        if (btn_char >= "0" && btn_char <= "9") begin
                            temp_val <= (temp_val * 10) + (btn_char - "0");
                            input_val <= (input_val * 10) + (btn_char - "0");
                        end else if (btn_char == "+" || btn_char == "-" || btn_char == "*") begin
                            total <= temp_val;
                            temp_val <= 0;
                            prev_op <= btn_char;
                            input_val <= 0;
                            state <= S_OPER;
                        end
                    end

                    S_OPER: begin
                        if (btn_char >= "0" && btn_char <= "9") begin
                            temp_val <= (temp_val * 10) + (btn_char - "0");
                            input_val <= (input_val * 10) + (btn_char - "0");
                        end else if (btn_char == "*") begin
                            if (prev_op == "*") begin
                                total <= total * temp_val;
                            end else begin
                                mult_val <= temp_val;
                                total <= total;
                            end
                            temp_val <= 0;
                            prev_op <= "*";
                        end else if (btn_char == "+" || btn_char == "-") begin
                            if (prev_op == "*") begin
                                total <= total * temp_val;
                            end else begin
                                case (prev_op)
                                    "+": total <= total + temp_val;
                                    "-": total <= total - temp_val;
                                endcase
                            end
                            temp_val <= 0;
                            prev_op <= btn_char;
                            input_val <= 0;
                        end else if (btn_char == "=") begin
                            case (prev_op)
                                "+": result_value <= total + temp_val;
                                "-": result_value <= total - temp_val;
                                "*": result_value <= total * temp_val;
                                default: result_value <= temp_val;
                            endcase
                            result_valid <= 1'b1;
                            total <= 0;
                            temp_val <= 0;
                            input_val <= 0;
                            state <= S_EQUAL;
                        end
                    end

                    S_EQUAL: begin
                        if (btn_char >= "0" && btn_char <= "9") begin
                            temp_val <= (btn_char - "0");
                            total <= 0;
                            prev_op <= 0;
                            input_val <= (btn_char - "0");
                            disp_index <= 1;
                            for (i = 0; i < 16; i = i + 1)
                                disp_str[i] <= " ";
                            disp_str[0] <= btn_char;
                            state <= S_IDLE;
                        end else if (btn_char == "+" || btn_char == "-" || btn_char == "*") begin
                            prev_op <= btn_char;
                            total <= result_value;
                            temp_val <= 0;
                            input_val <= 0;
                            state <= S_OPER;
                        end
                    end
                endcase
            end
        end
    end
endmodule

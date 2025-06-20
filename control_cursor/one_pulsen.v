module one_pulsen (
    input wire clk,
    input wire rst_n,
    input wire signal_in,
    output reg pulse_out
);
    reg signal_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_d <= 1'b0;
            pulse_out <= 1'b0;
        end else begin
            signal_d <= signal_in;
            pulse_out <= signal_in & ~signal_d;
        end
    end
endmodule

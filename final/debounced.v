module debouncen (
    input wire clk,
    input wire rst_n,
    input wire btn_in,
    output reg btn_out
);
    reg [19:0] cnt;
    reg btn_sync;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 20'd0;
            btn_sync <= 1'b1;
            btn_out <= 1'b1;
        end else begin
            if (btn_in == btn_sync)
                cnt <= 20'd0;
            else begin
                cnt <= cnt + 1;
                if (cnt > 20'd800_000) begin
                    btn_sync <= btn_in;
                    btn_out <= btn_in;
                end
            end
        end
    end
endmodule

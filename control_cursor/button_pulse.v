`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/09 15:54:29
// Design Name: 
// Module Name: button_pulse
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module button_pulse (
    input wire clk,
    input wire rst_n,
    input wire btn_raw,
    output reg btn_pulse
);
    reg btn_sync_0, btn_sync_1;
    reg btn_prev;

    // 2단 동기화
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_sync_0 <= 0;
            btn_sync_1 <= 0;
        end else begin
            btn_sync_0 <= btn_raw;
            btn_sync_1 <= btn_sync_0;
        end
    end

    // 상승 에지 검출
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_prev <= 0;
            btn_pulse <= 0;
        end else begin
            btn_pulse <= (btn_sync_1 && !btn_prev);
            btn_prev <= btn_sync_1;
        end
    end
endmodule

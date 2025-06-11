`timescale 1ns / 1ps

module lcd_pic_image (
    input wire clk_in,
    input wire sys_rst_n,
    input wire [10:0] pix_x,
    input wire [10:0] pix_y,
    output reg [23:0] pix_data
);

    parameter IMG_HEIGHT = 249;
    parameter IMG_WIDTH = 345;
    parameter ORIGIN_X = 100;
    parameter ORIGIN_Y = 60;

    wire [16:0] rom_addr;
    wire [23:0] rom_data;

    // ROM 인스턴스
    blk_mem_gen_0 u_rom (
        .clka(clk_in),
        .addra(rom_addr),
        .douta(rom_data)
    );

    reg valid_region;
    reg [16:0] read_addr;

    always @(*) begin
        if ((pix_x >= ORIGIN_X) && (pix_x < ORIGIN_X + IMG_WIDTH) &&
            (pix_y >= ORIGIN_Y) && (pix_y < ORIGIN_Y + IMG_HEIGHT)) begin
            valid_region = 1'b1;
            read_addr = (pix_y - ORIGIN_Y) * IMG_WIDTH + (pix_x - ORIGIN_X);
        end else begin
            valid_region = 1'b0;
            read_addr = 0;
        end
    end

    assign rom_addr = read_addr;

    always @(*) begin
        if (!sys_rst_n)
            pix_data = 24'h000000;
        else if (valid_region)
            pix_data = rom_data;
        else
            pix_data = 24'h0000000; // 배경색
    end
endmodule

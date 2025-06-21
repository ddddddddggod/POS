module lcd_pic_image (
    input wire clk_in,
    input wire sys_rst_n,
    input wire [3:0] sw,
    input wire [10:0] pix_x,
    input wire [10:0] pix_y,
    output reg [23:0] pix_data
);

    // Image 관련 파라미터
    parameter IMG_HEIGHT = 320;
    parameter IMG_WIDTH  = 560;
    parameter ORIGIN_X   = 120;
    parameter ORIGIN_Y   = 80;
    /// 560x320

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

    wire region_sw0 = sw[0] && (pix_x >= 120) && (pix_x < 260) && (pix_y >= 300) && (pix_y < 400);
    wire region_sw1 = sw[1] && (pix_x >= 260) && (pix_x < 400) && (pix_y >= 300) && (pix_y < 400);
    wire region_sw2 = sw[2] && (pix_x >= 400) && (pix_x < 540) && (pix_y >= 300) && (pix_y < 400);
    wire region_sw3 = sw[3] && (pix_x >= 540) && (pix_x < 680) && (pix_y >= 300) && (pix_y < 400);

    always @(*) begin
    if (!sys_rst_n)
        pix_data = 24'h000000; // 리셋 시 검은색
    else if ((pix_x >= 120) && (pix_x < 680) && (pix_y >= 300) && (pix_y < 400)) begin
        // 사각형 영역 내에서 스위치 상태에 따라 색 결정
        if (region_sw0 || region_sw1 || region_sw2 || region_sw3)
            pix_data = 24'hBEBEBE;  // 스위치 LOW
        else
            pix_data = 24'hFF0000;  // 스위치 HIGH
    end
    else if (valid_region)
        pix_data = rom_data; // 이미지 데이터
    else
        pix_data = 24'hFFFFFF; // 배경은 검은색
end

endmodule

timescale 1ns / 1ps

module lcd_top(
    input wire sys_clk,
    input wire sys_rst_n,
    output wire [23:0] rgb_lcd,
    output wire hsync,
    output wire vsync,
    output wire lcd_clk,
    output wire lcd_de,
    output wire lcd_ud,
    output wire lcd_bl
    );
    wire lcd_clk_33m;
    wire locked;
    wire rst_n;
    wire [9:0] pix_x;
    wire [9:0] pix_y;
    wire [23:0] pix_data;
    
    //rst_n
    assign rst_n = (sys_rst_n & locked);
    //lcd_ctrl
    assign lcd_ud = 1'b0;
    //Instnatiation
    clk_wiz_0 clk_wiz_0_inst(
                        .reset (~sys_rst_n),
                        .clk_in1 (sys_clk),
                        .clk_out1(lcd_clk_33m),
                        .locked (locked)
     );

     //tft_ctrl_inst
     lcd_ctrl lcd_ctrl_inst(
                        .clk_in (lcd_clk_33m),
                        .sys_rst_n (rst_n),
                        .data_in (pix_data),
                        
                        .data_req(),
                        .pix_x (pix_x),
                        .pix_y (pix_y),
                        .rgb_lcd_24b (rgb_lcd),
                        .hsync (hsync),
                        .vsync (vsync),
                        .lcd_clk (lcd_clk),
                        .lcd_de (lcd_de),
                        .lcd_bl(lcd_bl)
                      );
     //lcd_pic_inst
     lcd_pic lcd_pic_inst(
                        .clk_in (lcd_clk_33m),
                        .sys_rst_n (rst_n),
                        .pix_x (pix_x),
                        .pix_y (pix_y),
                        .pix_data (pix_data)
                        );
             
endmodule

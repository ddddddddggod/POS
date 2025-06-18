#-------------------------------
# System Clock & Reset
#-------------------------------
set_property -dict {PACKAGE_PIN Y9 IOSTANDARD LVCMOS33} [get_ports sys_clk]
set_property -dict {PACKAGE_PIN F22 IOSTANDARD LVCMOS33} [get_ports sys_rst_n]

#-------------------------------
# LCD Control Signals
#-------------------------------
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33} [get_ports hsync]
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33} [get_ports vsync]
set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports lcd_clk]
set_property -dict {PACKAGE_PIN N20 IOSTANDARD LVCMOS33} [get_ports lcd_bl]
set_property -dict {PACKAGE_PIN B21 IOSTANDARD LVCMOS33} [get_ports lcd_ud]
set_property -dict {PACKAGE_PIN D15 IOSTANDARD LVCMOS33} [get_ports lcd_de]

#-------------------------------
# LCD RGB888 Output (24bit)
#-------------------------------
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[23]}]
set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[22]}]
set_property -dict {PACKAGE_PIN C18 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[21]}]
set_property -dict {PACKAGE_PIN A16 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[20]}]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[19]}]
set_property -dict {PACKAGE_PIN A17 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[18]}]
set_property -dict {PACKAGE_PIN B16 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[17]}]
set_property -dict {PACKAGE_PIN B17 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[16]}]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[15]}]
set_property -dict {PACKAGE_PIN F19 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[14]}]
set_property -dict {PACKAGE_PIN E20 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[13]}]
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[12]}]
set_property -dict {PACKAGE_PIN D22 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[11]}]
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[10]}]
set_property -dict {PACKAGE_PIN C22 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[9]}]
set_property -dict {PACKAGE_PIN A19 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[8]}]
set_property -dict {PACKAGE_PIN E21 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[7]}]
set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[6]}]
set_property -dict {PACKAGE_PIN G21 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[5]}]
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[4]}]
set_property -dict {PACKAGE_PIN D21 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[3]}]
set_property -dict {PACKAGE_PIN G16 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[2]}]
set_property -dict {PACKAGE_PIN G19 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[1]}]
set_property -dict {PACKAGE_PIN F18 IOSTANDARD LVCMOS33} [get_ports {rgb_lcd[0]}]

#-------------------------------
# pin mapping
#-------------------------------
set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS33} [get_ports btn_up]
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports btn_down]
set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports btn_left]
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33} [get_ports btn_right]
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports btn_center]
#-------------------------------
# using dip sw
#-------------------------------
set_property -dict {PACKAGE_PIN G22 IOSTANDARD LVCMOS33}  [get_ports {dip_sw[0]}]
set_property -dict {PACKAGE_PIN H22 IOSTANDARD LVCMOS33}  [get_ports {dip_sw[2]}]
set_property -dict {PACKAGE_PIN F21 IOSTANDARD LVCMOS33}  [get_ports {dip_sw[3]}]
set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS33}  [get_ports {dip_sw[4]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS33}  [get_ports {dip_sw[5]}]
#-------------------------------
#led
#-------------------------------
set_property -dict {PACKAGE_PIN T22 IOSTANDARD LVCMOS33}  [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN T21 IOSTANDARD LVCMOS33}  [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN U22 IOSTANDARD LVCMOS33}  [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN U21 IOSTANDARD LVCMOS33}  [get_ports {led[3]}]

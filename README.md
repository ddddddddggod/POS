# <POS기>
2025 digital system FPGA project

## 사용 FPGA
- Libertron사의 EMA-MOD-7V2000T-2-2 모듈 (Xilinx Virtex-7 시리즈 FPGA (XC7V2000T-2FLG1925C)탑재)
- FSM LCD 모듈
  
## 메뉴판 선택
- LCD : 메뉴판 그림 출력
- Switch : 딥 스위치를 이용한 메뉴 선택
- LED : 선택된 메뉴 LED 표시
- 
## 계산기 (최대 출력 결과값 : 16777215)

### Mode 1 (직접 계산)
- UI (block, 숫자, 연산자, input, output)
- cursor (push button을 이용해 출력 선택)

### Mode 2 (자동 계산)
- LCD : 메뉴판에서 선택된 메뉴 자동 덧셈

## Final Sources
### Deisgn Sources
- lcd_top >> top module
- lcd_ctrl >> lcd display
- lcd_pic >> 계산기 UI
- lcd_pic_image >> 메뉴 이미지
- calc_fsm >> 계산기 기능
- font_rom >> 계산기 폰트
- cursor_ctrl >> 계산기 커서 제어
- one_pulse, debouncedn >> 계산기 버튼 noise 제거

### Block Sources (vivado 내장 모듈 사용)
- blk_mem_gen_0 >> 메뉴 이미지 (.coe파일)
- clk_wiz_0 >> clock

### Constraints
- lcd.xdc >> FPGA pin 연결

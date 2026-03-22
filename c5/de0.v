module de0
(
      // Reset
      input              RESET_N,

      // Clocks
      input              CLOCK_50,
      input              CLOCK2_50,
      input              CLOCK3_50,
      inout              CLOCK4_50,

      // DRAM
      output             DRAM_CKE,
      output             DRAM_CLK,
      output      [1:0]  DRAM_BA,
      output      [12:0] DRAM_ADDR,
      inout       [15:0] DRAM_DQ,
      output             DRAM_CAS_N,
      output             DRAM_RAS_N,
      output             DRAM_WE_N,
      output             DRAM_CS_N,
      output             DRAM_LDQM,
      output             DRAM_UDQM,

      // GPIO
      inout       [35:0] GPIO_0,
      inout       [35:0] GPIO_1,

      // 7-Segment LED
      output      [6:0]  HEX0,
      output      [6:0]  HEX1,
      output      [6:0]  HEX2,
      output      [6:0]  HEX3,
      output      [6:0]  HEX4,
      output      [6:0]  HEX5,

      // Keys
      input       [3:0]  KEY,

      // LED
      output      [9:0]  LEDR,

      // PS/2
      inout              PS2_CLK,
      inout              PS2_DAT,
      inout              PS2_CLK2,
      inout              PS2_DAT2,

      // SD-Card
      output             SD_CLK,
      inout              SD_CMD,
      inout       [3:0]  SD_DATA,

      // Switch
      input       [9:0]  SW,

      // VGA
      output      [3:0]  VGA_R,
      output      [3:0]  VGA_G,
      output      [3:0]  VGA_B,
      output             VGA_HS,
      output             VGA_VS
);

// High-Impendance-State
assign DRAM_DQ = 16'hzzzz;
assign GPIO_0  = 36'hzzzzzzzz;
assign GPIO_1  = 36'hzzzzzzzz;
assign SD_DATA[0] = 1'bZ;
assign {HEX0,HEX1,HEX2,HEX3,HEX4,HEX5} = ~48'h0;

// Провода
// ---------------------------------------------------------------------
wire        c25, c100, reset_n;

// Генератор частоты
// -----------------------------------------------------------------------------
pll u0
(
    .clkin      (CLOCK_50),
    .locked     (reset_n),
    .m25        (c25),
    .m100       (c100)
);

// -----------------------------------------------------------------------------
// Ядрёный Процессор
// -----------------------------------------------------------------------------

wire [31:0] a; // Адресок дайте?
wire [ 3:0] b; // Маска
wire [31:0] d; // Данные на запись
wire [31:0] q; // На чтение
wire        w; // Сигнал записи

core C1
(
    .clock      (c25),
    .rst_n      (reset_n),
    .ce         (1'b1),
    .a          (a),
    .b          (b),
    .i          (i),
    .o          (d),
    .w          (w)
);

// Блоки памяти
// -----------------------------------------------------------------------------
// 00000    128K    Общая память
// 20000    128K    640x400, 16 цветов
// -----------------------------------------------------------------------------

// Допустимость записи в память
wire w256 = a < 32'h40000;

// Роутер памяти
wire [31:0] i =
    w256 ? q :
    a[31:4] == 28'hC000002 ? x   : // MouseX
    a[31:4] == 28'hC000003 ? y   : // MouseY
    a[31:4] == 28'hC000004 ? btn : // Button
    32'b0;

// FMax ~ 43 Mhz при таком подходе с негативным спадом clock-100
m256 M1(.c(~c100), .a(a[17:2]), .b(b), .d(d), .q(q), .w(w & w256), .ax(va), .qx(vq));

// Видеоадаптер
// -----------------------------------------------------------------------------
wire [15:0] va;
wire [31:0] vq;

vga32 D1
(
    .clock  (c25),
    .hs     (VGA_HS),
    .vs     (VGA_VS),
    .rgb    ({VGA_R,VGA_G,VGA_B}),
    .a      (va),
    .i      (vq),
);

// Контроллер мыши
// -----------------------------------------------------------------------------

wire        ms_cmd;
wire [7:0]  ms_dat;
wire [7:0]  ms_kbd;
wire        ms_hit, ms_err, ms_ready;

// Результаты чтения информации о мыши
wire [11:0] x, y;
wire [ 2:0] btn;
wire        recv;

kb K1A
(
    .clock  (c25),   // 25 Mhz
    .reset_n(reset_n),    // =0 Сброс
    .ps_clk (PS2_CLK2),   // PS/2 Clock
    .ps_dat (PS2_DAT2),   // PS/2 Data
    .cmd    (ms_cmd),     // =1 Сигнал на отсылку команды
    .dat    (ms_dat),     // Код команды или данных
    .kbd    (ms_kbd),     // Принятые данные от мыши
    .hit    (ms_hit),     // =1 Данные приняты (только 1 такт)
    .err    (ms_err),     // =1 Есть ошибка приема/передачи
    .ready  (ms_ready)    // =1 Готовность к приему команд
);

mouse K1B
(
    .clock   (c25),
    .reset_n (reset_n),
    .xmax    (640),
    .ymax    (480),
    .x       (x),
    .y       (y),
    .ps_clk  (PS2_CLK2),
    .cmd     (ms_cmd),
    .dat     (ms_dat),
    .ready   (ms_ready),
    .hit     (ms_hit),
    .kbd     (ms_kbd),
    .btn     (btn),
    .recv    (recv)
);

endmodule

`include "../core.v"
`include "../vga32.v"
`include "../kb.v"
`include "../mouse.v"


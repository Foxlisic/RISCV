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
//    .clock      (c25),
    .rst_n      (reset_n),
    .ce         (1'b1),
    .a          (a),
    .b          (b),
    .i          (q),
    .o          (d),
    .w          (w)
);

// -----------------------------------------------------------------------------
// 00000    131K    Общая память
// 20C00    125K    640x400, 16 цветов
// -----------------------------------------------------------------------------

m256 M1(.c(~c25), .a(a[17:2]), .b(b), .d(d), .q(q), .w(w), .ax(va), .qx(vq));

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


endmodule

`include "../core.v"
`include "../vga32.v"


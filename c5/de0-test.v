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

// Активировано, 50% duty
ledpanel(CLOCK_50, 1'b1, 16'h0200, out, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5);

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

// Эксперименты с памятью
m256 M1( .c(~c25), .a(a), .b(b), .d(d), .q(q), .w(w) );
// ----

reg [ 3:0]  t;
reg [15:0]  a;
reg [ 3:0]  b;
reg [31:0]  d;
reg         w;
wire [31:0] q;
// ---
reg [23:0]  out;

always @(posedge c25)
if (reset_n) begin

    case (t)
    0: begin t <= 1; w <= 1; d <= 32'hCAFEBABE; b <= 4'b0000; a <= 16'hDEDA; end
    1: begin t <= 2; w <= 0; end
    2: begin t <= 3; w <= 1; d <= 32'h11223344; b <= 4'b1100; end
    3: begin t <= 4; w <= 0; out <= q; end
    endcase

end

endmodule


module ledpanel
(
    // ------------------------------
    input  wire        clock50,     // Тактовая частота
    input  wire        ena,         // Активация устройства
    input  wire [15:0] duty,        // Яркость от 0 до 65535
    input  wire [23:0] hexcode,     // Входные данные
    // ------------------------------
    output wire [6:0]  hex0,
    output wire [6:0]  hex1,
    output wire [6:0]  hex2,
    output wire [6:0]  hex3,
    output wire [6:0]  hex4,
    output wire [6:0]  hex5
);

// Выдача изображения
assign hex5 = get_led_state(hexcode[23:20], pwm & ena & hl[5]);
assign hex4 = get_led_state(hexcode[19:16], pwm & ena & hl[4]);
assign hex3 = get_led_state(hexcode[15:12], pwm & ena & hl[3]);
assign hex2 = get_led_state(hexcode[ 11:8], pwm & ena & hl[2]);
assign hex1 = get_led_state(hexcode[  7:4], pwm & ena & hl[1]);
assign hex0 = get_led_state(hexcode[  3:0], pwm & ena & hl[0]);

reg [ 5:0] hl;
reg [15:0] counter;
reg        pwm;

// ~ 750 Hz
always @(posedge clock50) begin

    counter <= counter + 1;
    pwm     <= counter < duty;

    casex (hexcode)

        24'h00000x: hl <= 6'b000001;
        24'h0000xx: hl <= 6'b000011;
        24'h000xxx: hl <= 6'b000111;
        24'h00xxxx: hl <= 6'b001111;
        24'h0xxxxx: hl <= 6'b011111;
        default:    hl <= 6'b111111;

    endcase

end

// Функция получения Led State
function [6:0] get_led_state;
input [3:0] hc;
input enpin;
begin

    if (enpin)
    case (hc)

        4'h0: get_led_state = 7'b1000000;
        4'h1: get_led_state = 7'b1111001;
        4'h2: get_led_state = 7'b0100100;
        4'h3: get_led_state = 7'b0110000;
        4'h4: get_led_state = 7'b0011001;
        4'h5: get_led_state = 7'b0010010;
        4'h6: get_led_state = 7'b0000010;
        4'h7: get_led_state = 7'b1111000;
        4'h8: get_led_state = 7'b0000000;
        4'h9: get_led_state = 7'b0010000;
        4'hA: get_led_state = 7'b0001000;
        4'hB: get_led_state = 7'b0000011;
        4'hC: get_led_state = 7'b1000110;
        4'hD: get_led_state = 7'b0100001;
        4'hE: get_led_state = 7'b0000110;
        4'hF: get_led_state = 7'b0001110;

	endcase
    else get_led_state = 7'b1111111;

end
endfunction

endmodule

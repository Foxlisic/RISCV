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

// LED OFF
assign HEX0 = 7'b1111111;
assign HEX1 = 7'b1111111;
assign HEX2 = 7'b1111111;
assign HEX3 = 7'b1111111;
assign HEX4 = 7'b1111111;
assign HEX5 = 7'b1111111;

assign SD_DATA[0] = 1'bZ;

// Провода
// ---------------------------------------------------------------------
wire        clock_25, clock_100, reset_n;

// Генератор частоты
// -----------------------------------------------------------------------------
pll u0
(
    .clkin      (CLOCK_50),
    .locked     (reset_n),
    .m25        (clock_25),
    .m100       (clock_100)
);
// -----------------------------------------------------------------------------
wire   [3:0]    key = KEY;
wire            clock = clock_100;
// -----------------------------------------------------------------------------

`define CP3 cp[2:0]

// @TODO assign dp   = beep & divclk[16];
assign LEDR = disp ^ (phi == 4'h2 && divclk[23] ? (1 << `CP3) : 0);

// =============================================================================
// MNODULE
// =============================================================================

reg [23:0]  divclk; // ~95.3 Hz
reg [ 2:0]  phi;
reg [ 7:0]  cp;
reg [ 7:0]  disp;
reg         beep;
// -----------------------------------------------------------------------------
always @(posedge clock) divclk <= divclk + 1;
// -----------------------------------------------------------------------------

always @(posedge divclk[19])
begin

    case (phi)

    // IDLE: Ждать пока на кнопку нажмется
    0: phi <= &key ? 0 : 1;

    // ENTER DATA
    1: begin beep <= 0; phi <= &key ? 2 : 1; end
    2: if      (!key[0]) begin phi <= 1; `CP3 <= `CP3 + 1; disp[`CP3] <= 1'b0; end
       else if (!key[1]) begin phi <= 1; `CP3 <= `CP3 + 1; disp[`CP3] <= 1'b1; end
       else if (!key[2]) begin phi <= 1; `CP3 <= `CP3 - 1; end
       else if (!key[3]) begin phi <= 3; end

    // DOWNTIMER
    3: begin

        if (&cp) begin

            disp <= disp - 1;
            if (disp == 1) begin beep <= 1; phi <= 0; end

        end

        cp <= cp + 1;

    end

    endcase

end

endmodule

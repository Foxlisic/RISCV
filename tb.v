`timescale 10ns / 1ns
module tb;
// ---------------------------------------------------
reg clock_25 = 0, clock_100 = 1, rst_n = 0;
// ---------------------------------------------------
always #0.5 clock_100 = ~clock_100;
always #2.0 clock_25  = ~clock_25;
// ---------------------------------------------------
reg  [ 7:0] M[1024]; // 1024
// ---------------------------------------------------
initial begin #4.0 rst_n = 1; #200 $finish; end
initial begin $dumpfile("tb.vcd"); $dumpvars(0, tb); end
initial begin $readmemh("tb.hex", M, 1'b0); end
// ---------------------------------------------------
wire [31:0] A;  // Адрес (Address)
wire [31:0] I = {M[A+3], M[A+2], M[A+1], M[A]};
wire [31:0] O;  // Данные в память (Out)
wire        W;  // Сигнал записи (Write)
wire [ 1:0] WS; // Сколько записывать
// ---------------------------------------------------
always @(posedge clock_100)
begin

    // Запись в память 1,2,4 байта
    if (W)
    case (WS)
    2'b00: {M[A]} <= O[7:0];
    2'b01: {M[A+1], M[A]} <= O[15:0];
    2'b10: {M[A+3], M[A+2], M[A+1], M[A]} <= O;
    endcase

end
// ---------------------------------------------------
core C1
(
    .clock      (clock_25),
    .rst_n      (rst_n),
    .ce         (1'b1),
    .a          (A),
    .i          (I),
    .o          (O),
    .w          (W),
    .ws         (WS)
);
endmodule

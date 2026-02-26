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
wire [31:0] a;  // Адрес (Address)
wire [31:0] o;  // Данные в память (Out)
wire        w;  // Сигнал записи (Write)
wire [ 1:0] ws; // Сколько записывать
wire [31:0] i = {M[a+3], M[a+2], M[a+1], M[a]};
// ---------------------------------------------------
always @(negedge clock_100)
begin

    // Запись в память 1,2,4 байта
    if (w)
    case (ws)
    2'b00: {M[a]} <= o[7:0];
    2'b01: {M[a+1], M[a]} <= o[15:0];
    2'b10: {M[a+3], M[a+2], M[a+1], M[a]} <= o;
    endcase

end
// ---------------------------------------------------
core C1
(
    .clock      (clock_25),
    .rst_n      (rst_n),
    .ce         (1'b1),
    .a          (a),
    .i          (i),
    .o          (o),
    .w          (w),
    .ws         (ws)
);
endmodule

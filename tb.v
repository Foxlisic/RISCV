`timescale 10ns / 1ns
module tb;
// ---------------------------------------------------
reg clock_25 = 0, clock_100 = 1, rst_n = 0;
// ---------------------------------------------------
always #0.5 clock_100 = ~clock_100;
always #2.0 clock_25  = ~clock_25;
// ---------------------------------------------------
reg  [31:0] M[1024]; // 4 x 1024 = 4kb
// ---------------------------------------------------
initial begin #4.0 rst_n = 1; #200 $finish; end
initial begin $dumpfile("tb.vcd"); $dumpvars(0, tb); end
initial begin $readmemh("tb.hex", M, 1'b0); end
// ---------------------------------------------------
wire [31:0] A; // Адрес (Address)
reg  [31:0] I; // Данные из памяти (In)
wire [31:0] O; // Данные в память (Out)
wire        W; // Сигнал записи (Write)
// ---------------------------------------------------
always @(posedge clock_100) begin I <= M[A[11:2]]; if (W) M[A[11:2]] <= O; end
// ---------------------------------------------------
core C1
(
    .clock      (clock_25),
    .rst_n      (rst_n),
    .ce         (1'b1),
    .a          (A),
    .i          (I),
    .o          (O),
    .w          (W)
);
endmodule

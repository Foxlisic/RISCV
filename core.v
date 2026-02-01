module core
(
    input               clock,
    input               rst_n,
    input               ce,
    // Интерфейс ввода-вывода
    output      [31:0]  a,
    input       [31:0]  i,
    output      [31:0]  o,
    output reg          w
);

assign a = pc;
// -----------------------------------------------------------------------------
reg         cp;         // =0 PC; =1 MR
reg [ 1:0]  t;          // Указатель фазы выполнения
reg [31:0]  pc;         // Программный счетчик
reg [31:0]  mr;         // Указатель в памяти
reg [31:0]  r[32];      // 32bit x 32 регистра
// -----------------------------------------------------------------------------
always @(posedge clock)
if (rst_n == 1'b0) begin

    pc <= 0;
    mr <= 0;
    w  <= 0;

end else if (ce) begin

    w  <= 0;

end

endmodule

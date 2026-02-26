module core
(
    input               clock,
    input               rst_n,
    input               ce,
    // Интерфейс ввода-вывода
    output      [31:0]  a,
    input       [31:0]  i,
    output reg  [31:0]  o,
    output reg  [ 1:0]  ws,     // 0=1b, 1=2b, 3=4b
    output reg          w
);

assign a = m ? cp : pc;
// -----------------------------------------------------------------------------
localparam RUN = 0;
localparam ADD = 0, SLL = 1, SLT = 2, SLTU = 3, XOR = 4, SRL = 5, OR = 6, AND = 7;
// -----------------------------------------------------------------------------
reg         m;          // =0 PC; =1 MR
reg [ 1:0]  s;          // Указатель фазы
reg [31:0]  opcache;    // Сохранение опкода для 2T+ инструкции
reg [31:0]  pc, cp;     // Программный счетчик или указатель на память
reg [31:0]  r[32];      // 32bit x 32 регистра
// -----------------------------------------------------------------------------
reg         rw;         // Когда пишем
reg [ 4:0]  rn;         // Защелнуть Rd
reg [31:0]  x;          // И что именно в регистр Rd
// -----------------------------------------------------------------------------
wire [31:0] instr   = (s ? opcache : i);
wire [ 6:0] fn7     = instr[31:25];
wire [ 4:0] rs1     = instr[19:15];
wire [ 4:0] rs2     = instr[24:20];
wire [ 2:0] fn3     = instr[14:12];
wire [ 4:0] rd      = instr[11:7];
wire [ 6:0] opcode  = instr[ 6:0];
// ---
wire [19:0] imm20   = instr[31:12];
wire [31:0] immis   = {{20{instr[31]}}, instr[31:20]};
wire [31:0] immj    = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
wire [19:0] imms    = {{20{instr[31]}}, instr[31:25], instr[11:7]};
wire [31:0] immb    = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0} + pc;
// ---
wire [31:0] r1      = rs1 ? r[rs1] : 32'b0;
wire [31:0] r2      = rs2 ? r[rs2] : 32'b0;
// -----------------------------------------------------------------------------
wire [31:0] ptr     = r1 + immis;
wire [31:0] pc4     = pc + 4;
// -----------------------------------------------------------------------------
// Выбор второго операнда (I/R) в зависимости от опкода
wire [31:0] op2     = (opcode == 7'h13) ? immis : r2;

// Общий случай для сравнения, проверки знаков и вычитания
wire [32:0] sub     = r1 - op2;

// Получение 1 если r1 < op2 со знаком (OF != SF)
wire        slt     = ((r1[31] ^ op2[31]) & (r1[31] ^ sub[31])) ^ sub[31]; 

// Знаковое расширение для SRA
// Количество сдвигов разное для I/R-операнде
wire [63:0] r1s     = {fn7 ? {32{r1[31]}} : 32'b0, r1};
wire [ 4:0] sha     = (opcode == 7'h13) ? rs2 : r2[4:0];

// Для R-АЛУ операции выбирается SUB если FN7 не равен 0, иначе везде ADD
wire [31:0] addsub  = (opcode == 7'h33 && fn7) ? sub[31:0] : r1 + op2;
// -----------------------------------------------------------------------------
wire [31:0] alu =
    fn3 == ADD  ? addsub     : // 0 ADDI или ADD, SUB
    fn3 == SLL  ? r1 << sha  : // 1 SLL
    fn3 == SLT  ? slt        : // 2 SLT
    fn3 == SLTU ? sub[32]    : // 3 SLTU
    fn3 == XOR  ? r1 ^ op2   : // 4 XOR
    fn3 == SRL  ? r1s >> sha : // 5 SRL, SRA
    fn3 == OR   ? r1 | op2   : // 6 OR
                  r1 & op2;    // 7 AND
// -----------------------------------------------------------------------------
always @(posedge clock)
if (rst_n == 1'b0) begin

    pc <= 0;
    cp <= 0;
    w  <= 0;
    o  <= 0;
    rw <= 0;
    ws <= 0;
    m  <= 0;
    s  <= 0;

end else if (ce) begin

    rw <= 0;
    rn <= rd;

    // На первом такте переход к следующей инструкции
    if (s == 0) begin

        opcache <= i;
        pc      <= pc4;

    end

    // Исполнение инструкции
    case (opcode)

    // (LUI|AUIPC) Rd, Imm20
    7'h37: begin rw <= 1; x <= {imm20, 12'h000}; end
    7'h17: begin rw <= 1; x <= {imm20, 12'h000} + pc; end

    // JAL Rd, ImmJ
    // JALR Rd, Rs1, ImmS
    7'h6F: begin rw <= 1; x <= pc4; pc <= pc + immj; end
    7'h67: begin rw <= 1; x <= pc4; pc <= {ptr[31:1], 1'b0}; end

    // [2T] LOAD Rd,Rs1,ImmI
    7'h03: case (s)

        0: begin s <= 1; m <= 1; cp <= ptr; end
        1: begin s <= 0; m <= 0; rw <= 1;

            case (fn3)
            0: x <= {{24{i[7]}},  i[ 7:0]}; // LB
            1: x <= {{16{i[15]}}, i[15:0]}; // LH
            2: x <= i;        // LW
            4: x <= i[ 7:0];  // LBU
            5: x <= i[15:0];  // LHU
            endcase

        end

    endcase

    // [2T] STORE Rd,Rs1,ImmI
    7'h23: case (s)

        0: begin s <= 1; m <= 1; w <= 1; o <= r2; ws <= fn3[1:0]; cp <= imms; end
        1: begin s <= 0; m <= 0; w <= 0; end

    endcase

    // Branch
    7'h63: case (fn3)

        0: if (sub == 0) pc <= immb; // BEQ
        1: if (sub != 0) pc <= immb; // BNE
        4: if (slt == 1) pc <= immb; // BLT
        5: if (slt == 0) pc <= immb; // BGE
        6: if (sub[32])  pc <= immb; // BLTU
        7: if (!sub[32]) pc <= immb; // BGEU

    endcase

    // [ALU] Immediate | Register
    7'h13,
    7'h33: begin rw <= 1; x <= alu; end
    
    endcase

end

// -----------------------------------------------------------------------------
always @(negedge clock) if (rw) r[rn] <= x;

endmodule

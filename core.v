module core
(
    input               clock,
    input               rst_n,
    input               ce,
    // Интерфейс ввода-вывода
    output reg  [31:0]  a,
    input       [31:0]  i,
    output reg  [31:0]  o,
    output reg  [ 1:0]  s,      // 0=1b, 1=2b, 3=4b
    output reg          w
);

// -----------------------------------------------------------------------------
localparam ADD = 0, SLL = 1, SLT = 2, SLTU = 3, XOR = 4, SRL = 5, OR = 6, AND = 7;
// -----------------------------------------------------------------------------
reg         m, wn;      // Выбор источника памяти
reg  [31:0] pc;         // Программный счетчик или указатель на память
reg  [31:0] pcn, cpn;   // Следующий адрес в памяти
reg  [31:0] on;         // Следующий out_data
reg  [31:0] r[32];      // 32bit x 32 регистра
reg  [ 1:0] t, tn;      // Стадия исполнения
reg  [ 1:0] sn;         // Размер для записи
reg         rw;         // =1 Писать в регистр Rd
reg  [31:0] x;          // Что именно писать в Rd
reg  [31:0] opcache;    // Сохранить кеш инструкции
// -----------------------------------------------------------------------------
wire [31:0] instr   = (t ? opcache : i);
wire [ 6:0] fn7     = instr[31:25];
wire [ 4:0] rs1     = instr[19:15];
wire [ 4:0] rs2     = instr[24:20];
wire [ 2:0] fn3     = instr[14:12];
wire [ 4:0] rd      = instr[11:7];
wire [ 6:0] opcode  = instr[ 6:0];
// ---
wire [19:0] imm20   = instr[31:12];
wire [31:0] immu    = {imm20, 12'h000};
wire [31:0] immi    = {{20{instr[31]}}, instr[31:20]};
wire [31:0] imms    = {{20{instr[31]}}, instr[31:25], instr[11:7]};
wire [31:0] immj    = pc + {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
wire [31:0] immb    = pc + {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
// ---
wire [31:0] r1      = rs1 ? r[rs1] : 32'b0;
wire [31:0] r2      = rs2 ? r[rs2] : 32'b0;
wire [31:0] ap      = r1 + imms;            // Адрес Load/Store
wire [31:0] jp      = r1 + immi;            // JALR
wire [31:0] pc4     = pc + 4;
// ---
wire        is13    = opcode == 7'h13;      // АЛУ с immediate
wire        is33    = opcode == 7'h33;      // АЛУ с регистрами
wire        fn75    = fn7[5];               // Переключение режима SUB/SRA
// -----------------------------------------------------------------------------
wire [31:0] op2     = is13 ? immi : r2;
wire [ 4:0] sha     = is13 ? rs2  : r2;
wire [32:0] sub     = r1 - op2;
wire        slt     = ((r1[31] ^ op2[31]) & (r1[31] ^ sub[31])) ^ sub[31];
wire [63:0] srl     = {{32{r1[31] & fn75}}, r1};
reg  [31:0] res;
// -----------------------------------------------------------------------------
always @(*) begin

    case (fn3)
    ADD:     res = (is33 && fn75) ? sub[31:0] : r1 + op2;
    SLL:     res = r1 << sha;
    SLT:     res = slt;
    SLTU:    res = sub[32];
    XOR:     res = r1 ^ op2;
    SRL:     res = srl >> sha;
    OR:      res = r1 | op2;
    AND:     res = r1 & op2;
    default: res = 32'b0;
    endcase

end
// -----------------------------------------------------------------------------

always @(*) begin

    m   = 1'b0;
    wn  = 1'b0;
    on  = 1'b0;
    tn  = 1'b0;
    sn  = 1'b0;
    rw  = 1'b0;
    pcn = pc4;
    cpn = ap;

    case (opcode)

    // LOAD Rd,Rs1,ImmI [2T]
    7'h03: case (t)

        0: begin m = 1; tn = 1; cpn = jp; end
        1: begin

            rw = 1;

            case (fn3)
            0: x = {{24{i[7]}},  i[ 7:0]}; // LB
            1: x = {{16{i[15]}}, i[15:0]}; // LH
            2: x = i;        // LW
            4: x = i[ 7:0];  // LBU
            5: x = i[15:0];  // LHU
            endcase

        end

    endcase

    // АЛУ с Immediate операндом
    7'h13: begin rw = 1; x = res; end

    // AUIPC Rd, Imm20
    7'h17: begin rw = 1; x = immu + pc; end

    // STORE Rd,Rs1,ImmI [2T]
    7'h23: case (t)

        0: begin {m, wn} = 2'b11; tn = 1; on = r2; sn = fn3[1:0]; end

    endcase

    // АЛУ с регистрами или умножение и деление
    7'h33: begin rw = 1; x = res; end

    // LUI Rd, Imm20
    7'h37: begin rw = 1; x = immu; end

    // Условный переход
    7'h63: case (fn3)

        0: if (sub == 0) pcn = immb; // BEQ
        1: if (sub != 0) pcn = immb; // BNE
        4: if (slt == 1) pcn = immb; // BLT
        5: if (slt == 0) pcn = immb; // BGE
        6: if (sub[32])  pcn = immb; // BLTU
        7: if (!sub[32]) pcn = immb; // BGEU

    endcase

    // JALR Rd, Rs1, ImmS
    7'h67: begin rw = 1; x = pc4; pcn = {jp[31:1], 1'b0}; end

    // JAL Rd, ImmJ
    7'h6F: begin rw = 1; x = pc4; pcn = immj; end

    endcase

end
// -----------------------------------------------------------------------------
always @(posedge clock)
if (rst_n == 1'b0) begin

    a  <= 0;    // Старт с 0x00000000
    s  <= 0;
    o  <= 0;
    w  <= 0;
    pc <= 0;
    t  <= 0;

end else if (ce) begin

    t  <= tn;               // Счетчик фазы
    pc <= pcn;              // Следующий PC
    a  <= m ? cpn : pcn;    // Новый PC или указатель
    w  <= wn;
    o  <= on;
    s  <= sn;

    if (!t) opcache <= instr;
    if (rw) r[rd] <= x;

end

endmodule

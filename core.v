module core
(
    input               clock,
    input               rst_n,
    input               ce,
    // Интерфейс ввода-вывода
    output reg  [31:0]  a,
    input       [31:0]  i,
    output reg  [31:0]  o,
    output reg  [ 3:0]  b,
    output reg          w,
    output reg          read
);
// -----------------------------------------------------------------------------
localparam ADD = 0, SLL = 1, SLT = 2, SLTU = 3, XOR = 4, SRL = 5, OR = 6, AND = 7;
// -----------------------------------------------------------------------------
reg  [31:0] r[32];          // 32bit x 32 регистра
reg         m;              // Выбор источника памяти
reg         wn, rn;         // =1 Установка записи/чтения в память
reg         rw;             // =1 Писать в регистр Rd
reg  [31:0] on;             // Данные для записи в память
reg  [ 3:0] bn;             // Маска для записи STORE
reg  [ 1:0] t, tn;          // Стадия исполнения
reg  [31:0] pc, pcn, cpn;   // Программный счетчик или указатель на память
reg  [31:0] opcache;        // Сохраненный опкод
reg  [31:0] x, y;           // Что именно писать в Rd
reg  [63:0] q;              // Делимое, остаток и результат
reg  [31:0] d;              // Делитель
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
wire [31:0] jp      = r1 + immi;            // LOAD, JALR
wire [31:0] ap      = r1 + imms;            // STORE
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
wire [63:0] s1      = {{32{r1[31]}}, r1}; // SIGN(r1)
wire [63:0] s2      = {{32{r2[31]}}, r2}; // SIGN(r2)
wire [63:0] mul     = (fn3==1 || fn3==2 ? s1 : r1) * (fn3 == 2 ? s2 : r2);
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
    rn  = 1'b0;
    tn  = 1'b0;
    rw  = 1'b0;
    cpn = 1'b0;
    pcn = t ? pc : pc4;

    // Подготовка записи в память (cpn/on), регистр (x) или чтения из памяти (y)
    on  = r2 << {ap[1:0], 3'b000};
    y   = i  >> {jp[1:0], 3'b000};
    x   = 1'b0;

    case (fn3[1:0])
    2'b00: begin bn = ~(4'b0001 << ap[1:0]); end
    2'b01: begin bn = ~(4'b0011 << ap[1:0]); end
    2'b10: begin bn = ~(4'b1111 << ap[1:0]); end
    2'b11: begin bn = 4'b0000; end
    endcase

    // Декодер инструкции
    case (opcode)

    // LOAD Rd,Rs1,ImmI [2T]
    7'h03: case (t)

        0: begin tn = 1; m = 1; cpn = jp; rn = 1; end
        1: begin

            // 1) +0 WORD Выровненное чтение по границам 32х битного слова: WORD
            // 2) +0,+1,+2 смещение действует для всех HALF
            // 3) +0,+1,+2,+3 BYTE
            // Иначе: +3 для HALF или любой +1,+2,+3 для WORD действует частично
            if (jp[1:0] == 2'b00 || fn3[1:0] /* BYTE */ == 2'b00 || (jp[1:0] != 2'b11 && fn3[1:0] == /*HALF*/ 2'b01)) begin

                rw = 1;

                case (fn3)
                3'b000: x = {{24{y[7]}},  y[ 7:0]}; // LB
                3'b001: x = {{16{y[15]}}, y[15:0]}; // LH
                3'b010: x = y;                      // LW
                3'b100: x = y[ 7:0];                // LBU
                3'b101: x = y[15:0];                // LHU
                endcase

            end else
            // Выборка памяти, к следующему WORD и сохранить часть слова
            begin tn = 2; m = 1; cpn = jp + 4; on = y; rn = 1; end

        end

        // Запись в регистр HALF или части слов DWORD
        2: begin

            rw = 1;

            casex (fn3)
            // LH или LHU
            3'bx01: x = {{16{~fn3[2] & i[7]}}, i[7:0], o[7:0]};
            // LW
            3'b010: case (jp[1:0])
                2'b01: x = {i[7:0],  o[23:0]};
                2'b10: x = {i[15:0], o[15:0]};
                2'b11: x = {i[23:0], o[7:0]};
            endcase
            endcase

        end

    endcase

    // АЛУ с Immediate операндом
    7'h13: begin rw = 1; x = res; end

    // AUIPC Rd, Imm20
    7'h17: begin rw = 1; x = immu + pc; end

    // STORE Rd,Rs1,ImmI [2*T]
    7'h23: case (t)

        // `bn` и `on` был подготовлен ранее для первой записи
        0: begin {m, wn} = 2'b11; tn = 1; cpn = ap; end
        1: begin

            // Следующее 32х битное слово
            cpn = (ap + 4);

            // Зависит от смещения
            case (ap[1:0])
            2'b01: begin bn = 4'b1110; on = r2[31:24]; end
            2'b10: begin bn = 4'b1100; on = r2[31:16]; end
            2'b11: begin bn = 4'b1000; on = r2[31:8];  end
            endcase

            case (fn3[1:0])
            // 2 байта: на границе слова
            2'b01: if (ap[1:0] == 2'b11) begin {m, wn} = 2'b11; tn = 2; bn = 4'b1110; end
            // 4 байта: невыровненные
            2'b10: if (ap[1:0] != 2'b00) begin {m, wn} = 2'b11; tn = 2; end
            endcase

        end

    endcase

    // Умножение или деление
    7'h33: if (fn7 == 7'h01) begin

        case (fn3)

        // Умножение
        0:     begin rw = 1; x = mul[31:0];  end // MUL
        1,2,3: begin rw = 1; x = mul[63:32]; end // MULH, MULHSU, MULHU

        endcase

    end
    // АЛУ с регистрами или умножение и деление
    else begin rw = 1; x = res; end

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

    t  <= 0;
    a  <= 0;                // Старт с 0x00000000
    pc <= 0;
    b  <= 4'b0;
    o  <= 32'b0;
    w  <= 1'b0;
    read <= 1'b0;

end else if (ce) begin

    t   <= tn;               // Счетчик фазы
    pc  <= pcn;              // Следующий PC
    a   <= m ? cpn : pcn;    // Новый PC или указатель
    o   <= on;
    b   <= bn;
    q   <= x;                // Для деления
    d   <= y;
    w   <= wn;
    read <= rn;

    if (!t) opcache <= instr;
    if (rw) r[rd] <= x;

end

endmodule

#define RD(i)    ((i >>  7) & 0x1F)
#define RS1(i)   ((i >> 15) & 0x1F)
#define RS2(i)   ((i >> 25) & 0x1F)
#define FN3(i)   ((i >> 12) & 0x07)
#define FN7(i)   ((i >> 25) & 0x7F)

#define IMMI(i)  (i >> 20)
#define IMM20(i) (i & 0xFFFFF000)
#define IMMS(i)  (((i >> 25) << 5) | ((i >> 7) & 0x1F))
#define IMMB(i)  (((i >> 31) << 12) | (((i >> 7) & 1) << 11) | (((i >> 25) & 0x3F) << 5) | (((i >> 8) & 0x0F) << 1))
#define IMMJ(i)  (((i >> 31) << 20) | (i & 0xFF000) | (((i >> 20) & 1) << 11) | (((i >> 21) & 0x3FF) << 1))

#define WR(i,v)  regs[i] = v
#define RR(i)    (i ? regs[i] : 0)

// Знакорасширение n-го бита
#define SIGN(i,n) (Uint32)((i & (1 << (n-1))) ? i | (0xFFFFFFFF ^ ((1 << n) - 1)) : i)

char   ds[64];

static const char* ralias[32] = {
    "zero", "ra", "sp",  "gp",  // 0
    "tp",   "t0", "t1",  "t2",  // 4
    "s0",   "s1", "a0",  "a1",  // 8
    "a2",   "a3", "a4",  "a5",  // 12
    "a6",   "a7", "s2",  "s3",  // 16
    "s4",   "s5", "s6",  "s7",  // 20
    "s8",   "s9", "s10", "s11", // 24
    "t3",   "t4", "t5",  "t6",  // 28
};

static const char* balias[8]  = {"BEQ  ", "BNE  ", "B?2  ", "B?3  ", "BLT  ", "BGE  ", "BLTU ", "BGEU "};
static const char* ialias[8]  = {"ADDI ", "#    ", "SLTI ", "SLTUI", "XORI ", "ORI  ", "?6   ", "ANDI "};
static const char* lalias[8]  = {"LB   ", "LH   ", "LW   ", "L?3  ", "LBU  ", "LHU  ", "L?6  ", "L?7  "};
static const char* salias[8]  = {"SB   ", "SH   ", "SW   ", "S?3  ", "S?4  ", "S?5  ", "S?6  ", "S?7  "};
static const char* aalias[10] = {"ADD  ", "SLL  ", "SLT  ", "SLTU ", "XOR  ", "SRL  ", "OR   ", "AND  ", "SUB  ", "SRA  "};

// Старт и загрузка в память файла
void init(int argc, char** argv)
{
    pc  = 0x00000000;
    mem = (Uint8*) calloc(MAX_MEM + 1, 1); // 1Mb

    // Загрузить программу в память
    if (argc > 1) {

        FILE* f = fopen(argv[1], "rb");
        if (f) { fread(mem, 1, 1024*1024, f); fclose(f); }
    }
}

// Чтение из памяти
Uint8  readb(Uint32 a) { return mem[a & MAX_MEM]; }
Uint16 readh(Uint32 a) { return readb(a) + readb(a+1)*256; }
Uint32 readw(Uint32 a) { return readh(a) + readh(a+2)*65536; }

// Запись в память
void   writeb(Uint32 a, Uint8  b) { mem[a & MAX_MEM] = b; }
void   writeh(Uint32 a, Uint16 b) { writeb(a, b); writeb(a + 1, b >> 8); }
void   writew(Uint32 a, Uint32 b) { writeh(a, b); writeb(a + 2, b >> 16); }

// Знакорасширение для вывода на экран
int signex(Uint32 i, int size)
{
    int s = (1 << (size - 1));
    int m = s - 1;

    if (i & s) {
        return -(((i & m) ^ m) + 1);
    } else {
        return i & m;
    }
}

// Дизассемблирование строки
void disasm(Uint32 a)
{
    int inst = readw(a);

    Uint32 opcode = (inst & 0x7F);
    Uint32 funct3 = FN3(inst);
    Uint32 funct7 = FN7(inst);
    Uint32 rd     = RD (inst);
    Uint32 rs1    = RS1(inst);
    Uint32 rs2    = RS2(inst);
    // ---
    Uint32 immi   = IMMI(inst);
    Uint32 immu   = IMM20(inst);
    Uint32 imms   = IMMS(inst);
    Uint32 immb   = IMMB(inst);
    Uint32 immj   = IMMJ(inst);

    ds[0] = 0;

    int immis = signex(immi, 12);
    int immbp = signex(immb, 13) + a;

    switch (opcode) {

        // АЛУ с IMMEDIATE
        case 0x13:

            switch (funct3) {

                case 1:
                    sprintf(ds, "SLLI  %s,%s,%d", ralias[rd], ralias[rs1], rs2); return;

                case 5:
                    sprintf(ds, "%s %s,%s,%d", funct7 ? "SRAI " : "SRLI ", ralias[rd], ralias[rs1], rs2); return;

                case 0: case 2: case 3: case 4: case 6: case 7:

                    immi = (funct3 == 3 ? immi : immis);
                    sprintf(ds, "%s %s,%s,%d # $%03x", ialias[funct3], ralias[rd], ralias[rs1], immi, immi & 0xFFF); return;
            }

            break;

        // ПЕРЕХОДЫ
        case 0x17: sprintf(ds, "AUIPC %s,$%08x", ralias[rd], immu); return;
        case 0x37: sprintf(ds, "LUI   %s,$%08x", ralias[rd], immu); return;
        case 0x67:

            switch (funct3) {
                case 0: sprintf(ds, "JALR  %s,%d => %s", ralias[rs1], immis & ~1, ralias[rd]); return;
            }

            break;

        case 0x6F:

            sprintf(ds, "JAL   %s,$%08x", ralias[rd], a + signex(immj, 21)); return;

        // ЗАГРУЗКА И СОХРАНЕНИЕ
        case 0x03:

            sprintf(ds, "%s %s,(%s,%d)", lalias[funct3], ralias[rd], ralias[rs1], immis); return;

        case 0x23:

            sprintf(ds, "%s %s,(%s,%d)", salias[funct3], ralias[rs2], ralias[rs1], signex(imms, 12)); return;

        // УСЛОВНЫЕ ПЕРЕХОДЫ
        case 0x63:

            sprintf(ds, "%s %s,%s => %08x", balias[funct3], ralias[rs1], ralias[rs2], immbp); return;

        // АРИФМЕТИКО-ЛОГИКА
        case 0x33:

            if      (funct3 == 0 && funct7) funct3 = 10; // SUB
            else if (funct3 == 5 && funct7) funct3 = 11; // SRA

            sprintf(ds, "%s %s,%s,%s", aalias[funct3], ralias[rd], ralias[rs1], ralias[rs2]); return;
    }

    printf("Undefined %02x opcode %08X\n", opcode, inst);
}

void step()
{
    Uint32 i = readw(pc);
    Uint32 t = 0, a, b;

    switch (i & 0x7F) {

        // LUI Rd, Imm20
        case 0x37: {

            WR(RD(i), IMM20(i));
            break;
        }

        // AUIPC Rd, Imm20
        case 0x17: {

            WR(RD(i), pc + IMM20(i));
            break;
        }

        // JAL Rd, ImmJ
        case 0x6F: {

            WR(RD(i), pc + 4);
            pc += SIGN(IMMJ(i), 21);
            return;
        }

        // JALR Rd,Rs1,ImmI
        case 0x67: {

            WR(RD(i), pc + 4);
            pc = RR(RS1(i)) + (SIGN(i >> 20, 12) & ~1);
            return;
        }

        // LOAD: Загрузка данных из памяти
        case 0x03: {

            a = RS1(i) + SIGN(IMMI(i), 12);

            switch (FN3(i)) {

                case 0: WR(RD(i), SIGN(readb(a), 8)); break;    // LB
                case 1: WR(RD(i), SIGN(readh(a), 16)); break;   // LH
                case 2: WR(RD(i), readw(a)); break;             // LW
                case 4: WR(RD(i), readb(a)); break;             // LBU
                case 5: WR(RD(i), readh(a)); break;             // LHU
            }

            break;
        }

        // STORE: Сохранение данных в память
        case 0x23: {

            a = RS1(i) + SIGN(IMMS(i), 12);

            switch (FN3(i)) {

                case 0: writeb(a, RR(RS2(i))); break;   // SB
                case 2: writeh(a, RR(RS2(i))); break;   // SH
                case 3: writew(a, RR(RS2(i))); break;   // SW
            }

            break;
        }

        // BRANCH rs1,rs2,immb: Условные переходы
        case 0x63: {

            a = RR(RS1(i));
            b = RR(RS2(i));

            switch (FN3(i)) {

                case 0: t = (a == b); break;    // BEQ
                case 1: t = (a != b); break;    // BNE
                case 4: t = ((int)a <  (int)b); break; // BLT
                case 5: t = ((int)a >= (int)b); break; // BGE
                case 6: t = a <  b; break;      // BLTU
                case 7: t = a >= b; break;      // BGEU
            }

            // Выполнить переход, если совпало условие
            if (t) { pc += SIGN(IMMB(i), 13); return; }

            break;
        }
    }
}

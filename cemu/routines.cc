// Для декодера
Uint32 opcode, funct3, rd, rs1, rs2, funct7, immi, imms, immb, immu, immj;
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

// Вернуть байт
Uint8  readb(Uint32 a) { return mem[a & MAX_MEM]; }
Uint16 readh(Uint32 a) { return readb(a) + readb(a+1)*256; }
Uint32 readw(Uint32 a) { return readh(a) + readh(a+2)*65536; }

// Раскодировать операнды и поля
void decode(Uint32 inst)
{
    opcode = (inst & 0x7F);
    funct3 = (inst >> 12) & 7;
    rd     = (inst >>  7) & 0x1F;
    rs1    = (inst >> 15) & 0x1F;
    rs2    = (inst >> 20) & 0x1F;
    funct7 = (inst >> 25) & 0x7F;
    immi   = (inst >> 20);
    immu   = inst & 0xFFFFF000;
    imms   = (funct7 << 5) | rd;
    immb   = ((inst >> 31) << 12) | (((inst >> 7) & 1) << 11) | (((inst >> 25) & 0x3F) << 5) | (((inst >> 8) & 0x0F) << 1);
    immj   = ((inst >> 31) << 20) | (inst & 0xFF000) | (((inst >> 20) & 1) << 11) | (((inst >> 21) & 0x3FF) << 1);
}

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

    decode(inst);

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

            sprintf(ds, "JAL   %s,$%08x", ralias[rd], a + signex(immj,21)); return;

        // ЗАГРУЗКА И СОХРАНЕНИЕ
        case 0x03:

            sprintf(ds, "%s %s,(%s,%d)", lalias[funct3], ralias[rd], ralias[rs1], immis); return;

        case 0x23:

            sprintf(ds, "%s %s,(%s,%d)", salias[funct3], ralias[rs2], ralias[rs1], signex(imms,12)); return;

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

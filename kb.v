/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */

module kb
(
    // 25 MHZ
    input               clock,
    input               reset_n,

    // Рассылка команд
    input               cmd,                // =1 строб команды
    input       [7:0]   dat,                // Отсылаемый байт

    // Ввод-вывод на клавиатуру и наоборот
    inout               ps_clk,
    inout               ps_dat,

    // Исходящие данные от клавиатуры
    output              ready,      // =1 Устройство готово к приему команды cmd=1, dat
    output  reg         hit,        // =1 Одиночный хит на получение данных от контроллера
    output  reg         kdone,      // =1 Если пришел ASCII ответ
    output  reg [7:0]   kbd,        // Данные от клавиатуры
    output  reg [7:0]   ascii,      // Код ASCII
    output  reg         err,        // =1 Ошибка обработки или таймаут

    // Регистры состояния для отладки
    output  reg [ 1:0]  stage,      // Стадия
    output  reg [ 7:0]  t,          // Субфункция
    output  reg [ 9:0]  dm,         // Отсчет таймаута 5 мк x 1024 = 5 ms
    output  reg [ 6:0]  dx,         // 200 kHz делитель частоты (5 мкс один отсчет)
    output  reg [ 1:0]  rt,         // Обнаружение CLOCK
    output  reg [ 3:0]  cnt,
    output  reg         CMD,
    output  reg [ 9:0]  DAT,

    // Регистр исходящих CLK/DAT для мыши
    output  reg         we_clk,
    output  reg         we_dat,
    output  reg         PS_CLK,
    output  reg         PS_DAT
);
// -----------------------------------------------------------------------------
localparam
    PERIOD = 124,           // 200 kHz (25000000/200000 - 1)
    CWAIT  = 20;            // Ожидание перед отправкой команды x 5 мкс

localparam
    IDLE        = 0,
    RECEIVE     = 1,
    TRANSMIT    = 2;
// -----------------------------------------------------------------------------
assign  ready  = (CMD == 0);
assign  ps_clk = we_clk ? PS_CLK : 1'bz;
assign  ps_dat = we_dat ? PS_DAT : 1'bz;
// -----------------------------------------------------------------------------
wire    valid = ps_dat ^ (^kbd);
reg     released, extended, shift;
// -----------------------------------------------------------------------------
always @(negedge clock)
if (reset_n == 0) begin

    t        <= 0;
    dx       <= 0;
    dm       <= 0;
    we_clk   <= 0;
    we_dat   <= 0;
    cnt      <= 0;
    err      <= 0;
    stage    <= IDLE;
    CMD      <= 0;
    DAT      <= 8'h00;
    kdone    <= 1'b0;
    shift    <= 1'b0;
    released <= 1'b0;
    extended <= 1'b0;

end
else begin

    hit     <= 1'b0;
    kdone   <= 1'b0;

    // Регистрация команды для отсылки устройству
    if (cmd) begin CMD <= 1; DAT <= {/*STOP*/ 1'b1, /*PAR*/ ~^dat, dat}; err <= 0; end

    // 5 микросекунд, 200 kHz (основано на 25 Mhz) 25M / 125 = 200k
    if (dx == PERIOD) begin

        // Регистрация сигнала CLK от клавиатуры
        rt <= {rt[0], ps_clk};

        // Проверка на таймаут, сброс в IDLE при ошибке
        if (stage) begin dm <= dm + 1; if (&dm) begin stage <= IDLE; CMD <= 0; err <= 1; end end

        case (stage)

            // Ожидание команды от хоста или данных от клавиатуры/мыши
            // -----------------------------------------------------------------
            IDLE: begin

                t   <= 0;
                cnt <= 0;

                // [R] Получен сигнал от клавиатуры
                if (rt == 2'b10) begin

                    stage <= RECEIVE;
                    err   <= 0;

                end
                // [T] Запрос исполнения команды
                else if (CMD) begin

                    stage <= TRANSMIT;
                    err   <= 0;
                    {we_clk, we_dat} <= 2'b11;
                    {PS_CLK, PS_DAT} <= 2'b11;

                end

            end

            // Прием сигнала от устройства
            // https://ru.wikipedia.org/wiki/Скан-код
            // -----------------------------------------------------------------
            RECEIVE: if (rt == 2'b01) begin

                t  <= t + 1;
                dm <= 0;

                case (t)
                // Старт-бит должен быть равен 0, иначе не принимать данные
                0: if (ps_dat) begin stage <= IDLE; err <= 1; end

                // Прием LSB (8 бит)
                1,2,3,4,5,6,7,8: kbd <= {ps_dat, kbd[7:1]};

                // Сверка бита четности:
                // - Если количество ЧЕТНО, то там будет 0, а в PS_DAT=1, так что ОК
                // - И наоборот также, НЕЧЕТНО дает 1, а в PS_DAT=0, и это OK
                // - Иначе не OK ни разу
                9: begin

                    hit <= valid;

                    // Клавиша отпущена
                    if      (kbd == 8'hF0) begin released <= 1'b1; end
                    else if (kbd == 8'hE0) begin extended <= 1'b1; end
                    // Декодирование клавиши
                    else begin

                        // Отправка клавиши только при KeyDown
                        kdone <= valid && !released;

                        // Декодирование клавиши
                        case ({extended, kbd})

                            // Левый и правый SHIFT равнозначны
                            /* SH */ 8'h12, 8'h59: begin shift <= ~released; kdone <= 1'b0; end

                            // Цифробуквенная клавиатура
                            /* Aa */ 8'h1C: ascii <= shift ? 8'h41 : 8'h61;
                            /* Bb */ 8'h32: ascii <= shift ? 8'h42 : 8'h62;
                            /* Cc */ 8'h21: ascii <= shift ? 8'h43 : 8'h63;
                            /* Dd */ 8'h23: ascii <= shift ? 8'h44 : 8'h64;
                            /* Ee */ 8'h24: ascii <= shift ? 8'h45 : 8'h65;
                            /* Ff */ 8'h2B: ascii <= shift ? 8'h46 : 8'h66;
                            /* Gg */ 8'h34: ascii <= shift ? 8'h47 : 8'h67;
                            /* Hh */ 8'h33: ascii <= shift ? 8'h48 : 8'h68;
                            /* Ii */ 8'h43: ascii <= shift ? 8'h49 : 8'h69;
                            /* Jj */ 8'h3B: ascii <= shift ? 8'h4A : 8'h6A;
                            /* Kk */ 8'h42: ascii <= shift ? 8'h4B : 8'h6B;
                            /* Ll */ 8'h4B: ascii <= shift ? 8'h4C : 8'h6C;
                            /* Mm */ 8'h3A: ascii <= shift ? 8'h4D : 8'h6D;
                            /* Nn */ 8'h31: ascii <= shift ? 8'h4E : 8'h6E;
                            /* Oo */ 8'h44: ascii <= shift ? 8'h4F : 8'h6F;
                            /* Pp */ 8'h4D: ascii <= shift ? 8'h50 : 8'h70;
                            /* Qq */ 8'h15: ascii <= shift ? 8'h51 : 8'h71;
                            /* Rr */ 8'h2D: ascii <= shift ? 8'h52 : 8'h72;
                            /* Ss */ 8'h1B: ascii <= shift ? 8'h53 : 8'h73;
                            /* Tt */ 8'h2C: ascii <= shift ? 8'h54 : 8'h74;
                            /* Uu */ 8'h3C: ascii <= shift ? 8'h55 : 8'h75;
                            /* Vv */ 8'h2A: ascii <= shift ? 8'h56 : 8'h76;
                            /* Ww */ 8'h1D: ascii <= shift ? 8'h57 : 8'h77;
                            /* Xx */ 8'h22: ascii <= shift ? 8'h58 : 8'h78;
                            /* Yy */ 8'h35: ascii <= shift ? 8'h59 : 8'h79;
                            /* Zz */ 8'h1A: ascii <= shift ? 8'h5A : 8'h7A;

                            // Цифры
                            /* 0) */ 8'h45: ascii <= shift ? 8'h29 : 8'h30;
                            /* 1! */ 8'h16: ascii <= shift ? 8'h21 : 8'h31;
                            /* 2@ */ 8'h1E: ascii <= shift ? 8'h40 : 8'h32;
                            /* 3# */ 8'h26: ascii <= shift ? 8'h23 : 8'h33;
                            /* 4$ */ 8'h25: ascii <= shift ? 8'h24 : 8'h34;
                            /* 5% */ 8'h2E: ascii <= shift ? 8'h25 : 8'h35;
                            /* 6^ */ 8'h36: ascii <= shift ? 8'h5E : 8'h36;
                            /* 7& */ 8'h3D: ascii <= shift ? 8'h26 : 8'h37;
                            /* 8* */ 8'h3E: ascii <= shift ? 8'h2A : 8'h38;
                            /* 9( */ 8'h46: ascii <= shift ? 8'h28 : 8'h39;

                            // Спецсимволы
                            /* `~ */ 8'h0E: ascii <= shift ? 8'h7E : 8'h60;
                            /* -_ */ 8'h4E: ascii <= shift ? 8'h5F : 8'h2D;
                            /* =+ */ 8'h55: ascii <= shift ? 8'h2B : 8'h3D;
                            /* \| */ 8'h5D: ascii <= shift ? 8'h7C : 8'h5C;
                            /* [{ */ 8'h54: ascii <= shift ? 8'h7B : 8'h5B;
                            /* ]} */ 8'h5B: ascii <= shift ? 8'h7D : 8'h5D;
                            /* ;: */ 8'h4C: ascii <= shift ? 8'h3A : 8'h3B;
                            /* '" */ 8'h52: ascii <= shift ? 8'h22 : 8'h27;
                            /* ,< */ 8'h41: ascii <= shift ? 8'h3C : 8'h2C;
                            /* .> */ 8'h49: ascii <= shift ? 8'h3E : 8'h2E;
                            /* /? */ 8'h4A: ascii <= shift ? 8'h3F : 8'h2F;

                            // Разные клавиши
                            /* BACK */ 8'h66:   ascii <= 8'h08;
                            /* TAB  */ 8'h0D:   ascii <= 8'h09;
                            /* ENT  */ 8'h5A:   ascii <= 8'h0A;
                            /* ESC  */ 8'h76:   ascii <= 8'h1B;
                            /* SPC  */ 8'h29:   ascii <= 8'h20;

                            // Дополненный набор
                            /* PGUP */ 9'h17D:  ascii <= 8'h01;
                            /* PGDN */ 9'h17A:  ascii <= 8'h02;
                            /* UP   */ 9'h175:  ascii <= 8'h03;
                            /* RT   */ 9'h174:  ascii <= 8'h04;
                            /* DN   */ 9'h172:  ascii <= 8'h05;
                            /* LF   */ 9'h16B:  ascii <= 8'h06;
                            /* DEL  */ 9'h171:  ascii <= 8'h07;
                            /* INS  */ 9'h16C:  ascii <= 8'h0B;
                            /* HOME */ 9'h170:  ascii <= 8'h0C;
                            /* END  */ 9'h169:  ascii <= 8'h0D;

                            // Клавиши, которые не играют никакой роли
                            default: kdone <= 1'b0;

                        endcase

                        released <= 1'b0;
                        extended <= 1'b0;

                    end

                end

                // Стоповый бит если 0, то это ошибка
                10: begin

                    CMD   <= 0;
                    stage <= IDLE;
                    err   <= ~ps_dat;

                end

                endcase

            end

            // Процедура отсылки команды на клавиатуру
            // https://wiki.osdev.org/PS/2_Keyboard#Command_Queue_and_State_Machine
            // -----------------------------------------------------------------
            TRANSMIT: begin

                t <= t + 1;

                case (t)

                    // Пролог
                    CWAIT:    begin PS_CLK <= 0; end              // CLK=0 на 100 мк
                    CWAIT+20: begin PS_DAT <= 0; end              // DAT=0 на 50 мк
                    CWAIT+28: begin PS_CLK <= 1; end              // CLK=1 старт бит
                    CWAIT+29: begin we_clk <= 0; dm <= 0; end

                    // Ожидание 10 битов от клавиатуры
                    // Ожидание может длиться до 5 миллисекунд, иначе сброс
                    CWAIT+30: begin

                        t <= CWAIT+30;

                        // На негативном фронте CLK отправка данных
                        if (rt == 2'b10) begin

                            PS_DAT  <= DAT[0];
                            DAT     <= DAT[9:1];
                            cnt     <= cnt + 1;
                            dm      <= 0;

                        end
                        // Отосланы все 10 бит, на позитивном фронте CLK
                        else if (rt == 2'b01 && cnt == 10) t <= CWAIT+31;

                    end

                    // Ждать бита ACK от клавиатуры
                    CWAIT+31: we_dat <= 0;
                    CWAIT+33: begin dm <= 0; t <= CWAIT + (rt == 2'b01 ? 34 : 33); end

                    // Через 10 мкс завершить отсылку и перейти к стадии приема ответа от клавиатуры
                    CWAIT+34: t <= (rt == 2'b10) ? CWAIT+35 : CWAIT+34;
                    CWAIT+35: begin stage <= RECEIVE; t <= 0; end

                endcase

            end

        endcase

    end

    dx <= (dx == PERIOD) ? 0 : dx + 1;

end

endmodule

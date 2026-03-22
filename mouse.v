// https://wiki.osdev.org/PS/2_Mouse
// -----------------------------------------------------------------------------
module mouse
(
    input               clock,      // 25 MHZ
    input               reset_n,    // =0 Сброс
    // --------------------
    inout               ps_clk,     // Входящие данные от PS2_CLK
    output reg          cmd,        // Отправка команды на мышь
    output reg  [ 7:0]  dat,        // Что отправлять
    input               ready,      // Ждать готовности
    input               hit,        // Ответ от мыши
    input       [ 7:0]  kbd,        // Данные от мыши
    // --------------------
    output reg  [11:0]  x,          // Координата X
    output reg  [11:0]  y,          // Координата Y
    output reg  [ 2:0]  btn,        // Кнопки мыши
    output reg          recv,       // =1 Принятые данные
    // --------------------
    input       [11:0]  xmax,       // Если 0=639 (максимум X)
    input       [11:0]  ymax        // Если 0=479 (максимум Y)
);

// Регистры
reg [ 1:0] t;
reg [ 1:0] rc;
reg [23:0] sr;
reg [15:0] tm;

// Границы окна
wire [11:0] xm = xmax ? xmax - 1 : 639;
wire [11:0] ym = ymax ? ymax - 1 : 479;

// Следующие принятые данные
wire [23:0] isr   = {kbd, sr[23:8]};
wire [11:0] xnext = x + {{4{isr[4]}}, isr[15:8]};
wire [11:0] ynext = y - {{4{isr[5]}}, isr[23:16]};

always @(posedge clock)
if (reset_n) begin

    recv <= 0;

    // Код активации мыши в работу
    case (t)
    0: begin t <= ready ? 1 : 0; end
    1: begin cmd <= 1; t <= 2; dat <= 8'hF4; end
    2: begin cmd <= 0; end
    endcase

    // Отметить что ранее принятые данные невалидны
    if (tm == 16'hFFFE) rc <= 0;

    // Таймаут CLK=1 приема данных 2.6 мс
    tm <= ps_clk ? (&tm ? tm : tm + 1) : 0;

    // Прием данных
    if (hit) begin

        // Если были приняты все 3 байта из потока
        if (rc == 2) begin

            x    <= xnext[11] ? 0 : (xnext > xm ? xm : xnext);
            y    <= ynext[11] ? 0 : (ynext > ym ? ym : ynext);
            btn  <= isr[2:0];
            recv <= 1;

        end

        sr <= isr;
        rc <= rc == 2 ? 0 : rc + 1;

    end

end else begin

    t  <= 0;
    rc <= 0;
    x  <= (xmax >> 1);
    y  <= (ymax >> 1);

end

endmodule

# Создаем описание частоты для входного пина
create_clock -name clk_50 -period 20.000 [get_ports {CLOCK_50}]

# Автоматически вычисляем частоты для всех выходов PLL
derive_pll_clocks

# Вычисляем погрешности (jitter и т.д.)
derive_clock_uncertainty

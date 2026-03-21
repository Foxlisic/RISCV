// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
// ---------------------
module m256(c, /*PORT1*/ a,d,q,w,b, /*PORT-2*/ cx,ax,dx,qx,wx,bx);
input           c, cx;
input    [ 3:0] b, bx;
input    [15:0] a, ax;
input    [31:0] d, dx;
output   [31:0] q, qx;
input           w, wx;
// ---------------------
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
    tri1      c;
    tri0      w, wx;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif
// ---------------------
altsyncram altsyncram_component
(
// -- Порт-1 --
    .clock0           (c),
    .address_a        (a),
    .data_a           (d),
    .wren_a           (w),
    .q_a              (q),
// -- Порт-2 --
    // .clock1           (cx),
    .address_b        (ax),
    .data_b           (dx),
    .wren_b           (wx),
    .q_b              (qx),
// -- Настойки --
    .aclr0            (1'b0),   // Чистка кармы выходного регистра A/B асинхронно
    .aclr1            (1'b0),
    .addressstall_a   (1'b0),   // Не защелкивать адресный входящий регистр A
    .addressstall_b   (1'b0),
    .byteena_a        (~b),     // Маска активации записи байта из data-входа
    .byteena_b        (4'b1111),
    .clocken0         (1'b1),
    .clocken1         (1'b1),
    .clocken2         (1'b1),
    .clocken3         (1'b1),
    .eccstatus        (),     // Не проверять ECC
    .rden_a           (1'b1), // Разрешить чтение и также защелкивание на выходном регистре
    .rden_b           (1'b1)
);
defparam
    altsyncram_component.init_file                  = "m256.mif",
// --
    altsyncram_component.address_reg_b              = "CLOCK0",
    altsyncram_component.indata_reg_b               = "CLOCK0",
    altsyncram_component.wrcontrol_wraddress_reg_b  = "CLOCK0",
    altsyncram_component.outdata_reg_a              = "UNREGISTERED",
    altsyncram_component.outdata_reg_b              = "UNREGISTERED",
    altsyncram_component.outdata_aclr_a             = "NONE",
    altsyncram_component.outdata_aclr_b             = "NONE",
// --
    altsyncram_component.widthad_a                  = 16,
    altsyncram_component.widthad_b                  = 16,
    altsyncram_component.width_a                    = 32,
    altsyncram_component.width_b                    = 32,
    altsyncram_component.numwords_a                 = 65536,
    altsyncram_component.numwords_b                 = 65536,
    altsyncram_component.width_byteena_a            = 4,
    altsyncram_component.width_byteena_b            = 4,
// --
    altsyncram_component.clock_enable_input_a       = "BYPASS",
    altsyncram_component.clock_enable_input_b       = "BYPASS",
    altsyncram_component.clock_enable_output_a      = "BYPASS",
    altsyncram_component.clock_enable_output_b      = "BYPASS",
// --
    altsyncram_component.lpm_type                   = "altsyncram",
    altsyncram_component.ram_block_type             = "M10K",
    altsyncram_component.intended_device_family     = "Cyclone V",
    altsyncram_component.power_up_uninitialized     = "FALSE",
    altsyncram_component.operation_mode             = "BIDIR_DUAL_PORT",
// --
    altsyncram_component.read_during_write_mode_mixed_ports    = "DONT_CARE",
    altsyncram_component.read_during_write_mode_port_a         = "NEW_DATA_NO_NBE_READ",
    altsyncram_component.read_during_write_mode_port_b         = "NEW_DATA_NO_NBE_READ";
endmodule

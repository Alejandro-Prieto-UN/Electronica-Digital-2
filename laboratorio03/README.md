# Laboratorio 03 - ALU + Banco de Registros + Diseño Modular

### NOMBRES PARTICIPANTES

- Jhohan Stiven Rodríguez Rodríguez
- Alejandro Brandon Prieto León
- Ángel Alirio Rivera Amortegui

## 1. Código Fuente de los Módulos (`src/`)

El sistema modular está dividido en unidades funcionales independientes encargadas del procesamiento aritmético, la selección dinámica de operandos, la gestión del banco de registros y el protocolo de visualización.

### 1.1. Unidad Aritmético Lógica (`src/alu.v`)

Módulo combinacional puro encargado de ejecutar las operaciones aritméticas y lógicas seleccionadas mediante la señal `opcode[2:0]`.

```verilog
`timescale 1ns / 1ps

module alu (
    input  wire [3:0] A,        // Operando A (4 bits)
    input  wire [3:0] B,        // Operando B (4 bits)
    input  wire [2:0] opcode,   // Operación seleccionada por SW[2:0] (3 bits)
    output reg  [3:0] result    // Resultado de la ALU (4 bits)
);

    // Lógica combinacional pura
    always @(*) begin
        case (opcode)
            3'b000:  result = A + B;       // Suma
            3'b001:  result = A - B;       // Resta
            3'b010:  result = A & B;       // AND bit a bit
            3'b011:  result = A | B;       // OR bit a bit
            3'b100:  result = A ^ B;       // XOR bit a bit
            3 me:    result = ~A;          // NOT en Operando A
            3'b110:  result = A << 1;      // Desplazamiento lógico izquierda (Shift Left)
            3'b111:  result = A >> 1;      // Desplazamiento lógico derecha (Shift Right)
            default: result = 4'b0000;     // Estado por defecto de seguridad
        endcase
    end

endmodule

### 1.2. Selector combinacional de registros

`timescale 1ns / 1ps

module comb_selector (
    input  wire       clk,            // Reloj principal de 125 MHz
    input  wire       btn_next_comb,  // BTN2: Cambia a la siguiente combinación
    output reg  [1:0] read_addr_a,    // Dirección de lectura para Operando A
    output reg  [1:0] read_addr_b,    // Dirección de lectura para Operando B
    output reg  [3:0] active_leds     // Salida hacia LEDs verdes (LED[3:0])
);

    // Contador interno para indexar las 6 combinaciones posibles
    reg [2:0] comb_index = 3'b000;
    reg btn_next_prev = 1'b0;

    // 1. LÓGICA SECUENCIAL: Avanzar el contador con flanco de subida en BTN2
    always @(posedge clk) begin
        btn_next_prev <= btn_next_comb;

        if (btn_next_comb && !btn_next_prev) begin
            if (comb_index == 3'd5)
                comb_index <= 3'b000;  // Reinicia al llegar a la última combinación
            else
                comb_index <= comb_index + 1'b1;
        end
    end

    ### 1.2.2. LÓGICA COMBINACIONAL: Mapeo de índice a direcciones y LEDs
    always @(*) begin
        case (comb_index)
            3'd0: begin // Pareja (R0, R1)
                read_addr_a = 2'b00;
                read_addr_b = 2'b01;
                active_leds = 4'b0011;
            end
            3'd1: begin // Pareja (R0, R2)
                read_addr_a = 2'b00;
                read_addr_b = 2'b10;
                active_leds = 4'b0101;
            end
            3'd2: begin // Pareja (R0, R3)
                read_addr_a = 2'b00;
                read_addr_b = 2'b11;
                active_leds = 4'b1001;
            end
            3'd3: begin // Pareja (R1, R2)
                read_addr_a = 2'b01;
                read_addr_b = 2'b10;
                active_leds = 4'b0110;
            end
            3'd4: begin // Pareja (R1, R3)
                read_addr_a = 2 me;
                read_addr_b = 2'b11;
                active_leds = 4'b1010;
            end
            3'd5: begin // Pareja (R2, R3)
                read_addr_a = 2'b10;
                read_addr_b = 2'b11;
                active_leds = 4'b1100;
            end
            default: begin
                read_addr_a = 2'b00;
                read_addr_b = 2'b01;
                active_leds = 4'b0011;
            end
        endcase
    end

endmodule

### 1.3. Controlador de visualización

`timescale 1ns / 1ps

module display_tm1637 (
    input  wire       clk,          // Reloj del sistema (125 MHz)
    input  wire       btn_exec,     // BTN3: Ejecución de la operación y Latch
    input  wire [3:0] alu_result,   // Resultado procesado por la ALU
    output reg        clk_display = 1'b1,
    inout  wire       dio_display
);

    // ---------------- 1. Latch del resultado con BTN3 ----------------
    reg [1:0] btn_sync = 2'b00;
    reg       btn_prev = 1'b0;
    reg [3:0] latched_result = 4'h0;

    always @(posedge clk) begin
        btn_sync <= {btn_sync[0], btn_exec};   // Sincronizador de 2 FFs
        btn_prev <= btn_sync[1];
        if (btn_sync[1] && !btn_prev)
            latched_result <= alu_result;
    end

    // ---------------- 2. Decodificador Hexadecimal a 7 Segmentos ----------------
    function [7:0] seg7_map(input [3:0] d);
        case (d)
            4'h0: seg7_map = 8'h3F;
            4'h1: seg7_map = 8'h06;
            4'h2: seg7_map = 8'h5B;
            4'h3: seg7_map = 8'h4F;
            4'h4: seg7_map = 8'h66;
            4'h5: seg7_map = 8'h6D;
            4'h6: seg7_map = 8'h7D;
            4'h7: seg7_map = 8'h07;
            4'h8: seg7_map = 8'h7F;
            4'h9: seg7_map = 8'h6F;
            4'hA: seg7_map = 8'h77;
            4'hB: seg7_map = 8'h7C;
            4'hC: seg7_map = 8'h39;
            4'hD: seg7_map = 8'h5E;
            4'hE: seg7_map = 8'h79;
            4'hF: seg7_map = 8'h71;
            default: seg7_map = 8'h00;
        endcase
    endfunction

    // ---------------- 3. Generación de Tick de Temporización (100 kHz) ----------------
    reg [10:0] tick_cnt = 11'd0;
    wire       tick = (tick_cnt == 11'd1249);
    always @(posedge clk)
        tick_cnt <= tick ? 11'd0 : tick_cnt + 1'b1;

    // ---------------- 4. Control Tri-state para DIO ----------------
    reg dio_out = 1'b1;
    reg dio_oe  = 1'b1;
    assign dio_display = dio_oe ? dio_out : 1'bz;

    // ---------------- 5. Máquina de Estados Finitos (FSM) ----------------
    localparam S_START0   = 4'd0,
               S_START1   = 4'd1,
               S_LOAD     = 4'd2,
               S_SETUP    = 4'd3,
               S_HIGH     = 4'd4,
               S_FALL     = 4'd5,
               S_ACK_REL  = 4'd6,
               S_ACK_H    = 4'd7,
               S_ACK_L    = 4'd8,
               S_ACK_TAKE = 4'd9,
               S_STOP1    = 4'd10,
               S_STOP2    = 4'd11;

    reg [3:0] st        = S_START0;
    reg [1:0] byte_idx  = 2'd0;
    reg [7:0] shift_reg = 8'd0;
    reg [2:0] bit_cnt   = 3'd0;

    reg [7:0] cur_byte;
    always @(*) begin
        case (byte_idx)
            2'd0:    cur_byte = 8'h44;                       // Comando: Dirección Fija
            2'd1:    cur_byte = 8'hC0;                       // Dirección Digito 1
            2'd2:    cur_byte = seg7_map(latched_result);    // Segmentos cargados
            default: cur_byte = 8'h8F;                       // Control: Display ON, brillo máx
        endcase
    end

    always @(posedge clk) begin
        if (tick) begin
            case (st)
                S_START0: begin
                    dio_oe <= 1'b1; clk_display <= 1'b1; dio_out <= 1'b1;
                    st <= S_START1;
                end
                S_START1: begin
                    dio_out <= 1'b0;
                    st <= S_LOAD;
                end
                S_LOAD: begin
                    clk_display <= 1'b0;
                    shift_reg   <= cur_byte;
                    bit_cnt     <= 3'd0;
                    st <= S_SETUP;
                end
                S_SETUP: begin
                    dio_out <= shift_reg[0];
                    st <= S_HIGH;
                end
                S_HIGH: begin
                    clk_display <= 1'b1;
                    st <= S_FALL;
                end
                S_FALL: begin
                    clk_display <= 1'b0;
                    shift_reg   <= {1'b0, shift_reg[7:1]};
                    if (bit_cnt == 3'd7) st <= S_ACK_REL;
                    else begin bit_cnt <= bit_cnt + 1'b1; st <= S_SETUP; end
                end
                S_ACK_REL: begin
                    dio_oe <= 1'b0;
                    st <= S_ACK_H;
                end
                S_ACK_H: begin
                    clk_display <= 1'b1;
                    st <= S_ACK_L;
                end
                S_ACK_L: begin
                    clk_display <= 1'b0;
                    st <= S_ACK_TAKE;
                end
                S_ACK_TAKE: begin
                    dio_oe  <= 1'b1;
                    dio_out <= 1'b0;
                    if (byte_idx == 2'd1) begin
                        byte_idx <= 2'd2;
                        st <= S_LOAD;
                    end else
                        st <= S_STOP1;
                end
                S_STOP1: begin
                    clk_display <= 1'b1;
                    st <= S_STOP2;
                end
                S_STOP2: begin
                    dio_out <= 1'b1;
                    byte_idx <= (byte_idx == 2'd3) ? 2'd0 : byte_idx + 1'b1;
                    st <= S_START0;
                end
                default: st <= S_START0;
            endcase
        end
    end

endmodule
## 1.2. Módulo Principal / Top (`src/top.v`)

Módulo de jerarquía superior (*Top-Level Module*) que interconecta todos los bloques funcionales del sistema. Recibe los estímulos de la FPGA (entradas de switches y pulsadores), gestiona el banco de registros local de 4 posiciones, instancia la ALU, el selector combinacional y el controlador TM1637.

```verilog
`timescale 1ns / 1ps

module top (
    input  wire       clk,         // Reloj principal de la placa (125 MHz)
    input  wire [3:0] sw,          // SW[2:0]: Opcode de la ALU | SW[3]: No usado
    input  wire       btn2,        // BTN2: Rotar combinación de operandos
    input  wire       btn3,        // BTN3: Ejecutar operación y enviar resultado al Display
    output wire [3:0] led,         // LED[3:0]: Indican los 2 registros seleccionados
    output wire       clk_display, // Señal CLK serial para el módulo TM1637
    inout  wire       dio_display  // Línea bidireccional DIO para el módulo TM1637
);

    // ---------------- 1. Banco de Registros (4 Registros de 4 bits) ----------------
    // Valores predefinidos/cargados para las pruebas
    reg [3:0] reg_bank [0:3];

    initial begin
        reg_bank[0] = 4'h3; // R0 = 3 (0011)
        reg_bank[1] = 4'h5; // R1 = 5 (0101)
        reg_bank[2] = 4'hA; // R2 = 10 (1010 / 'A' en hex)
        reg_bank[3] = 4'hF; // R3 = 15 (1111 / 'F' en hex)
    end

    // ---------------- 2. Interconexiones Internas ----------------
    wire [1:0] addr_a;
    wire [1:0] addr_b;
    wire [3:0] operand_a;
    wire [3:0] operand_b;
    wire [3:0] alu_out;

    // Lectura continua del banco de registros
    assign operand_a = reg_bank[addr_a];
    assign operand_b = reg_bank[addr_b];

    // ---------------- 3. Instancia: Selector Combinacional ----------------
    comb_selector u_comb_selector (
        .clk            (clk),
        .btn_next_comb  (btn2),
        .read_addr_a    (addr_a),
        .read_addr_b    (addr_b),
        .active_leds    (led)
    );

    // ---------------- 4. Instancia: Unidad Aritmético Lógica (ALU) ----------------
    alu u_alu (
        .A      (operand_a),
        .B      (operand_b),
        .opcode (sw[2:0]),
        .result (alu_out)
    );

    // ---------------- 5. Instancia: Controlador TM1637 ----------------
    display_tm1637 u_display (
        .clk         (clk),
        .btn_exec    (btn3),
        .alu_result  (alu_out),
        .clk_display (clk_display),
        .dio_display (dio_display)
    );

endmodule

## 3. Testbench de Simulación (`testbench/tb_top_lab03.v`)

Módulo de verificación para simular el comportamiento del sistema `top`, la selección dinámica de registros, las operaciones de la ALU y la transmisión serial al display TM1637.

```verilog
`timescale 1ns / 1ps

module tb_top_lab03;

    // Señales de entrada (estímulos)
    reg        clk;
    reg  [3:0] sw;
    reg        btn2;
    reg        btn3;

    // Señales de salida (monitoreo)
    wire [3:0] led;
    wire       clk_display;
    wire       dio_display;

    // Instanciación de la Unidad Bajo Prueba (UUT)
    top uut (
        .clk         (clk),
        .sw          (sw),
        .btn2        (btn2),
        .btn3        (btn3),
        .led         (led),
        .clk_display (clk_display),
        .dio_display (dio_display)
    );

    // Generación de reloj de 125 MHz (período = 8ns)
    always #4 clk = ~clk;

    initial begin
        // Generación de archivo VCD para visualización en GTKWave / EDA Playground
        $dumpfile("sim/tb_top_lab03.vcd");
        $dumpvars(0, tb_top_lab03);

        // 1. Inicialización de señales
        clk  = 1'b0;
        sw   = 4'b0000;
        btn2 = 1'b0;
        btn3 = 1'b0;

        #40;

        // Registros iniciales en top.v: R0=3, R1=5, R2=10(A), R3=15(F)
        // Combinación inicial (index 0): Pareja (R0, R1) -> A=3, B=5

        // 2. Probar ALU: Operación Suma (opcode = 000) -> 3 + 5 = 8
        sw = 4'b0000; 
        #40;
        // Ejecutar y latch en Display (pulso en btn3)
        btn3 = 1'b1; #40; btn3 = 1'b0; #40;

        #1000;

        // 3. Probar ALU: Operación OR bit a bit (opcode = 011) -> 3 | 5 = 7
        sw = 4'b0011; 
        #40;
        btn3 = 1'b1; #40; btn3 = 1'b0; #40;

        #1000;

        // 4. Cambiar a la siguiente combinación de registros (R0, R2) usando btn2
        // A = R0 (3), B = R2 (10 / 0xA)
        btn2 = 1'b1; #40; btn2 = 1'b0; #40;

        // Probar ALU: Suma 3 + 10 = 13 (0xD)
        sw = 4'b0000; 
        #40;
        btn3 = 1'b1; #40; btn3 = 1'b0; #40;

        #200000; // Tiempo suficiente para observar el protocolo serial del TM1637

        $finish;
    end

endmodule

## 2. Archivo de Restricciones (`constraints/zybo_z7.xdc`)

Archivo de asignación de pines y estándares de voltaje para la placa Digilent Zybo Z7.

```xdc
# ------------------------------------------------------------------------------
# Reloj principal del sistema (125 MHz)
# ------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];

# ------------------------------------------------------------------------------
# Interruptores de deslizamiento (SW[3:0])
# SW[2:0]: Opcode de la ALU | SW[3]: Libre / Reservado
# ------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { sw[0] }];
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }];
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }];
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }];

# ------------------------------------------------------------------------------
# Pulsadores (Buttons)
# BTN2: Selección de combinación | BTN3: Ejecutar y Latch en Display
# ------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { btn2 }];
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { btn3 }];

# ------------------------------------------------------------------------------
# LEDs Verdes (LED[3:0]) - Indicadores de Registros Activos
# ------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { led[3] }];

# ------------------------------------------------------------------------------
# Conector Pmod JA - Display TM1637
# JA[0] -> CLK | JA[1] -> DIO
# ------------------------------------------------------------------------------
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { clk_display }];
set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { dio_display }];

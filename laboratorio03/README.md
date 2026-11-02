# Laboratorio 03 - ALU + Banco de Registros + Diseño Modular

### NOMBRES PARTICIPANTES

- Jhohan Stiven Rodríguez Rodríguez
- Alejandro Brandon Prieto León
- Ángel Alirio Rivera Amortegui

## 1. Código Fuente de los Módulos (`src/`)

El sistema modular está dividido en unidades funcionales independientes encargadas del procesamiento aritmético, la selección dinámica de operandos, la gestión del banco de registros y el protocolo de visualización.

### 1.1. Unidad Aritmético Lógica (`src/alu.v`)

Módulo combinacional puro encargada de ejecutar las operaciones aritméticas y lógicas seleccionadas mediante la señal `opcode[2:0]`.

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
            3'b01:  result = ~A;          // NOT en Operando A
            3'b110:  result = A << 1;      // Desplazamiento lógico izquierda (Shift Left)
            3'b111:  result = A >> 1;      // Desplazamiento lógico derecha (Shift Right)
            default: result = 4'b0000;     // Estado por defecto de seguridad
        endcase
    end

endmodule

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

    // 2. LÓGICA COMBINACIONAL: Mapeo de índice a direcciones y LEDs
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


## Archivo `top.v`

// top.v
`timescale 1ns / 1ps

module top (
    input  wire       clk,          // Reloj de 125 MHz (Zybo Z7)
    input  wire [3:0] BTN,          // BTN0=SelReg, BTN1=Write, BTN2=NextComb, BTN3=Exec
    input  wire [3:0] SW,           // Entradas por interruptores (Datos / Opcode)
    output wire [3:0] LED,          // Indicadores de pareja de registros seleccionada
    output wire       RGB_R, RGB_G, RGB_B, // Indicador LED RGB de registro de escritura
    output wire       clk_display,  // Reloj serial hacia TM1637
    inout  wire       dio_display   // Línea bidireccional de datos TM1637
);

    wire [1:0] read_addr_a, read_addr_b;
    wire [1:0] write_ptr;
    wire [3:0] data_out_a, data_out_b;
    wire [3:0] alu_result;

    // 1. Selector de Combinaciones entre Registros
    comb_selector u_comb_selector (
        .clk(clk),
        .btn_next_comb(BTN[2]),
        .read_addr_a(read_addr_a),
        .read_addr_b(read_addr_b),
        .active_leds(LED)
    );

    // 2. Banco de Registros (4 registros x 4 bits)
    reg_bank u_reg_bank (
        .clk(clk),
        .write_enable(BTN[1]),
        .btn_sel_reg(BTN[0]),
        .data_in(SW[3:0]),
        .read_addr_a(read_addr_a),
        .read_addr_b(read_addr_b),
        .data_out_a(data_out_a),
        .data_out_b(data_out_b),
        .write_ptr(write_ptr)
    );

    // 3. Unidad Lógico Aritmética (ALU)
    alu u_alu (
        .A(data_out_a),
        .B(data_out_b),
        .opcode(SW[2:0]),
        .result(alu_result)
    );

    // 4. Controlador de Pantalla TM1637 con Latch de actualización
    display_tm1637 u_display (
        .clk(clk),
        .btn_exec(BTN[3]),
        .alu_result(alu_result),
        .clk_display(clk_display),
        .dio_display(dio_display)
    );

    // Mapeo visual LED RGB según el registro de escritura activo (write_ptr)
    assign RGB_R = (write_ptr == 2'b00) || (write_ptr == 2'b11);
    assign RGB_G = (write_ptr == 2'b01) || (write_ptr == 2'b11);
    assign RGB_B = (write_ptr == 2'b10);

endmodule

## Testbench completo (`tb_top_lab03.v`)

// testbench/tb_top_lab03.v
`timescale 1ns / 1ps

module tb_top_lab03;

    reg        clk;
    reg  [3:0] BTN;
    reg  [3:0] SW;
    wire [3:0] LED;
    wire       RGB_R, RGB_G, RGB_B;
    wire       clk_display;
    wire       dio_display;

    // Instanciación de la UUT (Unit Under Test)
    top uut (
        .clk(clk),
        .BTN(BTN),
        .SW(SW),
        .LED(LED),
        .RGB_R(RGB_R),
        .RGB_G(RGB_G),
        .RGB_B(RGB_B),
        .clk_display(clk_display),
        .dio_display(dio_display)
    );

    // Generación de reloj de 125 MHz (período = 8ns)
    always #4 clk = ~clk;

    initial begin
        // Generación de archivo VCD obligatorio para simulación GTKWave
        $dumpfile("sim/tb_top_lab03.vcd");
        $dumpvars(0, tb_top_lab03);

        // Inicialización de señales
        clk = 0;
        BTN = 4'b0000;
        SW  = 4'b0000;

        #40;

        // 1. Carga de datos en los registros
        // Cargar R0 = 5 (SW=5, BTN[1] pulso)
        SW = 4'd5; #40; BTN[1] = 1; #40; BTN[1] = 0; #40;

        // Seleccionar R1 (BTN[0] pulso) y Cargar R1 = 3
        BTN[0] = 1; #40; BTN[0] = 0; #40;
        SW = 4'd3; #40; BTN[1] = 1; #40; BTN[1] = 0; #40;

        // Seleccionar R2 (BTN[0] pulso) y Cargar R2 = 8
        BTN[0] = 1; #40; BTN[0] = 0; #40;
        SW = 4'd8; #40; BTN[1] = 1; #40; BTN[1] = 0; #40;

        // Seleccionar R3 (BTN[0] pulso) y Cargar R3 = 2
        BTN[0] = 1; #40; BTN[0] = 0; #40;
        SW = 4'd2; #40; BTN[1] = 1; #40; BTN[1] = 0; #40;

        // 2. Probar ALU: Operación Suma (opcode = 000) sobre R0 (5) y R1 (3) -> Resultado = 8
        SW = 4'b0000; #40;
        // Ejecutar en Display (BTN[3] pulso)
        BTN[3] = 1; #40; BTN[3] = 0; #40;

        #1000;

        // 3. Probar ALU: Operación Resta (opcode = 001) -> Resultado = 2
        SW = 4'b0001; #40;
        BTN[3] = 1; #40; BTN[3] = 0; #40;

        #1000;

        // 4. Cambiar combinación de registros a (R0, R2) presionando BTN[2]
        BTN[2] = 1; #40; BTN[2] = 0; #40;
        SW = 4'b0000; #40; // Suma 5 + 8 = 13 (0xD)
        BTN[3] = 1; #40; BTN[3] = 0; #40;

        #200000; // Tiempo para observar serialización TM1637

        $finish;
    end

endmodule

## Archivo `.vcd` de simulación
sim/tb_top_laboratorio03.vcd

## Descripción del sistema
Este laboratorio implementa un sistema digital modular sobre la tarjeta de desarrollo Zybo Z7 (FPGA Zynq-7000). El sistema consta de un banco de 4 registros de 4 bits, una Unidad Lógico Aritmética (ALU) parametrizable con 8 operaciones combinacionales, un selector de parejas de registros para su procesamiento y un controlador serie para el módulo de visualización TM1637 (display de 7 segmentos).

## Explicación de la arquitectura modular
El diseño sigue de manera estricta el principio de modularidad en HDL Verilog, interconectando submódulos especializados dentro de un archivo top sin concentrar la lógica combinacional/secuencial en él:

- **`reg_bank.v`**: Almacena 4 datos de 4 bits (R0 a R3). Permite la selección secuencial del registro objetivo de escritura mediante un botón (`BTN0`) e incrusta el dato enviado por los switches (`SW[3:0]`) al activar el botón de carga (`BTN1`).
- **`comb_selector.v`**: Gestiona las 6 combinaciones posibles entre la pareja de registros leídos $(R_A, R_B)$. Cada pulsación de `BTN2` conmuta a la siguiente pareja habilitando sus respectivas líneas de lectura y encendiendo los LEDs indicadores (`LED[3:0]`).
- **`alu.v`**: Recibe los valores de $R_A$ y $R_B$ seleccionados y calcula la operación definida por la dirección del opcode en los switches (`SW[2:0]`).
- **`display_tm1637.v`**: Implementa el protocolo serie propietario del driver TM1637 a 100 kHz. Retiene el último resultado mediante un mecanismo de latch activado por `BTN3`.
- **`top.v`**: Realiza únicamente el enrutamiento físico y de señales entre los submódulos e interfaces de I/O de la FPGA.

# Laboratorio 03 - ALU + Banco de Registros + Diseño Modular

### NOMBRES PARTICIPANTES

- Jhohan Stiven Rodríguez Rodríguez
- Alejandro Brandon Prieto León
- Ángel Alirio Rivera Amortegui

---

## 1. Código Fuente del Banco de Registros (`src/reg_bank.v`)

Este módulo implementa el almacenamiento secuencial de 4 registros de 4 bits. Al presionar `BTN0` rota el puntero de escritura (`write_ptr`), mientras que `BTN1` guarda el valor de los interruptores `SW[3:0]` en la posición activa. Posee lectura asíncrona de dos puertos (`data_out_a` y `data_out_b`).

### 1.1. Banco de Registros (`src/reg_bank.v`)

```verilog
`timescale 1ns / 1ps

module reg_bank (
    input  wire       clk,          // Reloj principal de la Zybo Z7 (125 MHz)
    input  wire       btn_sel_reg,  // BTN0: Selecciona registro a escribir (R0->R1->R2->R3)
    input  wire       write_enable, // BTN1: Guarda el valor SW[3:0] en el registro activo
    input  wire [3:0] data_in,      // SW[3:0]: Dato de entrada de 4 bits
    input  wire [1:0] read_addr_a,  // Dirección de lectura para Operando A (00=R0 .. 11=R3)
    input  wire [1:0] read_addr_b,  // Dirección de lectura para Operando B (00=R0 .. 11=R3)
    output wire [3:0] data_out_a,   // Dato de salida del Operando A hacia la ALU
    output wire [3:0] data_out_b,   // Dato de salida del Operando B hacia la ALU
    output reg  [1:0] write_ptr     // Dirección del registro seleccionado (0..3) para controlar el LED RGB
);

    // Arreglo de memoria de 4 registros de 4 bits cada uno
    reg [3:0] registers [0:3];

    // Registros auxiliares para detección de flanco de subida en los botones
    reg btn_sel_prev  = 1'b0;
    reg write_en_prev = 1'b0;

    // Inicialización en cero para simulación
    integer i;
    initial begin
        write_ptr = 2'b00;
        for (i = 0; i < 4; i = i + 1) begin
            registers[i] = 4'b0000;
        end
    end

    // LÓGICA SECUENCIAL: Selección de registro y escritura sincronizada con reloj
    always @(posedge clk) begin
        // Actualizar estados previos para los detectores de flanco
        btn_sel_prev  <= btn_sel_reg;
        write_en_prev <= write_enable;

        // 1. Detección de flanco en BTN0: Rotar la dirección de escritura (R0 -> R1 -> R2 -> R3)
        if (btn_sel_reg && !btn_sel_prev) begin
            write_ptr <= write_ptr + 1'b1;
        end

        // 2. Detección de flanco en BTN1: Guardar data_in en el registro activo
        if (write_enable && !write_en_prev) begin
            registers[write_ptr] <= data_in;
        end
    end

    // LÓGICA COMBINACIONAL: Lectura asíncrona continua de operandos
    assign data_out_a = registers[read_addr_a];
    assign data_out_b = registers[read_addr_b];

endmodule
```

### 1.2. Selector Combinacional de Registros (`src/comb_selector.v`)
```
`timescale 1ns / 1ps

module comb_selector (
    input  wire       clk,            // Reloj principal de 125 MHz
    input  wire       btn_next_comb,  // BTN2: Cambia a la siguiente combinación
    output reg  [1:0] read_addr_a,    // Dirección del registro para Operando A (00=R0 .. 11=R3)
    output reg  [1:0] read_addr_b,    // Dirección del registro para Operando B (00=R0 .. 11=R3)
    output reg  [3:0] active_leds     // Salida hacia los LEDs verdes (LED[3:0])
);

    // Contador interno para indexar las 6 combinaciones posibles entre los 4 registros
    reg [2:0] comb_index = 3'b000;
    reg btn_next_prev = 1'b0;

    // 1. LÓGICA SECUENCIAL: Avanzar el contador de combinación con BTN2
    always @(posedge clk) begin
        btn_next_prev <= btn_next_comb;

        // Detección de flanco de subida en BTN2
        if (btn_next_comb && !btn_next_prev) begin
            if (comb_index == 3'd5)
                comb_index <= 3'b000;  // Reinicia al llegar a la última combinación
            else
                comb_index <= comb_index + 1'b1;
        end
    end

    // 2. LÓGICA COMBINACIONAL: Mapeo del índice a las direcciones de lectura y LEDs
    always @(*) begin
        case (comb_index)
            3'd0: begin // Pareja (R0, R1)
                read_addr_a = 2'b00; // Operando A = R0
                read_addr_b = 2'b01; // Operando B = R1
                active_leds = 4'b0011; // LED0 y LED1 encendidos
            end
            3'd1: begin // Pareja (R0, R2)
                read_addr_a = 2'b00; // Operando A = R0
                read_addr_b = 2'b10; // Operando B = R2
                active_leds = 4'b0101; // LED0 y LED2 encendidos
            end
            3'd2: begin // Pareja (R0, R3)
                read_addr_a = 2'b00; // Operando A = R0
                read_addr_b = 2'b11; // Operando B = R3
                active_leds = 4'b1001; // LED0 y LED3 encendidos
            end
            3'd3: begin // Pareja (R1, R2)
                read_addr_a = 2'b01; // Operando A = R1
                read_addr_b = 2'b10; // Operando B = R2
                active_leds = 4'b0110; // LED1 y LED2 encendidos
            end
            3'd4: begin // Pareja (R1, R3)
                read_addr_a = 2'b01; // Operando A = R1
                read_addr_b = 2'b11; // Operando B = R3
                active_leds = 4'b1010; // LED1 y LED3 encendidos
            end
            3'd5: begin // Pareja (R2, R3)
                read_addr_a = 2'b10; // Operando A = R2
                read_addr_b = 2'b11; // Operando B = R3
                active_leds = 4'b1100; // LED2 y LED3 encendidos
            end
            default: begin
                read_addr_a = 2'b00;
                read_addr_b = 2'b01;
                active_leds = 4'b0011;
            end
        endcase
    end

endmodule
```
### 1.3. Unidad Aritmético Lógica (src/alu.v)
```
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
            3'b101:  result = ~A;          // NOT en Operando A
            3'b110:  result = A << 1;      // Desplazamiento lógico izquierda (Shift Left)
            3'b111:  result = A >> 1;      // Desplazamiento lógico derecha (Shift Right)
            default: result = 4'b0000;     // Estado por defecto de seguridad para evitar la inferencia de latches no deseados
        endcase
    end

endmodule
```
### 1.4. Estrategia de Visualización (src/display_tm1637.v)
```
`timescale 1ns / 1ps
// Controlador TM1637 (muestra el resultado de la ALU en el digito 1)
// Todo corre en el reloj de 125 MHz con un "tick" de habilitacion (sin relojes derivados).

module display_tm1637 (
    input  wire       clk,          // 125 MHz
    input  wire       btn_exec,     // BTN3
    input  wire [3:0] alu_result,
    output reg        clk_display = 1'b1,
    inout  wire       dio_display
);

    // ---------------- 1. Latch del resultado con BTN3 ----------------
    reg [1:0] btn_sync = 2'b00;
    reg       btn_prev = 1'b0;
    reg [3:0] latched_result = 4'h0;

    always @(posedge clk) begin
        btn_sync <= {btn_sync[0], btn_exec};   // Sincronizador 2 FF
        btn_prev <= btn_sync[1];
        if (btn_sync[1] && !btn_prev)
            latched_result <= alu_result;
    end

    // ---------------- 2. Decodificador hex -> 7 segmentos ----------------
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

    // ---------------- 3. Tick lento (100 kHz) ----------------
    reg [10:0] tick_cnt = 11'd0;
    wire       tick = (tick_cnt == 11'd1249);
    always @(posedge clk)
        tick_cnt <= tick ? 11'd0 : tick_cnt + 1'b1;

    // ---------------- 4. DIO tri-state ----------------
    reg dio_out = 1'b1;
    reg dio_oe  = 1'b1;
    assign dio_display = dio_oe ? dio_out : 1'bz;

    // ---------------- 5. Maquina de estados ----------------
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
            2'd0:    cur_byte = 8'h44;                       // Comando de datos: MODO DIRECCIÓN FIJA
            2'd1:    cur_byte = 8'hC0;                       // Dirección del Dígito 1 (izquierda)
            2'd2:    cur_byte = seg7_map(latched_result);    // Dato únicamente para el Dígito 1
            default: cur_byte = 8'h8F;                       // Display ON, brillo máximo
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
```

##  2. Archivo top
```
`timescale 1ns / 1ps

module top (
    input  wire       clk,          // Reloj principal de 125 MHz (Pin K17)
    input  wire [3:0] SW,           // Switches SW[3:0] para datos y opcode
    input  wire [3:0] BTN,          // Botones BTN0, BTN1, BTN2, BTN3
    output wire [3:0] LED,          // LEDs verdes LED[3:0]
    output reg        RGB_R,        // Canal Rojo del LED RGB
    output reg        RGB_G,        // Canal Verde del LED RGB
    output reg        RGB_B,        // Canal Azul del LED RGB
    output wire       clk_display,  // Pin CLK del TM1637 (Pmod)
    inout  wire       dio_display   // Pin DIO del TM1637 (Pmod)
);

    // Cables internos de interconexión (Buses de datos y control)
    wire [1:0] write_ptr;
    wire [1:0] read_addr_a;
    wire [1:0] read_addr_b;
    wire [3:0] data_out_a;
    wire [3:0] data_out_b;
    wire [3:0] alu_result;

    // 1. Instancia del Banco de Registros (reg_bank.v)
    reg_bank u_reg_bank (
        .clk          (clk),
        .btn_sel_reg  (BTN[0]),       // BTN0: Seleccionar registro a escribir
        .write_enable (BTN[1]),       // BTN1: Guardar SW[3:0] en registro activo
        .data_in      (SW[3:0]),      // Dato proveniente de los switches
        .read_addr_a  (read_addr_a),  // Dirección del Operando A desde el selector
        .read_addr_b  (read_addr_b),  // Dirección del Operando B desde el selector
        .data_out_a   (data_out_a),   // Dato entregado a la ALU (A)
        .data_out_b   (data_out_b),   // Dato entregado a la ALU (B)
        .write_ptr    (write_ptr)     // Puntero para indicación en LED RGB
    );

    // 2. Instancia del Selector de Combinaciones (comb_selector.v)
    comb_selector u_comb_selector (
        .clk           (clk),
        .btn_next_comb (BTN[2]),       // BTN2: Cambiar pareja de registros (A, B)
        .read_addr_a   (read_addr_a),  // Salida de dirección A
        .read_addr_b   (read_addr_b),  // Salida de dirección B
        .active_leds   (LED[3:0])      // Enciende LEDs de la pareja activa
    );

    // 3. Instancia de la ALU (alu.v)
    alu u_alu (
        .A      (data_out_a),          // Operando A desde el banco de registros
        .B      (data_out_b),          // Operando B desde el banco de registros
        .opcode (SW[2:0]),             // Operación elegida por SW[2:0]
        .result (alu_result)           // Resultado calculated
    );

    // 4. Instancia del Controlador y Retención del Display (display_tm1637.v)
    display_tm1637 u_display (
        .clk         (clk),
        .btn_exec    (BTN[3]),         // BTN3: Ejecuta y congela el resultado
        .alu_result  (alu_result),     // Entrada de resultado desde la ALU
        .clk_display (clk_display),    // Salida hacia la pantalla
        .dio_display (dio_display)     // Salida hacia la pantalla
    );

    // 5. Decodificador visual para el LED RGB según el registro destino (write_ptr)
    always @(*) begin
        case (write_ptr)
            2'b00: begin RGB_R = 1'b1; RGB_G = 1'b0; RGB_B = 1'b0; end // R0 -> Rojo
            2'b01: begin RGB_R = 1'b0; RGB_G = 1'b1; RGB_B = 1'b0; end // R1 -> Verde
            2'b10: begin RGB_R = 1'b0; RGB_G = 1'b0; RGB_B = 1'b1; end // R2 -> Azul
            2'b11: begin RGB_R = 1'b1; RGB_G = 1'b1; RGB_B = 1'b1; end // R3 -> Blanco
            default: begin RGB_R = 1'b0; RGB_G = 1'b0; RGB_B = 1'b0; end
        endcase
    end

endmodule
```
##  3 .Testbench 
```
`timescale 1ns / 1ps

module tb_top;

    // Entradas del Top
    reg        clk;
    reg  [3:0] SW;
    reg  [3:0] BTN;

    // Salidas del Top
    wire [3:0] LED;
    wire       RGB_R;
    wire       RGB_G;
    wire       RGB_B;
    wire       clk_display;
    wire       dio_display;

    // Resistencia de Pull-Up en la línea bidireccional dio_display
    pullup(dio_display);

    // Instancia del módulo top
    top uut (
        .clk         (clk),
        .SW          (SW),
        .BTN         (BTN),
        .LED         (LED),
        .RGB_R       (RGB_R),
        .RGB_G       (RGB_G),
        .RGB_B       (RGB_B),
        .clk_display (clk_display),
        .dio_display (dio_display)
    );

    // Generación del reloj principal de 125 MHz (Periodo de 8 ns)
    always #4 clk = ~clk;

    initial begin
        // Configuración para guardar ondas en VCD
        $dumpfile("sim.vcd");
        $dumpvars(0, tb_top);

        // 1. Estado inicial
        clk = 1'b0;
        SW  = 4'b0000;
        BTN = 4'b0000;

        #100;

        // PASO 1: Cargar dato en el Registro 0 (R0 = 5)
        $display("Guardando valor 5 en Registro 0...");
        SW = 4'b0101;      // Valor 5
        #50; BTN[1] = 1'b1;
        #100; BTN[1] = 1'b0;
        #100;

        // PASO 2: Seleccionar Registro 1 e ingresar dato (R1 = 3)
        $display("Cambiando al Registro 1...");
        BTN[0] = 1'b1; #100; BTN[0] = 1'b0; #100;

        $display("Guardando valor 3 en Registro 1...");
        SW = 4'b0011;      // Valor 3
        BTN[1] = 1'b1; #100; BTN[1] = 1'b0; #100;

        // PASO 3: Seleccionar combinación de registros (A y B)
        $display("Seleccionando parejas de registros con BTN[2]...");
        BTN[2] = 1'b1; #100; BTN[2] = 1'b0; #100;

        // PASO 4: Configurar Opcode en SW[2:0] (SUMA = 3'b000)
        $display("Seleccionando Operacion en ALU (SW[2:0])...");
        SW = 4'b0000; // SUMA
        #200;

        // PASO 5: Ejecutar y transmitir al Display TM1637 (BTN[3])
        $display("Presionando BTN[3] (btn_exec) para iniciar la transmisión...");
        BTN[3] = 1'b1; #100; BTN[3] = 1'b0;

        #2500000; // Espera para simulación

        $display("Simulacion completada exitosamente.");
        $finish;
    end

endmodule
```
##  4. Archivo .vcd
```
En esta sección se detalla la configuración utilizada para la generación del archivo de simulación de ondas `.vcd` (Value Change Dump), el cual permite auditar el comportamiento temporal de las señales en GTKWave.

El archivo de volcado generado durante la simulación se almacena en la raíz del proyecto bajo el nombre:
- `laboratorio03.vcd` (o `sim.vcd`)

Dentro del módulo de prueba (`tb_top_lab03.v`), la directiva encargada de instanciar la creación de dicho archivo es:

```verilog
initial begin
    $dumpfile("laboratorio03.vcd");
    $dumpvars(0, tb_top_lab03);
end
```
# Descripción del sistema
El presente proyecto implementa un sistema digital modular en la tarjeta FPGA Digilent Zybo Z7 (basada en el SoC Zynq-7000). El sistema permite procesar datos de 4 bits mediante una Unidad Aritmético Lógica (ALU) e inspeccionar sus resultados en un display de 7 segmentos de 4 dígitos controlado por el chip TM1637.

El flujo de funcionamiento del sistema integra los siguientes componentes:
- **Banco de Registros:** Un bloque de memoria interna secuencial de 4 posiciones ($R0$ a $R3$) de 4 bits cada una. Incluye un indicador de estado en un LED RGB que cambia de color según el registro seleccionado para escritura ($R0$: Rojo, $R1$: Verde, $R2$: Azul, $R3$: Blanco).
- **Selector Combinacional de Registros:** Un módulo secuencial/combinacional que, al pulsar `BTN2`, avanza a través de 6 combinaciones prefijadas de parejas de operandos ($A$ y $B$) y retroalimenta los LEDs verdes (`LED[3:0]`) para indicar visualmente los registros activos.
- **Unidad Aritmético Lógica (ALU):** Un módulo combinacional puro que ejecuta 8 operaciones distintas (sumas, restas, operaciones lógicas AND/OR/XOR/NOT y desplazamientos a la izquierda y derecha) seleccionadas mediante los switches `SW[2:0]`.
- **Controlador de Visualización TM1637:** Un subsistema encargado de congelar (*latch*) el resultado de la ALU al presionar `BTN3` y transmitirlo de forma serial mediante un protocolo propietario de 2 hilos (`CLK` y `DIO` bidireccional) al display externo.

---

# Explicación de la arquitectura modular
La arquitectura del proyecto adopta un diseño estrictamente modular y jerárquico descrita en Verilog HDL. Las responsabilidades de cada módulo en la carpeta `src/` se dividen de la siguiente manera:

1. **`reg_bank.v` (Banco de Registros):**
   - **Lógica Secuencial:** Registra escrituras síncronas en el flanco de subida de `clk` (125 MHz). Al detectar un flanco positivo en `BTN0`, incrementa el puntero de escritura `write_ptr` ($0 \rightarrow 1 \rightarrow 2 \rightarrow 3 \rightarrow 0$). Al presionar `BTN1`, guarda el bus de entrada `SW[3:0]` en el registro apuntado.
   - **Lógica Combinacional:** Implementa una lectura asíncrona permanente de dos puertos independientes (`data_out_a` y `data_out_b`) a partir de las direcciones enviadas por el selector.

2. **`comb_selector.v` (Selector de Registros):**
   - Mantiene un contador interno (`comb_index`) de 0 a 5 que avanza al presionar `BTN2` con detección de flanco de subida.
   - Decodifica combinacionalmente el índice actual para asignar las direcciones de lectura (`read_addr_a` y `read_addr_b`) hacia el banco de registros, activando simultáneamente la máscara de LEDs verdes correspondiente a la pareja en uso.

3. **`alu.v` (Unidad Aritmético Lógica):**
   - Corresponde a un bloque puramente combinacional evaluado en un bloque `always @(*)`.
   - Según el valor en `opcode[2:0]`, selecciona en un bloque `case` la operación matemática o lógica a ejecutar entre los operandos `A` y `B`, entregando el bus `result` de 4 bits sin generar latches involuntarios gracias a su cláusula `default`.

4. **`display_tm1637.v` (Controlador de Pantalla):**
   - Aísla la temporización rápida de la FPGA respecto al display mediante un divisor de reloj por *tick* (100 kHz).
   - Administra la interfaz serial a través de una Máquina de Estados Finitos (FSM) que gestiona el protocolo serie y la línea de datos tri-state (`dio_display`).

5. **`top.v` (Módulo Principal / Top-Level):**
   - Actúa como la entidad superior (*wrapper*) que instancia e interconecta los buses internos entre `reg_bank`, `comb_selector`, `alu` y `display_tm1637`.
   - Contiene el decodificador de color para el LED RGB según el registro de escritura activo y asigna directamente las señales físicas a los pines de la FPGA Zybo Z7 descritos en el archivo `.xdc`.

---
# Descripción de la estrategia de visualización utilizada
El controlador del display TM1637 resuelve el reto de conectar un circuito digital de alta velocidad (125 MHz) con un periférico serial lento usando dos técnicas principales:

1. **Mecanismo de Retención (*Latch*) por Pulsador:**
   - Para evitar que la pantalla cambie constantemente durante la manipulación de switches o la selección de registros, el módulo incluye un sincronizador de dos flip-flops (`btn_sync`) y un detector de flanco ascendente sobre el botón de ejecución (`BTN3`).
   - Solo cuando se presiona `BTN3`, el resultado actual de la ALU (`alu_result`) se almacena en el registro interno `latched_result`, manteniendo una lectura estable en el display.

2. **Generación de Temporización por Tick (100 kHz):**
   - En lugar de usar relojes derivados (*gated clocks*) que producen problemas de *skew* y *timing* en síntesis, el módulo utiliza un contador síncrono `tick_cnt` que genera un pulso de habilitación (*tick*) cada 1250 ciclos del reloj del sistema ($125 \text{ MHz} / 1250 = 100 \text{ kHz}$).

3. **Máquina de Estados Finitos (FSM) y Línea Bidireccional Tri-State:**
   - La transmisión serial se estructura mediante una FSM de 12 estados (`S_START0` a `S_STOP2`).
   - La FSM genera las condiciones de inicio (START) y parada (STOP) del protocolo TM1637, conmuta la señal de reloj serie (`clk_display`) y desplaza el byte de datos bit por bit (LSB primero).
   - Para la línea de datos `dio_display`, se utiliza una salida con control de alta impedancia (Tri-state):
     ```verilog
     assign dio_display = dio_oe ? dio_out : 1'bz;
     ```
     Durante el noveno pulso de reloj (`S_ACK_REL`), la FPGA deshabilita su buffer de salida (`dio_oe = 0`), liberando la línea para permitir recibir la señal de confirmación (ACK) enviada por el chip TM1637 antes de finalizar la trama.
   - Los valores hexadecimales de 4 bits retenidos se convierten mediante una función decodificadora (`seg7_map`) a su representación de 7 segmentos equivalente para su correcto dibujado en el dígito de la pantalla.
# Capturas de GTKWave
# Evidencia de funcionamiento en FPGA
# Análisis de resultados

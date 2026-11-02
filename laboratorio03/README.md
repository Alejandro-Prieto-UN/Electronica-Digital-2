# Laboratorio 03 - ALU + Banco de Registros + Diseño Modular

### NOMBRES PARTICIPANTES

- Jhohan Stiven Rodríguez Rodríguez
- Alejandro Brandon Prieto León
- Ángel Alirio Rivera Amortegui

---

## 1. Descripción del Sistema

El presente laboratorio implementa un sistema digital modular en la tarjeta FPGA Digilent Zybo Z7. El sistema integra:
- Un **Banco de Registros** interno de 4 posiciones ($R0$ a $R3$) de 4 bits cada uno, con un indicador dinámico visual a través de un LED RGB.
- Un **Selector Combinacional de Registros** que rota mediante el pulsador `BTN2` entre 6 parejas posibles de operandos ($A$ y $B$), encendiendo los LEDs verdes correspondientes.
- Una **Unidad Aritmético Lógica (ALU)** de 4 bits capaz de realizar 8 operaciones (aritméticas y lógicas) seleccionadas mediante los interruptores `SW[2:0]`.
- Un **Controlador de Visualización TM1637** que retiene (*latch*) y transmite de forma serial síncrona el resultado de la ALU hacia la pantalla tras presionar el pulsador `BTN3`.

---

## 2. Explicación de la Arquitectura Modular

La arquitectura del sistema está organizada en módulos independientes e interconectados descritos en Verilog HDL dentro de la carpeta `src/`.

### 2.1. Código Fuente del Banco de Registros (`src/reg_bank.v`)

Este módulo implementa el almacenamiento secuencial de 4 registros de 4 bits. Al presionar `BTN0` rota el puntero de escritura (`write_ptr`), mientras que `BTN1` guarda el valor de los switches `SW[3:0]` en la posición activa. Posee lectura asíncrona de dos puertos (`data_out_a` y `data_out_b`).
### 2.1. Banco de Registros (`src/reg_bank.v`)

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

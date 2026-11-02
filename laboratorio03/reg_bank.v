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
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
            3'b010: result = A & B;       // AND bit a bit
            3'b011:  result = A | B;       // OR bit a bit
            3'b100:  result = A ^ B;       // XOR bit a bit
            3'b101:  result = ~A;          // NOT en Operando A
            3'b110:  result = A << 1;      // Desplazamiento lógico izquierda (Shift Left)
            3'b111:  result = A >> 1;      // Desplazamiento lógico derecha (Shift Right)
            default: result = 4'b0000;     // Estado por defecto de seguridad para evitar la inferencia de latches no deseados
        endcase
    end

endmodule
`timescale 1ns / 1ps

module alu (
    input  wire [3:0] A,        // Operando A (4 bits)
    input  wire [3:0] B,        // Operando B (4 bits)
    input  wire [1:0] opcode,   // Código de operación (2 bits)
    output reg  [3:0] result    // Resultado de la operación (4 bits)
);

    // Lógica combinacional pura para la ALU
    always @(*) begin
        case (opcode)
            2'b00:  result = A + B;       // Suma
            2'b01:  result = A - B;       // Resta
            2'b10:  result = A & B;       // AND bit a bit
            2'b11:  result = A | B;       // OR bit a bit
            default: result = 4'b0000;
        endcase
    end

endmodule
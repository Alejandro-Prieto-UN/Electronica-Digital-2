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
    inout  wire       dio_display   //
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
        .result (alu_result)           // Resultado calculado
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
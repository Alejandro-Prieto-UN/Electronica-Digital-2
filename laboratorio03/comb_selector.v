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
`timescale 1ns / 1ps

module top_lab02 (
    input  wire       clk,      // Reloj de 125 MHz de la Zybo Z7 (Pin H16)
    input  wire [3:0] SW,       // Switches SW0 - SW3 (Bus de datos)
    input  wire [3:0] BTN,      // Botones BTN0 - BTN3
    output wire [3:0] LED,      // LEDs verdes LED0 - LED3 (Resultado)
    output reg        RGB_R,    // LED RGB canal Rojo
    output reg        RGB_G,    // LED RGB canal Verde
    output reg        RGB_B     // LED RGB canal Azul
);

    // Registros de almacenamiento para el Datapath
    reg [3:0] A = 4'b0000;
    reg [3:0] B = 4'b0000;
    reg [1:0] opcode = 2'b00;

    // Registros auxiliares para detección de flanco en BTN2 y BTN3
    reg btn2_prev = 1'b0;
    reg btn3_prev = 1'b0;

    // 1. LÓGICA SECUENCIAL: Captura y almacenamiento en Flip-Flops
    always @(posedge clk) begin
        // Cargar Operando A al presionar BTN0
        if (BTN[0]) begin
            A <= SW;
        end

        // Cargar Operando B al presionar BTN1
        if (BTN[1]) begin
            B <= SW;
        end

        // Detectar flanco de subida en BTN2 para alternar opcode[0]
        btn2_prev <= BTN[2];
        if (BTN[2] && !btn2_prev) begin
            opcode[0] <= ~opcode[0];
        end

        // Detectar flanco de subida en BTN3 para alternar opcode[1]
        btn3_prev <= BTN[3];
        if (BTN[3] && !btn3_prev) begin
            opcode[1] <= ~opcode[1];
        end
    end

    // 2. INSTANCIACIÓN DE LA ALU (Conexión modular)
    alu alu_inst (
        .A(A),
        .B(B),
        .opcode(opcode),
        .result(LED)
    );

    // 3. CONTROL DEL LED RGB SEGÚN EL OPCODE ALMACENADO
    always @(*) begin
        case (opcode)
            2'b00: begin // Suma: Verde
                RGB_R = 1'b0;
                RGB_G = 1'b1;
                RGB_B = 1'b0;
            end
            2'b01: begin // Resta: Rojo
                RGB_R = 1'b1;
                RGB_G = 1'b0;
                RGB_B = 1'b0;
            end
            2 'b10: begin // AND: Azul
                RGB_R = 1'b0;
                RGB_G = 1'b0;
                RGB_B = 1'b1;
            end
            2'b11: begin // OR: Amarillo (Rojo + Verde)
                RGB_R = 1'b1;
                RGB_G = 1'b1;
                RGB_B = 1'b0;
            end
            default: begin
                RGB_R = 1'b0;
                RGB_G = 1'b0;
                RGB_B = 1'b0;
            end
        endcase
    end

endmodule
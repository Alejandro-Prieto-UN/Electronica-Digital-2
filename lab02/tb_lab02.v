//iverilog -o sim_lab02.vvp alu.v top_lab02.v tb_lab02.v
//vvp sim_lab02.vvp
//gtkwave waveform_lab02.vcd

`timescale 1ns / 1ps

module tb_lab02;

    reg        clk;
    reg  [3:0] SW;
    reg  [3:0] BTN;

    wire [3:0] LED;
    wire       RGB_R;
    wire       RGB_G;
    wire       RGB_B;

    // Instancia de la Unidad Bajo Prueba (UUT)
    top_lab02 uut (
        .clk(clk),
        .SW(SW),
        .BTN(BTN),
        .LED(LED),
        .RGB_R(RGB_R),
        .RGB_G(RGB_G),
        .RGB_B(RGB_B)
    );

    // Reloj de 125 MHz (Período = 8ns, conmuta cada 4ns)
    always #4 clk = ~clk;

    initial begin
        // Creación del archivo de ondas para GTKWave
        $dumpfile("waveform_lab02.vcd");
        $dumpvars(0, tb_lab02);

        // Estado inicial
        clk = 0;
        SW  = 4'b0000;
        BTN = 4'b0000;
        #20;

        // --- PASO 1: Cargar Operando A = 9 (4'b1001) ---
        SW = 4'b1001;
        #10;
        BTN[0] = 1; // Presionar BTN0
        #16;
        BTN[0] = 0; // Soltar BTN0 (A queda almacenado en 9)
        #20;

        // --- PASO 2: Cargar Operando B = 3 (4'b0011) ---
        SW = 4'b0011;
        #10;
        BTN[1] = 1; // Presionar BTN1
        #16;
        BTN[1] = 0; // Soltar BTN1 (B queda almacenado en 3)
        #20;

        // Limpiar bus de switches para probar la persistencia de A y B
        SW = 4'b0000;
        #20;

        // Opcode actual = 00 (Suma: 9 + 3 = 12 -> LED = 4'b1100, RGB = Verde)

        // --- PASO 3: Cambiar a Opcode 01 (Resta) ---
        BTN[2] = 1; // Presionar BTN2 para alternar opcode[0]
        #16;
        BTN[2] = 0; // Soltar BTN2 (Opcode = 01, Resta: 9 - 3 = 6 -> LED = 4'b0110, RGB = Rojo)
        #30;

        // --- PASO 4: Cambiar a Opcode 11 (OR) ---
        BTN[3] = 1; // Presionar BTN3 para alternar opcode[1]
        #16;
        BTN[3] = 0; // Soltar BTN3 (Opcode = 11, OR: 9 | 3 = 11 -> LED = 4'b1011, RGB = Amarillo)
        #30;

        // --- PASO 5: Cambiar a Opcode 10 (AND) ---
        BTN[2] = 1; // Presionar BTN2 para alternar opcode[0]
        #16;
        BTN[2] = 0; // Soltar BTN2 (Opcode = 10, AND: 9 & 3 = 1 -> LED = 4'b0001, RGB = Azul)
        #30;

        $finish;
    end

endmodule
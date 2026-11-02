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

        // =========================================================
        // PASO 1: Cargar dato en el Registro 0 (R0 = 5)
        // =========================================================
        $display("Guardando valor 5 en Registro 0...");
        SW = 4'b0101;      // Valor 5
        
        // Pulso en BTN[1] (write_enable) para guardar
        #50; BTN[1] = 1'b1;
        #100; BTN[1] = 1'b0;
        #100;

        // =========================================================
        // PASO 2: Seleccionar Registro 1 e ingresar dato (R1 = 3)
        // =========================================================
        $display("Cambiando al Registro 1...");
        // Pulso en BTN[0] (btn_sel_reg) para avanzar de registro
        BTN[0] = 1'b1; #100; BTN[0] = 1'b0; #100;

        $display("Guardando valor 3 en Registro 1...");
        SW = 4'b0011;      // Valor 3
        
        // Pulso en BTN[1] para escribir en R1
        BTN[1] = 1'b1; #100; BTN[1] = 1'b0; #100;

        // =========================================================
        // PASO 3: Seleccionar combinación de registros (A y B)
        // =========================================================
        $display("Seleccionando parejas de registros con BTN[2]...");
        BTN[2] = 1'b1; #100; BTN[2] = 1'b0; #100;

        // =========================================================
        // PASO 4: Configurar Opcode en SW[2:0] (Ej. SUMA = 3'b000)
        // =========================================================
        $display("Seleccionando Operacion en ALU (SW[2:0])...");
        SW = 4'b0000; // SW[2:0] = 000 (SUMA)
        #200;

        // =========================================================
        // PASO 5: Ejecutar y transmitir al Display TM1637 (BTN[3])
        // =========================================================
        $display("Presionando BTN[3] (btn_exec) para iniciar la transmisión...");
        BTN[3] = 1'b1; #100; BTN[3] = 1'b0;

        // Espera de 2.5 ms para dar tiempo a completar el envío serie al TM1637
        $display("Simulando envio de datos al TM1637...");
        #2500000;

        $display("Simulacion completada exitosamente.");
        #50000000; // Extender la simulación a 50 us (50,000,000 ps)
        $finish;
    end

endmodule
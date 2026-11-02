`timescale 1ns / 1ps
//iverilog -o sim_display.out display.v tb_display.v
//vvp sim_display.out
//gtkwave display_sim.vcd

module tb_display;

    // Entradas al módulo
    reg clk;
    reg btn_exec;
    reg [3:0] alu_result;

    // Salidas del módulo
    wire clk_display;
    wire dio_display;

    // Instanciación del Módulo
    display uut (
        .clk(clk),
        .btn_exec(btn_exec),
        .alu_result(alu_result),
        .clk_display(clk_display),
        .dio_display(dio_display)
    );

    // Reloj principal (125 MHz)
    initial begin
        clk = 0;
        forever #4 clk = ~clk;
    end

    // Bloque de Estímulos y Generación para GTKWave
    initial begin
        $dumpfile("display_sim.vcd");
        $dumpvars(0, tb_display);

        // Condiciones iniciales
        btn_exec = 0;
        alu_result = 4'b0000;

        // Esperar 100 ns
        #100;

        // --- PRUEBA 1: Mostrar el resultado 13 (Hex: D) ---
        alu_result = 4'b1101; // 13 en binario
        #50;

        // Simular la pulsación del botón BTN3
        btn_exec = 1;
        #20;
        btn_exec = 0;

        // Esperar a que toda la transmisión serial ocurra
        #500000; // 500 microsegundos

        // --- PRUEBA 2: Mostrar el resultado 5 ---
        alu_result = 4'b0101; // 5 en binario
        #50;
        
        // Simular otra pulsación del botón
        btn_exec = 1;
        #20;
        btn_exec = 0;

        // Esperar a que toda la transmisión serial ocurra
        #50000000; // 500 microsegundos

        // Detener la simulación
        $finish;
    end

endmodule
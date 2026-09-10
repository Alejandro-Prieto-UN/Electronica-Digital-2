//timepo 1ns y presicion 1ps
`timescale 1ns/1ps

module tb_acumulador;

    reg clk;
    reg rst;
    reg start;
    reg [3:0] x;
    reg [1:0] modo;

    wire [5:0] acc;
    wire done;

    // Instancia del acumulador
    acumulador dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .x(x),
        .modo(modo),
        .acc(acc),
        .done(done)
    );

    // Inicia
    initial begin
        clk = 1'b0;
        rst = 1'b1;
        start = 1'b0;
        x = 4'd3;
        modo = 2'd0;

        #12;
        rst = 1'b0;
    end

    // Reloj: período de 10 ns
    always #5 clk = ~clk;

    // Genera el archivo VCD
    initial begin
        $dumpfile("acumulador.vcd");
        $dumpvars(0, tb_acumulador);
    end

   // Prueba de las tres opciones
    initial begin

        // OPCIÓN 1: SUMAR X 3 VECES

        @(negedge clk);
        modo = 2'd0;
        start = 1'b1;

        @(negedge clk);
        start = 1'b0;

        wait(done == 1'b1);
        @(negedge clk);
        @(negedge clk);

        // OPCIÓN 2: SUMAR X 4 VECES

        modo = 2'd1;
        start = 1'b1;

        @(negedge clk);
        start = 1'b0;

        wait(done == 1'b1);
        @(negedge clk);
        @(negedge clk);

        // OPCIÓN 3: SUMAR X HASTA NO SUPERAR 20

        modo = 2'd2;
        start = 1'b1;

        @(negedge clk);
        start = 1'b0;

        wait(done == 1'b1);
        @(negedge clk);
        @(negedge clk);

        $finish;
    end

    // Mostrar resultados en la terminal
    initial begin
        $monitor("Tiempo = %0t ns | rst = %b | start = %b | x = %d | modo = %d | acc = %d | done = %b",
                 $time, rst, start, x, modo, acc, done);
    end

endmodule
`timescale 1ns/1ps

module tb_transmisor;

    reg clk;
    reg rst;
    reg start;
    reg [7:0] data_in;

    wire tx;
    wire busy;
    wire done;

    // Instancia del transmisor
    transmisor #(
        .CLKS_PER_BIT(8)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_in(data_in),
        .tx(tx),
        .busy(busy),
        .done(done)
    );

    // Generación del reloj
    always #5 clk = ~clk;

    // Generación del VCD
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_transmisor);
    end

    // Estímulos
    initial begin

        // Valores iniciales
        clk     = 1'b0;
        rst     = 1'b1;
        start   = 1'b0;
        data_in = 8'h00;

        // Mantener reset durante un tiempo
        #12;
        rst = 1'b0;

        // PRIMERA TRANSMISIÓN: A5
        data_in = 8'hA5; // A5 en binario es 10100101

        @(negedge clk);
        start = 1'b1;

        @(negedge clk);
        start = 1'b0;

        // Esperar a que termine
        wait(done == 1'b1);

        // Esperar un poco antes de la siguiente transmisión
        @(negedge clk);
        @(negedge clk);

        // SEGUNDA TRANSMISIÓN: 3C
        data_in = 8'h3C; //3Cen binario es 00111100

        @(negedge clk);
        start = 1'b1;

        @(negedge clk);
        start = 1'b0;

        // Esperar a que termine
        wait(done == 1'b1);

        // Terminar simulación
        @(negedge clk);
        $finish;

    end

    // Mostrar registros en cada ciclo de reloj
    always @(posedge clk) begin
        #1;
        $display(
            "Tiempo = %0.1f ns | state = %b | tick_cnt = %0d | bit_count = %0d | shift_reg = %02h | tx = %b | busy = %b | done = %b",
            $realtime,
            dut.state,
            dut.tick_cnt,
            dut.bit_count,
            dut.shift_reg,
            tx,
            busy,
            done
        );
    end

endmodule
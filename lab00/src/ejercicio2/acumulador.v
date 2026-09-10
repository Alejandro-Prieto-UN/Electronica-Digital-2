
//COMPILAR: iverilog -g2012 -o src/ejercicio2/acumulador.vvp src/ejercicio2/acumulador.v src/ejercicio2/tb_acumulador.v
//EJECUTAR: vvp src/ejercicio2/acumulador.vvp
//GTKwave: gtkwave src/ejercicio2/acumulador.vcd

module acumulador (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire [3:0] x,
    input  wire [1:0] modo, //selecciona una de las opciones
    output reg  [5:0] acc,
    output reg        done
);

    // Estados de la FSM
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        LOAD = 2'b01,
        ADD  = 2'b10,
        DONE = 2'b11
    } estado_t;

    // Estado actual y siguiente
    estado_t estado_actual;
    estado_t estado_siguiente;

    // Contador de sumas realizadas
    reg [2:0] contador;


    // Registro de estado y datapath
    always @(posedge clk or posedge rst) begin

        if (rst) begin
            estado_actual <= IDLE;
            acc <= 6'd0;
            contador <= 3'd0;

        end else begin

            estado_actual <= estado_siguiente;

            case (estado_actual) //revisa en que estado estoy

                LOAD: begin
                    acc <= 6'd0;
                    contador <= 3'd0;
                end

                ADD: begin

                    // Modo 0: sumar x 3 veces
                    if (modo == 2'd0) begin
                        acc <= acc + x;
                        contador <= contador + 3'd1;
                    end

                    // Modo 1: sumar x 4 veces
                    else if (modo == 2'd1) begin
                        acc <= acc + x;
                        contador <= contador + 3'd1;
                    end
                    
                    // Modo 2: sumar x mientras no supere 20
                    else if (modo == 2'd2) begin
                        if (acc + x <= 20) begin
                            acc <= acc + x;
                            contador <= contador + 3'd1;
                        end
                    end

                end

                default: begin
                end

            endcase
        end
    end


    // Lógica de siguiente estado
    always @(*) begin

        // Por defecto, permanecer en el estado actual
        estado_siguiente = estado_actual;

        case (estado_actual)

            IDLE: begin
                if (start)
                    estado_siguiente = LOAD;
            end

            LOAD: begin
                estado_siguiente = ADD;
            end

            ADD: begin

                // Modo 0: terminar después de 3 sumas
                if (modo == 2'd0) begin
                    if (contador == 3'd2)
                        estado_siguiente = DONE;
                end

                // Modo 1: terminar después de 4 sumas
                else if (modo == 2'd1) begin
                    if (contador == 3'd3)
                        estado_siguiente = DONE;
                end

                // Modo 2: terminar cuando la siguiente suma fuera mayor que 20
                else if (modo == 2'd2) begin
                    if (acc + x > 20)
                        estado_siguiente = DONE;
                end

            end

            DONE: begin
                estado_siguiente = IDLE;
            end

            default: begin
                estado_siguiente = IDLE;
            end

        endcase
    end


    // Lógica de salida
    always @(*) begin
        done = 1'b0;

        if (estado_actual == DONE)
            done = 1'b1;

    end

endmodule
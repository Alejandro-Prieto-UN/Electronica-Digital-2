// COMPILAR:
// iverilog -g2012 -o src/ejercicio3/transmisor.vvp src/ejercicio3/transmisor.v src/ejercicio3/tb_transmisor.v

// EJECUTAR:
// vvp src/ejercicio3/transmisor.vvp

// GTKWave:
// gtkwave src/ejercicio3/wave.vcd


module transmisor #(
    parameter CLKS_PER_BIT = 8
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [7:0] data_in,

    output reg tx,
    output reg busy,
    output reg done
);

    // =========================================================
    // ESTADOS DE LA ASM
    // =========================================================

    typedef enum logic [2:0] {
        IDLE       = 3'b000,
        LOAD       = 3'b001,
        BIT_HOLD   = 3'b010,
        SHIFT_NEXT = 3'b011,
        DONE       = 3'b100
    } state_t;

    state_t state, next_state;


    // =========================================================
    // DATAPATH
    // =========================================================

    // Registro de desplazamiento
    reg [7:0] shift_reg;

    // Contador de bits transmitidos
    reg [2:0] bit_count;

    // Contador de clocks por bit
    reg [$clog2(CLKS_PER_BIT)-1:0] tick_cnt;


    // =========================================================
    // REGISTROS DE LA ASM Y DATAPATH
    // =========================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            state     <= IDLE;
            shift_reg <= 8'd0;
            bit_count <= 3'd0;
            tick_cnt  <= 0;

        end else begin

            state <= next_state;

            case (state)

                // -------------------------------------------------
                // LOAD
                // -------------------------------------------------
                LOAD: begin

                    shift_reg <= data_in;
                    bit_count <= 3'd0;
                    tick_cnt  <= 0;

                end


                // -------------------------------------------------
                // BIT_HOLD
                // -------------------------------------------------
                // El bit actual permanece en tx durante
                // exactamente CLKS_PER_BIT ciclos.
                //
                // Para CLKS_PER_BIT = 8:
                //
                // 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7
                //
                // En el último ciclo se prepara el siguiente bit.
                // -------------------------------------------------

                BIT_HOLD: begin

                    if (tick_cnt == CLKS_PER_BIT - 1) begin

                        tick_cnt <= 0;

                        // Al terminar el último bit no necesitamos
                        // pasar por SHIFT_NEXT.
                        if (bit_count == 3'd7) begin

                            shift_reg <= shift_reg >> 1;
                            bit_count <= bit_count + 1'b1;

                        end else begin

                            // Se desplaza el registro al terminar
                            // los 8 clocks del bit actual.
                            shift_reg <= shift_reg >> 1;
                            bit_count <= bit_count + 1'b1;

                        end

                    end else begin

                        tick_cnt <= tick_cnt + 1'b1;

                    end

                end


                // -------------------------------------------------
                // SHIFT_NEXT
                // -------------------------------------------------
                // Este estado NO agrega un ciclo extra al bit
                // anterior.
                //
                // El desplazamiento ya ocurrió al finalizar
                // BIT_HOLD. Por eso aquí simplemente se continúa
                // hacia BIT_HOLD con el nuevo bit.
                // -------------------------------------------------

                SHIFT_NEXT: begin

                    // El nuevo bit ya está disponible en shift_reg[0].
                    // El ciclo de SHIFT_NEXT corresponde al inicio
                    // temporal del siguiente bit.

                    // Dejamos tick_cnt en 1 porque este ciclo ya
                    // cuenta como el primer ciclo del nuevo bit.
                    tick_cnt <= 1;

                end


                default: begin

                    // No hacer nada

                end

            endcase

        end

    end


    // =========================================================
    // LÓGICA DE PRÓXIMO ESTADO
    // =========================================================

    always @(*) begin

        next_state = state;

        case (state)

            // -------------------------------------------------
            // IDLE
            // -------------------------------------------------

            IDLE: begin

                if (start)
                    next_state = LOAD;

            end


            // -------------------------------------------------
            // LOAD
            // -------------------------------------------------

            LOAD: begin

                next_state = BIT_HOLD;

            end


            // -------------------------------------------------
            // BIT_HOLD
            // -------------------------------------------------

            BIT_HOLD: begin

                if (tick_cnt == CLKS_PER_BIT - 1) begin

                    if (bit_count == 3'd7)
                        next_state = DONE;
                    else
                        next_state = SHIFT_NEXT;

                end

            end


            // -------------------------------------------------
            // SHIFT_NEXT
            // -------------------------------------------------

            SHIFT_NEXT: begin

                next_state = BIT_HOLD;

            end


            // -------------------------------------------------
            // DONE
            // -------------------------------------------------

            DONE: begin

                next_state = IDLE;

            end


            // -------------------------------------------------
            // DEFAULT
            // -------------------------------------------------

            default: begin

                next_state = IDLE;

            end

        endcase

    end


    // =========================================================
    // LÓGICA DE SALIDAS
    // =========================================================

    always @(*) begin

        // Valores por defecto
        tx   = 1'b1;
        busy = 1'b0;
        done = 1'b0;

        case (state)

            // -------------------------------------------------
            // IDLE
            // -------------------------------------------------

            IDLE: begin

                tx   = 1'b1;
                busy = 1'b0;
                done = 1'b0;

            end


            // -------------------------------------------------
            // LOAD
            // -------------------------------------------------

            LOAD: begin

                tx   = 1'b1;
                busy = 1'b1;
                done = 1'b0;

            end


            // -------------------------------------------------
            // BIT_HOLD
            // -------------------------------------------------

            BIT_HOLD: begin

                tx   = shift_reg[0];
                busy = 1'b1;
                done = 1'b0;

            end


            // -------------------------------------------------
            // SHIFT_NEXT
            // -------------------------------------------------

            SHIFT_NEXT: begin

                // El registro ya fue desplazado al terminar
                // BIT_HOLD, por lo que aquí ya aparece el
                // siguiente bit.
                tx   = shift_reg[0];
                busy = 1'b1;
                done = 1'b0;

            end


            // -------------------------------------------------
            // DONE
            // -------------------------------------------------

            DONE: begin

                tx   = 1'b1;
                busy = 1'b0;
                done = 1'b1;

            end


            // -------------------------------------------------
            // DEFAULT
            // -------------------------------------------------

            default: begin

                tx   = 1'b1;
                busy = 1'b0;
                done = 1'b0;

            end

        endcase

    end

endmodule
`timescale 1ns / 1ps
// Controlador TM1637 (muestra el resultado de la ALU en el digito 1)
// Todo corre en el reloj de 125 MHz con un "tick" de habilitacion (sin relojes derivados).

module display_tm1637 (
    input  wire       clk,          // 125 MHz
    input  wire       btn_exec,     // BTN3
    input  wire [3:0] alu_result,
    output reg        clk_display = 1'b1,
    inout  wire       dio_display
);

    // ---------------- 1. Latch del resultado con BTN3 ----------------
    reg [1:0] btn_sync = 2'b00;
    reg       btn_prev = 1'b0;
    reg [3:0] latched_result = 4'h0;

    always @(posedge clk) begin
        btn_sync <= {btn_sync[0], btn_exec};   // Sincronizador 2 FF
        btn_prev <= btn_sync[1];
        if (btn_sync[1] && !btn_prev)
            latched_result <= alu_result;
    end

    // ---------------- 2. Decodificador hex -> 7 segmentos ----------------
    // bit0=a, bit1=b, bit2=c, bit3=d, bit4=e, bit5=f, bit6=g, bit7=dp/dos puntos
    function [7:0] seg7_map(input [3:0] d);
        case (d)
            4'h0: seg7_map = 8'h3F;
            4'h1: seg7_map = 8'h06;
            4'h2: seg7_map = 8'h5B;
            4'h3: seg7_map = 8'h4F;
            4'h4: seg7_map = 8'h66;
            4'h5: seg7_map = 8'h6D;
            4'h6: seg7_map = 8'h7D;
            4'h7: seg7_map = 8'h07;
            4'h8: seg7_map = 8'h7F;
            4'h9: seg7_map = 8'h6F;
            4'hA: seg7_map = 8'h77;
            4'hB: seg7_map = 8'h7C;
            4'hC: seg7_map = 8'h39;
            4'hD: seg7_map = 8'h5E;
            4'hE: seg7_map = 8'h79;
            4'hF: seg7_map = 8'h71;
            default: seg7_map = 8'h00;
        endcase
    endfunction

    // ---------------- 3. Tick lento (100 kHz) ----------------
    // Cada estado dura 10 us; un bit usa 3 estados -> CLK del TM1637 ~33 kHz
    reg [10:0] tick_cnt = 11'd0;
    wire       tick = (tick_cnt == 11'd1249);
    always @(posedge clk)
        tick_cnt <= tick ? 11'd0 : tick_cnt + 1'b1;

    // ---------------- 4. DIO tri-state ----------------
    reg dio_out = 1'b1;
    reg dio_oe  = 1'b1;
    assign dio_display = dio_oe ? dio_out : 1'bz;

    // ---------------- 5. Maquina de estados ----------------
    // Secuencia de bytes:  [START] 0x44 [STOP] | [START] 0xC0, seg [STOP] | [START] 0x8F [STOP]
    localparam S_START0   = 4'd0,
               S_START1   = 4'd1,
               S_LOAD     = 4'd2,
               S_SETUP    = 4'd3,   // CLK=0: se pone el bit en DIO
               S_HIGH     = 4'd4,   // CLK=1: el TM1637 lee el bit
               S_FALL     = 4'd5,   // CLK=0
               S_ACK_REL  = 4'd6,   // CLK=0: FPGA suelta DIO
               S_ACK_H    = 4'd7,   // CLK=1: 9no pulso (ACK)
               S_ACK_L    = 4'd8,   // CLK=0: termina el 9no pulso
               S_ACK_TAKE = 4'd9,   // FPGA retoma DIO (CLK ya esta en 0)
               S_STOP1    = 4'd10,
               S_STOP2    = 4'd11;

    reg [3:0] st        = S_START0;
    reg [1:0] byte_idx  = 2'd0;
    reg [7:0] shift_reg = 8'd0;
    reg [2:0] bit_cnt   = 3'd0;

    reg [7:0] cur_byte;
    always @(*) begin
        case (byte_idx)
            2'd0:    cur_byte = 8'h44;                       // Comando de datos: MODO DIRECCIÓN FIJA
            2'd1:    cur_byte = 8'hC0;                       // Dirección del Dígito 1 (izquierda)
            2'd2:    cur_byte = seg7_map(latched_result);    // Dato únicamente para el Dígito 1
            default: cur_byte = 8'h8F;                       // Display ON, brillo máximo
        endcase
    end

    always @(posedge clk) begin
        if (tick) begin
            case (st)
                S_START0: begin
                    dio_oe <= 1'b1; clk_display <= 1'b1; dio_out <= 1'b1;
                    st <= S_START1;
                end
                S_START1: begin            // START: DIO baja con CLK en alto
                    dio_out <= 1'b0;
                    st <= S_LOAD;
                end
                S_LOAD: begin
                    clk_display <= 1'b0;
                    shift_reg   <= cur_byte;
                    bit_cnt     <= 3'd0;
                    st <= S_SETUP;
                end
                S_SETUP: begin             // DIO cambia solo con CLK en bajo
                    dio_out <= shift_reg[0];
                    st <= S_HIGH;
                end
                S_HIGH: begin
                    clk_display <= 1 me;
                    st <= S_FALL;
                end
                S_FALL: begin
                    clk_display <= 1'b0;
                    shift_reg   <= {1'b0, shift_reg[7:1]};
                    if (bit_cnt == 3'd7) st <= S_ACK_REL;
                    else begin bit_cnt <= bit_cnt + 1'b1; st <= S_SETUP; end
                end
                S_ACK_REL: begin           // Soltar DIO para que el TM1637 responda ACK
                    dio_oe <= 1'b0;
                    st <= S_ACK_H;
                end
                S_ACK_H: begin
                    clk_display <= 1'b1;
                    st <= S_ACK_L;
                end
                S_ACK_L: begin             // El 9no pulso baja antes de retomar DIO
                    clk_display <= 1'b0;
                    st <= S_ACK_TAKE;
                end
                S_ACK_TAKE: begin
                    dio_oe  <= 1'b1;
                    dio_out <= 1'b0;
                    if (byte_idx == 2'd1) begin      // Después de 0xC0 sigue el dato, sin generar STOP
                        byte_idx <= 2'd2;
                        st <= S_LOAD;
                    end else
                        st <= S_STOP1;
                end
                S_STOP1: begin             // STOP: CLK sube y luego DIO sube
                    clk_display <= 1'b1;
                    st <= S_STOP2;
                end
                S_STOP2: begin
                    dio_out <= 1'b1;
                    byte_idx <= (byte_idx == 2'd3) ? 2'd0 : byte_idx + 1'b1;
                    st <= S_START0;
                end
                default: st <= S_START0;
            endcase
        end
    end

endmodule
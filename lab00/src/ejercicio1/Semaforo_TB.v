// Modulo de prueba del incrementador
`timescale 1ns / 1ps

module Semaforo_TB;
    
    reg clk;
    reg rst;         
    wire green;
    wire yellow;
    wire red;
  
    Semaforo uut(.clk(clk),.rst(rst),.green(green),.yellow(yellow),.red(red));
    
    parameter PERIOD= 20;
    parameter real DUTY_CYCLE = 0.5;
    parameter OFFSET= 0;

   initial  begin  
     #OFFSET;
     forever
       begin
         clk = 1'b0;
         #(PERIOD-(PERIOD*DUTY_CYCLE)) clk = 1'b1;
         #(PERIOD*DUTY_CYCLE);
       end
   end

    initial begin
 
        rst=1;
        #20
        rst=0;
        #20
        rst=0;
        #20
        rst=0;
        #500
        rst=1;
        #20
        rst=0;
        #1000
        $finish;
    end

    initial begin: TEST_CASE
     $dumpfile("Semaforo_TB.vcd");
     $dumpvars(-1, uut);
   end

endmodule
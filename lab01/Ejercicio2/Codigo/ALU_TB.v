`timescale 1ns / 1ps

module ALU_TB();

    reg [3:0]A;
    reg [3:0]B;
    reg [1:0]Botones;
    wire[3:0]OP; //Aqui va el resultado de la operacion hecha
  


    ALU uut (.A(A),.B(B),.Botones(Botones),.OP(OP));


    initial begin
        A=4'b1010;
        B=4'b0011;
        Botones = 2'b00;
        #20;
        Botones =2'b01;
        #20;
        Botones = 2'b10;
        #20;
        Botones = 2'b11;
        #20;
        #100;
        $finish;
    end

    initial begin: TEST_CASE
     $dumpfile("ALU_TB.vcd");
     $dumpvars(-1, uut);
   end

endmodule
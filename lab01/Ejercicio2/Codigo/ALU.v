module ALU (
    input [3:0]A,
    input [3:0]B,
    input [1:0]Botones,
    output reg[3:0]OP
);

always @(*) begin

    if (Botones==2'b00)begin

        OP=A+B;

    end else if (Botones==2'b01)begin

        OP=A-B;
 
    end else if (Botones==2'b10)begin

        OP=A&B;

    end else if (Botones==2'b11)begin

        OP=A|B;

    end  else begin

        OP=4'b0000;
 
    end
    
end
endmodule
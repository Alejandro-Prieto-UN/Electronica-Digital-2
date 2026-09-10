module Semaforo(
    input clk,
    input rst,
    output reg green,
    output reg yellow,
    output reg red
    );

    reg [4:0]i;

always @(posedge clk) begin
    if (rst) begin
        i <= 5'd0;
    end else begin
        if (i >= 5'd18) begin
            i <= 5'd0;   
        end else begin
            i <= i + 1'b1; 
        end
    end
end

    always@(*)begin

          if(rst)begin

            green=1'b0;
            yellow=1'b0;
            red=1'b0;
          end

            if (i<=5) begin
                
                green=1'b1;
                yellow=1'b0;
                red=1'b0;

            end else if(5<i && i<=7)begin

                green=1'b0;
                yellow=1'b1;
                red=1'b0;

            end else if(7<i && i<=11)begin

                green=1'b0;
                yellow=1'b0;
                red=1'b1;

            end  else if(11<i && i<=13)begin

                green=1'b0;
                yellow=1'b1;
                red=1'b0;

            end  else if(13<i && i<=18)begin
                green=1'b1;
                yellow=1'b0;
                red=1'b0;
            end           
    end
endmodule
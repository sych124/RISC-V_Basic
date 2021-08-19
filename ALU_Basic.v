module ALU_Basic(
        input   [63:0]  ALUSrc0, ALUSrc1,
        input   [3:0]   ALUop,
        output  [63:0]  ALUresult
);

assign ALUresult = (ALUop[3:0] == 4'b0010) ? ALUSrc0 + ALUSrc1 :
                (ALUop[3:0] == 4'b0110) ? ALUSrc0 - ALUSrc1 :
                (ALUop[3:0] == 4'b0000) ? ALUSrc0 & ALUSrc1 :
                (ALUop[3:0] == 4'b0001) ? ALUSrc0 | ALUSrc1 : 64'b0;

endmodule

module Control_Decoder(
        input   [6:0]   Opcode,
        output  [7:0]   ControlBUS
);

assign ControlBUS = (Opcode[6:4] == 3'b010) ? 8'b00000110 :     //sd
                (Opcode[6:4] == 3'b110) ? 8'b10001000 : //beq
                (Opcode[6:4] == 3'b000)&&(Opcode[3:0] != 4'b0) ? 8'b01100011 :  //ld
                (Opcode[6:4] == 3'b011) ? 8'b00010001 : 8'b0;   //R-type

endmodule
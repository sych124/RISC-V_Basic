module Forwarding(
        input wire ID_EX_ALUsrc,
        input wire EX_MEM_Regwrite,
        input wire MEM_WB_Regwrite,
        input wire [4:0] EX_MEM_Rd,
        input wire [4:0] ID_EX_Rs,
        input wire [4:0] ID_EX_Rt,
        input wire [4:0] MEM_WB_Rd,
        output wire [1:0] forwardA,
        output wire [1:0] forwardB
);
        assign forwardA = ((MEM_WB_Regwrite && (MEM_WB_Rd != 5'd0)) && ~(EX_MEM_Regwrite && (EX_MEM_Rd != 5'd0) && (EX_MEM_Rd == ID_EX_Rs)) && (MEM_WB_Rd == ID_EX_Rs)) ? 2'b01 :
                        (EX_MEM_Regwrite && (EX_MEM_Rd != 5'd0) && (EX_MEM_Rd == ID_EX_Rs)) ? 2'b10 : 2'b00 ;
        assign forwardB = ((MEM_WB_Regwrite && (MEM_WB_Rd != 5'd0)) && ~(EX_MEM_Regwrite && (EX_MEM_Rd != 5'd0) && (EX_MEM_Rd == ID_EX_Rt)) && (MEM_WB_Rd == ID_EX_Rt) && (ID_EX_ALUsrc == 1'd0)) ? 2'b01 :
                        ((EX_MEM_Regwrite && (EX_MEM_Rd != 5'd0)) && (EX_MEM_Rd == ID_EX_Rt) && (ID_EX_ALUsrc == 1'd0)) ? 2'b10 : 2'b00 ;
endmodule

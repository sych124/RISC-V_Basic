module Hazard_Detector(
        input           Branch,
        input           ID_EX_MemRead,
        input   [4:0]   ID_EX_Rd,
        input   [4:0]   IF_ID_Rs,
        input   [4:0]   IF_ID_Rt,
        output          Flush
);

assign Flush = Branch || (ID_EX_MemRead ==  1'b1) &&
        ((ID_EX_Rd == IF_ID_Rs) || (ID_EX_Rd == IF_ID_Rt)) ? 1'b0 : 1'b1;

endmodule

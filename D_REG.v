module D_REG #(parameter n = 64)(
        input iRST,iCLK,iEN,
        input [n-1:0] iD, //input Data
        output reg [n-1:0] oD //output Data
);

        always @(posedge iCLK,posedge iRST)
        begin
                if(iRST) // KEY[0](RST) == 0
                        oD <=  0;
                else if(iEN)
                        oD <= iD;
                else
                        oD <= oD;
        end

endmodule

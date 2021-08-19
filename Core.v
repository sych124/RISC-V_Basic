module Core(
        // I/F with pm
        output wire     [63:0]  o_pm_addr,
        output wire             o_pm_cs,
        input wire      [31:0]  i_pm_data,
        //I/F with DM
        output wire     [63:0]  o_dm_addr,
        output wire             o_dm_cs,
        output wire             o_dm_rw,
        output wire     [63:0]  o_dm_data,
        input wire      [63:0]  i_dm_data,

        input wire              i_clk,
        input wire              i_rst
);
//Data Path
wire    [63:0]  PCiD, PC2PM;    //PC Register input and flow to Program Memory
wire    [31:0]  Instr;  //Instruction from Programm Memory
wire    [63:0]  RegSrc0, RegSrc1, RegRSrc1, Imm64;      //Source from Register
wire    [63:0]  ALURSrc0, ALURSrc1;     //ALU Source
wire    [63:0]  WBiD;   //Write Back Register Input Data
wire    [63:0]  ALU2DM, DM2WB;  //input,output for Data Memory
//Control Path
wire            Flush;  //Bubble
wire            Zero;   //Branch Control
wire            Branch, MemRead, MemtoReg, MemWrite,ALUSrc, RegWrite;
wire    [1:0]   ForwardA, ForwardB;
wire    [1:0]   ALUOp;  //to ALU Control
wire    [7:0]   Control;
wire    [6:0]   ControlBUS;
wire    [3:0]   ALUctrl; //to ALU
//Pipeline Path out
wire    [31:0]  IF_out;
wire    [231:0] ID_out;
wire    [206:0] EX_out;
wire    [134:0] MEM_out;
wire    [70:0]  MEM0_out;
/*Instruction Fetch*/
D_REG #(.n(64)) //PC SPR
PC_REG( .iRST(i_rst),.iCLK(i_clk),.iEN(1'b1),
        .iD(PCiD),.oD(PC2PM));
//Program Memory
assign o_pm_addr = PC2PM[9:0];
assign o_pm_cs  = 1'b1;
assign {Instr[7:0],Instr[15:8],Instr[23:16],Instr[31:24]} = i_pm_data;

D_REG #(.n(32))
IF_ID_REG(.iRST(i_rst),.iCLK(i_clk),.iEN(1'b1),
        .iD(Instr[31:0]),.oD(IF_out));

/*Instruction Decode*/
RegFile_32x64bit        //General Purpose Register
Reg_32( .i_read0(1'b1),.i_read_addr0(IF_out[19:15]),.o_read_data0(RegSrc0),
        .i_read1(1'b1),.i_read_addr1(IF_out[24:20]),.o_read_data1(RegSrc1),
        .i_write(MEM_out[66]),.i_write_addr(MEM_out[132:128]),.i_write_data(WBiD),
        .i_clk(i_clk),.i_rst(i_rst));

//ImmGen
assign Imm64 =  (IF_out[6:4] == 3'b010) ? {64{IF_out[31]}}-{12{IF_out[31]}} + {IF_out[31:25],IF_out[11:7]} :    //S-type
                (IF_out[6:4] == 3'b110) ? {64{IF_out[31]}}-{12{IF_out[31]}} + {IF_out[31],IF_out[7],IF_out[30:25],IF_out[11:8]} :       //SB-tye
                (IF_out[6:4] == 3'b000) ? {64{IF_out[31]}}-{12{IF_out[31]}} + {IF_out[31:20]} : 64'b0;  //I-type

Control_Decoder
Control_Decoder0(.Opcode(IF_out[6:0]),.ControlBUS(Control));
assign {Branch,MemRead,MemtoReg,ALUOp,MemWrite,ALUSrc,RegWrite} =
                (ID_out[231]&EX_out[206]) ? (Flush|Control[7] ? Control : 8'b0) : 8'b0;

Hazard_Detector
Hazard_Detection(.Branch(Branch&Zero),.ID_EX_MemRead(ID_out[162]),.ID_EX_Rd(ID_out[11:7]),.IF_ID_Rs(IF_out[19:15]),.IF_ID_Rt(IF_out[24:20]),.Flush(Flush));

assign ControlBUS = {ALUSrc,RegWrite,MemtoReg,MemWrite,MemRead,ALUOp};  //Bubble
assign RegRSrc1 = ALUSrc ? Imm64 : RegSrc1;     //Rs1 Select
//beq for PC
assign Zero = (RegSrc0 == RegSrc1);
assign PCiD = (Branch & Zero) ? PC2PM+{Imm64[62:0],1'b0}-64'd8 :
        ~Flush ? PC2PM-64'd8 : PC2PM+64'd4;

D_REG #(.n(232))
ID_EX_REG(.iRST(i_rst),.iCLK(i_clk),.iEN(1'b1),
        .iD({Flush,RegSrc1,ControlBUS,RegSrc0,RegRSrc1,IF_out}),.oD(ID_out)); //{1'b1,64b',7b',64b',64'b,Instr[32]}

/*ALU Execution*/
ALU_control//ALU Controler
ALU_control0(.i_op({ID_out[161:160],ID_out[30],ID_out[14:12]}),.o_op(ALUctrl));
//ALU Source MUX
assign ALURSrc0 = (ForwardA == 2'd0) ? ID_out[159:96] :
                (ForwardA == 2'd1) ? WBiD : EX_out[127:64];
assign ALURSrc1 = (ForwardB == 2'd0) ? ID_out[95:32] :
                (ForwardB == 2'd1) ? WBiD : EX_out[127:64];

ALU_Basic       //Logic Unit
ALU_Basic0(.ALUSrc0(ALURSrc0),.ALUSrc1(ALURSrc1),.ALUop(ALUctrl),.ALUresult(ALU2DM));
//Forwarding Unit
Forwarding
Forward0(.EX_MEM_Regwrite(EX_out[141]),.MEM_WB_Regwrite(MEM_out[134]),.MEM_WB_Rd(MEM_out[132:128]),.ID_EX_Rs(ID_out[19:15]),.forwardA(ForwardA)
        ,.ID_EX_ALUsrc(ID_out[166]),.EX_MEM_Rd(EX_out[132:128]),.ID_EX_Rt(ID_out[24:20]),.forwardB(ForwardB));

D_REG #(.n(207))
EX_MEM_REG(.iRST(i_rst),.iCLK(i_clk),.iEN(1'b1),
        .iD({ID_out[231:167],ID_out[165:162],ID_out[19:15],ID_out[11:7],ALU2DM,ALURSrc1}),.oD(EX_out)); //{Flush,RegSrc1[64],ControlBUS[4],RegSrc1[5],RegDest[5],ALUresult[64],ALURSrc1[64]

/*Memory Access*/
//Data Memory
assign o_dm_addr = EX_out[73:64];//EX_out[139] ? EX_out[73:64] :
                //EX0_out[140] ? EX0_out[73:64] : EX_out[73:64];
assign o_dm_cs  = 1'b1;
assign o_dm_rw  = EX_out[139] ? 1'b1 : 1'b0;
assign o_dm_data = {EX_out[149:142],EX_out[157:150],EX_out[165:158],EX_out[173:166],EX_out[181:174],EX_out[189:182],EX_out[197:190],EX_out[205:198]};
assign {DM2WB[7:0],DM2WB[15:8],DM2WB[23:16],DM2WB[31:24],DM2WB[39:32],DM2WB[47:40],DM2WB[55:48],DM2WB[63:56]} = i_dm_data;

D_REG #(.n(71))
MEM0_WB_REG(.iRST(i_rst),.iCLK(i_clk),.iEN(1'b1),
        .iD({EX_out[141:140],EX_out[132:128],EX_out[127:64]}),.oD(MEM0_out));
D_REG #(.n(135))
MEM_WB_REG(.iRST(i_rst),.iCLK(i_clk),.iEN(1'b1),
        .iD({MEM0_out,DM2WB}),.oD(MEM_out));    //{ControlBUS[2],RegDest[5],ALUresult[64],DataMemory[64]}

/*Write Back Begin*/
assign WBiD = MEM_out[133] ? MEM_out[63:0] : MEM_out[127:64];   //WriteBack Source MUX

endmodule

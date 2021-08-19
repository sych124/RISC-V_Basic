module RegFile_32x64bit(
        input wire              i_read0,        //active-high read request of read-port0
        input wire [4:0]        i_read_addr0,   //5'd0~5'd31
        output reg [63:0]       o_read_data0,

        input wire              i_read1,        //active-high read request of read-port1
        input wire [4:0]        i_read_addr1,   //5'd0~5'd31
        output reg [63:0]       o_read_data1,

        input wire              i_write,        //active-high write request of write-port0
        input wire [4:0]        i_write_addr,   //5'd0~5;d31
        output reg [63:0]       i_write_data,

        input wire              i_clk,          //clock
        input wire              i_rst           //active-high async. reset
);
reg [31:0] regs[0:31];

always @(posedge i_clk)
        if(i_read0)
                if((i_read_addr0 == i_write_addr) & i_write) o_read_data0 <= i_write_data;
                else o_read_data0 <= regs[i_read_addr0];

always @(posedge i_clk)
        if(i_read1)
                if((i_read_addr1 == i_write_addr) & i_write) o_read_data1 <= i_write_data;
                else o_read_data1 <= regs[i_read_addr1];

always @(posedge i_clk)
        if(i_rst) begin
                regs[0] <= 64'd0;       regs[1] <= 64'd0;       regs[2] <= 64'd0;       regs[3] <= 64'd0;       regs[4] <= 64'd0;
                regs[5] <= 64'd0;       regs[6] <= 64'd0;       regs[7] <= 64'd0;       regs[8] <= 64'd0;       regs[9] <= 64'd0;
                regs[10] <= 64'd0;      regs[11] <= 64'd0;      regs[12] <= 64'd0;      regs[13] <= 64'd0;      regs[14] <= 64'd0;
                regs[15] <= 64'd0;      regs[16] <= 64'd0;      regs[17] <= 64'd0;      regs[18] <= 64'd0;      regs[19] <= 64'd0;
                regs[20] <= 64'd0;      regs[21] <= 64'd0;      regs[22] <= 64'd0;      regs[23] <= 64'd0;      regs[24] <= 64'd0;
                regs[25] <= 64'd0;      regs[26] <= 64'd0;      regs[27] <= 64'd0;      regs[28] <= 64'd0;      regs[29] <= 64'd0;
                regs[30] <= 64'd0;      regs[31] <= 64'd0;
        end
        else if(i_write & (i_write_addr != 5'd0)) regs[i_write_addr] <= i_write_data;

endmodule

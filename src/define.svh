`ifndef define_sv
`define define_sv

//---------------------------------------------------------------------
//        Bit Width             
//---------------------------------------------------------------------
`define DATA_WIDTH    32
`define REG_DEPTH     32
`define PC_WIDTH      32
`define DM_DEPTH      16384
`define IM_DEPTH      16384
`define CSR_WIDTH     64
//---------------------------------------------------------------------
//        Instruction             
//---------------------------------------------------------------------
`define funct7_RANGE 31:25
`define rs2_RANGE    24:20
`define rs1_RANGE    19:15
`define funct3_RANGE 14:12
`define rd_RANGE     11:7
`define OP_RANGE     6:2
`define OP_WIDTH     5

// << opcode >>
// << R-type (M-extension) >>

`define RTYPE  5'b01100 //11
// << I-type >>         //
`define ITYPE  5'b00100 //11
`define JALR   5'b11001 //11
`define LOAD   5'b00000 //11
// << S-type >>         //
`define STYPE	 5'b01000 //11
// << B-type >>         //
`define BTYPE	 5'b11000 //11
// << U-type >>         //
`define AUIPC  5'b00101 //11
`define LUI    5'b01101 //11
// << J-type >> // JAL  //
`define JTYPE  5'b11011 //11
// << CSR >>            //
`define CSR    5'b11100 //11


/*
`define RTYPE  7'b0110011
// << I-type >>        
`define ITYPE  7'b0010011
`define JALR   7'b1100111
`define LOAD   7'b0000011
// << S-type >>        
`define STYPE	 7'b0100011
// << B-type >>        
`define BTYPE	 7'b1100011
// << U-type >>        
`define AUIPC  7'b0010111
`define LUI    7'b0110111
// << J-type >> // JAL 
`define JTYPE  7'b1101111
// << CSR >>           
`define CSR    7'b1110011
*/

//---------------------------------------------------------------------
//        ALU Operations             
//---------------------------------------------------------------------
`define ADD       4'd0  // rd = rs1 + rs2
`define SUB       4'd1  // rd = rs1 - rs2
`define SLL       4'd2  // rd = rs1s << rs2[4:0]
`define SLT_SLTU  4'd3  // rd = (rs1s < rs2s)? 1:0 / rd = (rs1u < rs2u)? 1:0
`define XOR       4'd4  // rd = rs1 ^ rs2
`define SRL_SRA   4'd5  // rd = rs1u >> rs2[4:0] / rd = rs1s >> rs2[4:0]
`define OR        4'd6  // rd = rs1 | rs2
`define AND       4'd7  // rd = rs1 & rs2
`define MUL       4'd8
`define MULH      4'd9
`define MULHSU    4'd10
`define MULHU     4'd11

`endif

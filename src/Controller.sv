module Controller(
  opcode_i,
  funct3_i,
  funct7_0_i,
  flush_i,
  RegWrite_o,
  ALUsrcAsel_o,
  ALUsrcBsel_o,
  MemWrite_o,
  MemRead_o,
  Branch_o,
  Jal_o,
  Jalr_o,
  ALUop_o
);
//---------------------------------------------------------------------
//        PORTS DECLARATION                             
//---------------------------------------------------------------------
input  logic [`OP_WIDTH-1:0]     opcode_i;
input  logic [2:0]               funct3_i;
input  logic                   funct7_0_i;
input  logic                      flush_i;//prevent the nop instruction(for Load type)
output logic                   RegWrite_o;
output logic [1:0]           ALUsrcAsel_o;
output logic [1:0]           ALUsrcBsel_o;
output logic [3:0]             MemWrite_o;
output logic                    MemRead_o;
output logic                     Branch_o;
output logic                        Jal_o;
output logic                       Jalr_o;
output logic [1:0]                ALUop_o;
//---------------------------------------------------------------------
//        LOGIC & VARIABLES DECLARATION                            
//---------------------------------------------------------------------
logic  [31:0]                  decoderOut;
logic                            no_flush;
assign no_flush = ~flush_i;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                            Control Signal Table                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// |  opcode_i  | RegWrite_o | ALUsrcAsel_o | ALUsrcBsel_o | MemWrite_o | MemRead_o | Branch_o | Jal_o | Jalr_o | ALUop_o  |                 Description                 |//
// |------------+------------+--------------+--------------+------------+-----------+----------+-------+--------+----------+---------------------------------------------|//
// |  5'b01100  |     1      |      0       |      0       |     f      |     0     |     0    |   0   |    0   |     1    | RTYPE                                       |//
// |  5'b00100  |     1      |      0       |      1       |     f      |     0     |     0    |   0   |    0   |     2    | ITYPE (RTYPE imm)                           |//
// |  5'b11001  |     1      |      1       |      2       |     f      |     0     |     0    |   0   |    1   |     0    | JALR  (rd = PC + 4 ; PC = imm + rs1)        |//
// |  5'b00000  |     1      |      0       |      1       |     f      |     1     |     0    |   0   |    0   |     0    | LOAD  (rd = Mem[rs1+imm])                   |//
// |  5'b01000  |     0      |      0       |      1       |    case    |     0     |     0    |   0   |    0   |     0    | STYPE (Mem[rs1+imm] = rs2)                  |//
// |  5'b11000  |     0      |      0       |      0       |     f      |     0     |     1    |   0   |    0   |     0    | BTYPE (Compare rs1 & rs2 -> PC = PC + imm/4)|//
// |  5'b00101  |     1      |      1       |      1       |     f      |     0     |     0    |   0   |    0   |     0    | AUIPC (rd = PC + imm)                       |//
// |  5'b01101  |     1      |      2       |      1       |     f      |     0     |     0    |   0   |    0   |     0    | LUI   (rd = imm)                            |//
// |  5'b11011  |     1      |      1       |      2       |     f      |     0     |     0    |   1   |    0   |     0    | JTYPE (rd = PC + 4 ; PC = PC + imm)         |//
// |  5'b11100  |     1      |      2       |      3       |     f      |     0     |     0    |   0   |    0   |     0    | CSR   (rd = cycle or instret)               |//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// ========================= Note =========================

// << ALUsrcAsel_o >>
// 0 : srcA or Forwarding
// 1 : PC
// 2 : 32'd0
// 3 : don't care

// << ALUsrcBsel_o >>
// 0 : srcB or Forwarding
// 1 : immediate value
// 2 : 32'd4
// 3 : CSR value
//---------------------------------------------------------------------
//        WIRE CONNECTION                             
//---------------------------------------------------------------------
assign RegWrite_o      = decoderOut[`RTYPE] | decoderOut[`ITYPE] | decoderOut[`JALR ] | decoderOut[`AUIPC] | decoderOut[`LUI  ] | decoderOut[`JTYPE] | decoderOut[`CSR  ] | (decoderOut[`LOAD ] & no_flush);
assign MemRead_o       = decoderOut[`LOAD ] & no_flush;
assign Branch_o        = decoderOut[`BTYPE];
assign Jal_o           = decoderOut[`JTYPE];
assign Jalr_o          = decoderOut[`JALR ];

assign ALUsrcAsel_o[0] = decoderOut[`JALR ] | decoderOut[`AUIPC] | decoderOut[`JTYPE];
assign ALUsrcAsel_o[1] = decoderOut[`LUI  ] | decoderOut[`CSR  ];

assign ALUsrcBsel_o[0] = decoderOut[`ITYPE] | decoderOut[`STYPE] | decoderOut[`AUIPC] | decoderOut[`LUI  ] | (decoderOut[`LOAD ] & no_flush) | decoderOut[`CSR  ];
assign ALUsrcBsel_o[1] = decoderOut[`JALR ] | decoderOut[`JTYPE] | decoderOut[`CSR  ];

assign ALUop_o[0]      = decoderOut[`RTYPE];
assign ALUop_o[1]      = decoderOut[`ITYPE] | (decoderOut[`RTYPE] & funct7_0_i);

assign MemWrite_o[0]   = (!decoderOut[`STYPE]) | (&funct3_i);// !(decoderOut[`STYPE] & !(&funct3_i)) = !decoderOut[`STYPE] | (&funct3_i)
assign MemWrite_o[1]   = !(decoderOut[`STYPE] & (^funct3_i));
assign MemWrite_o[2]   = !(decoderOut[`STYPE] & funct3_i[1] & (!funct3_i[0]));
assign MemWrite_o[3]   = MemWrite_o[2];
//---------------------------------------------------------------------
//        ALWAYS BLOCK                             
//---------------------------------------------------------------------
always_comb begin
  unique case(opcode_i)
    5'd0 :decoderOut = 32'b0000_0000_0000_0000_0000_0000_0000_0001;
    5'd1 :decoderOut = 32'b0000_0000_0000_0000_0000_0000_0000_0010;
    5'd2 :decoderOut = 32'b0000_0000_0000_0000_0000_0000_0000_0100;
    5'd3 :decoderOut = 32'b0000_0000_0000_0000_0000_0000_0000_1000;
    5'd4 :decoderOut = 32'b0000_0000_0000_0000_0000_0000_0001_0000;
    5'd5 :decoderOut = 32'b0000_0000_0000_0000_0000_0000_0010_0000;
    5'd6 :decoderOut = 32'b0000_0000_0000_0000_0000_0000_0100_0000;
    5'd7 :decoderOut = 32'b0000_0000_0000_0000_0000_0000_1000_0000;
    5'd8 :decoderOut = 32'b0000_0000_0000_0000_0000_0001_0000_0000;
    5'd9 :decoderOut = 32'b0000_0000_0000_0000_0000_0010_0000_0000;
    5'd10:decoderOut = 32'b0000_0000_0000_0000_0000_0100_0000_0000;
    5'd11:decoderOut = 32'b0000_0000_0000_0000_0000_1000_0000_0000;
    5'd12:decoderOut = 32'b0000_0000_0000_0000_0001_0000_0000_0000;
    5'd13:decoderOut = 32'b0000_0000_0000_0000_0010_0000_0000_0000;
    5'd14:decoderOut = 32'b0000_0000_0000_0000_0100_0000_0000_0000;
    5'd15:decoderOut = 32'b0000_0000_0000_0000_1000_0000_0000_0000;
    5'd16:decoderOut = 32'b0000_0000_0000_0001_0000_0000_0000_0000;
    5'd17:decoderOut = 32'b0000_0000_0000_0010_0000_0000_0000_0000;
    5'd18:decoderOut = 32'b0000_0000_0000_0100_0000_0000_0000_0000;
    5'd19:decoderOut = 32'b0000_0000_0000_1000_0000_0000_0000_0000;
    5'd20:decoderOut = 32'b0000_0000_0001_0000_0000_0000_0000_0000;
    5'd21:decoderOut = 32'b0000_0000_0010_0000_0000_0000_0000_0000;
    5'd22:decoderOut = 32'b0000_0000_0100_0000_0000_0000_0000_0000;
    5'd23:decoderOut = 32'b0000_0000_1000_0000_0000_0000_0000_0000;
    5'd24:decoderOut = 32'b0000_0001_0000_0000_0000_0000_0000_0000;
    5'd25:decoderOut = 32'b0000_0010_0000_0000_0000_0000_0000_0000;
    5'd26:decoderOut = 32'b0000_0100_0000_0000_0000_0000_0000_0000;
    5'd27:decoderOut = 32'b0000_1000_0000_0000_0000_0000_0000_0000;
    5'd28:decoderOut = 32'b0001_0000_0000_0000_0000_0000_0000_0000;
    5'd29:decoderOut = 32'b0010_0000_0000_0000_0000_0000_0000_0000;
    5'd30:decoderOut = 32'b0100_0000_0000_0000_0000_0000_0000_0000;
    5'd31:decoderOut = 32'b1000_0000_0000_0000_0000_0000_0000_0000;
  endcase
end

endmodule



// ----------------------------------- opcode 7-bits ALL MUX -----------------------------------

/*
module Controller(
  opcode_i,
  funct3_i,
  funct7_0_i,
  flush_i,
  RegWrite_o,
  ALUsrcAsel_o,
  ALUsrcBsel_o,
  MemWrite_o,
  MemRead_o,
  Branch_o,
  Jal_o,
  Jalr_o,
  ALUop_o
);
//---------------------------------------------------------------------
//        PORTS DECLARATION                             
//---------------------------------------------------------------------
input  logic [`OP_WIDTH-1:0]     opcode_i;
input  logic [2:0]               funct3_i;
input  logic                   funct7_0_i;//for M-extension instruction
input  logic                      flush_i;//prevent the nop instruction(for Load type)
output logic                   RegWrite_o;
output logic [1:0]           ALUsrcAsel_o;
output logic [1:0]           ALUsrcBsel_o;
output logic [3:0]             MemWrite_o;
output logic                    MemRead_o;
output logic                     Branch_o;
output logic                        Jal_o;
output logic                       Jalr_o;
output logic [1:0]                ALUop_o;
//---------------------------------------------------------------------
//        LOGIC & VARIABLES DECLARATION                            
//---------------------------------------------------------------------
logic                            no_flush;
assign no_flush = ~flush_i;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                            Control Signal Table                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// |  opcode_i  | RegWrite_o | ALUsrcAsel_o | ALUsrcBsel_o | MemWrite_o | MemRead_o | Branch_o | Jal_o | Jalr_o | ALUop_o  |                 Description                 |//
// |------------+------------+--------------+--------------+------------+-----------+----------+-------+--------+----------+---------------------------------------------|//
// |  5'b01100  |     1      |      0       |      0       |     f      |     0     |     0    |   0   |    0   |     1    | RTYPE                                       |//
// |  5'b00100  |     1      |      0       |      1       |     f      |     0     |     0    |   0   |    0   |     2    | ITYPE (RTYPE imm)                           |//
// |  5'b11001  |     1      |      1       |      2       |     f      |     0     |     0    |   0   |    1   |     0    | JALR  (rd = PC + 4 ; PC = imm + rs1)        |//
// |  5'b00000  |     1      |      0       |      1       |     f      |     1     |     0    |   0   |    0   |     0    | LOAD  (rd = Mem[rs1+imm])                   |//
// |  5'b01000  |     0      |      0       |      1       |    case    |     0     |     0    |   0   |    0   |     0    | STYPE (Mem[rs1+imm] = rs2)                  |//
// |  5'b11000  |     0      |      0       |      0       |     f      |     0     |     1    |   0   |    0   |     0    | BTYPE (Compare rs1 & rs2 -> PC = PC + imm/4)|//
// |  5'b00101  |     1      |      1       |      1       |     f      |     0     |     0    |   0   |    0   |     0    | AUIPC (rd = PC + imm)                       |//
// |  5'b01101  |     1      |      2       |      1       |     f      |     0     |     0    |   0   |    0   |     0    | LUI   (rd = imm)                            |//
// |  5'b11011  |     1      |      1       |      2       |     f      |     0     |     0    |   1   |    0   |     0    | JTYPE (rd = PC + 4 ; PC = PC + imm)         |//
// |  5'b11100  |     1      |      2       |      3       |     f      |     0     |     0    |   0   |    0   |     0    | CSR   (rd = cycle or instret)               |//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// ========================= Note =========================

// << ALUsrcAsel_o >>
// 0 : srcA or Forwarding
// 1 : PC
// 2 : 32'd0
// 3 : don't care

// << ALUsrcBsel_o >>
// 0 : srcB or Forwarding
// 1 : immediate value
// 2 : 32'd4
// 3 : CSR value

//---------------------------------------------------------------------
//        ALWAYS BLOCK                             
//---------------------------------------------------------------------

always_comb begin
  RegWrite_o    = 1'b0;
  ALUsrcAsel_o  = 2'd0;
  ALUsrcBsel_o  = 2'd0;
  MemWrite_o    = 4'hf;
  MemRead_o     = 1'b0;
  Branch_o      = 1'b0;
  Jal_o         = 1'b0;
  Jalr_o        = 1'b0;
  ALUop_o       = 2'd0;
  unique case(opcode_i)
    `RTYPE:begin
      RegWrite_o    = 1'b1;
      ALUsrcAsel_o  = 2'd0;
      ALUsrcBsel_o  = 2'd0;
      MemWrite_o    = 4'hf;
      MemRead_o     = 1'b0;
      Branch_o      = 1'b0;
      Jal_o         = 1'b0;
      Jalr_o        = 1'b0;
      if(funct7_0_i)ALUop_o = 2'd3;
      else          ALUop_o = 2'd1;
    end
    `ITYPE:begin
      RegWrite_o    = 1'b1;
      ALUsrcAsel_o  = 2'd0;
      ALUsrcBsel_o  = 2'd1;
      MemWrite_o    = 4'hf;
      MemRead_o     = 1'b0;
      Branch_o      = 1'b0;
      Jal_o         = 1'b0;
      Jalr_o        = 1'b0;
      ALUop_o       = 2'd2;
    end 
    `JALR:begin
      RegWrite_o    = 1'b1;
      ALUsrcAsel_o  = 2'd1;
      ALUsrcBsel_o  = 2'd2;
      MemWrite_o    = 4'hf;
      MemRead_o     = 1'b0;
      Branch_o      = 1'b0;
      Jal_o         = 1'b0;
      Jalr_o        = 1'b1;
      ALUop_o       = 2'd0;
    end  
    `LOAD:begin
      RegWrite_o    = 1'b1;
      ALUsrcAsel_o  = 2'd0;
      ALUsrcBsel_o  = 2'd1;
      MemWrite_o    = 4'hf;
      MemRead_o     = 1'b1;
      Branch_o      = 1'b0;
      Jal_o         = 1'b0;
      Jalr_o        = 1'b0;
      ALUop_o       = 2'd0;
    end  
    `STYPE:begin
      RegWrite_o    = 1'b0;
      ALUsrcAsel_o  = 2'd0;
      ALUsrcBsel_o  = 2'd1;
      unique case(funct3_i[1:0])
        2'd0:MemWrite_o  = 4'b1110;// Store Byte
        2'd1:MemWrite_o  = 4'b1100;// Store Half
        2'd2:MemWrite_o  = 4'b0000;// Store Word
        default:MemWrite_o = 4'b1111;
      endcase
      MemRead_o     = 1'b0;
      Branch_o      = 1'b0;
      Jal_o         = 1'b0;
      Jalr_o        = 1'b0;
      ALUop_o       = 2'd0;
    end	
    `BTYPE:begin
      RegWrite_o    = 1'b0;
      ALUsrcAsel_o  = 2'd0;
      ALUsrcBsel_o  = 2'd0;
      MemWrite_o    = 4'hf;
      MemRead_o     = 1'b0;
      Branch_o      = 1'b1;
      Jal_o         = 1'b0;
      Jalr_o        = 1'b0;
      ALUop_o       = 2'd0;
    end	
    `AUIPC:begin
      RegWrite_o    = 1'b1;
      ALUsrcAsel_o  = 2'd1;
      ALUsrcBsel_o  = 2'd1;
      MemWrite_o    = 4'hf;
      MemRead_o     = 1'b0;
      Branch_o      = 1'b0;
      Jal_o         = 1'b0;
      Jalr_o        = 1'b0;
      ALUop_o       = 2'd0;
    end 
    `LUI:begin
      RegWrite_o    = 1'b1;
      ALUsrcAsel_o  = 2'd2;
      ALUsrcBsel_o  = 2'd1;
      MemWrite_o    = 4'hf;
      MemRead_o     = 1'b0;
      Branch_o      = 1'b0;
      Jal_o         = 1'b0;
      Jalr_o        = 1'b0;
      ALUop_o       = 2'd0;
    end   
    `JTYPE:begin
      RegWrite_o    = 1'b1;
      ALUsrcAsel_o  = 2'd1;
      ALUsrcBsel_o  = 2'd2;
      MemWrite_o    = 4'hf;
      MemRead_o     = 1'b0;
      Branch_o      = 1'b0;
      Jal_o         = 1'b1;
      Jalr_o        = 1'b0;
      ALUop_o       = 2'd0;
    end 
    `CSR:begin
      RegWrite_o    = 1'b1;
      ALUsrcAsel_o  = 2'd2;
      ALUsrcBsel_o  = 2'd3;
      MemWrite_o    = 4'hf;
      MemRead_o     = 1'b0;
      Branch_o      = 1'b0;
      Jal_o         = 1'b0;
      Jalr_o        = 1'b0;
      ALUop_o       = 2'd0;
    end
    default:begin
      RegWrite_o    = 1'b0;
      ALUsrcAsel_o  = 2'd0;
      ALUsrcBsel_o  = 2'd0;
      MemWrite_o    = 4'hf;
      MemRead_o     = 1'b0;
      Branch_o      = 1'b0;
      Jal_o         = 1'b0;
      Jalr_o        = 1'b0;
      ALUop_o       = 2'd0;
    end
  endcase
end

endmodule

*/


// ----------------------------------- opcode 7-bits MUX & if -----------------------------------

/*
module Controller(
  opcode_i,
  funct3_i,
  flush_i,
  RegWrite_o,
  ALUsrcAsel_o,
  ALUsrcBsel_o,
  MemWrite_o,
  MemRead_o,
  Branch_o,
  Jal_o,
  Jalr_o,
  ALUop_o
);
//---------------------------------------------------------------------
//        PORTS DECLARATION                             
//---------------------------------------------------------------------
input  logic [`OP_WIDTH-1:0]     opcode_i;
input  logic [2:0]               funct3_i;
input  logic                      flush_i;//prevent the nop instruction(for Load type)
output logic                   RegWrite_o;
output logic [1:0]           ALUsrcAsel_o;
output logic [1:0]           ALUsrcBsel_o;
output logic [3:0]             MemWrite_o;
output logic                    MemRead_o;
output logic                     Branch_o;
output logic                        Jal_o;
output logic                       Jalr_o;
output logic [1:0]                ALUop_o;
//---------------------------------------------------------------------
//        LOGIC & VARIABLES DECLARATION                            
//---------------------------------------------------------------------
logic                            no_flush;
assign no_flush = ~flush_i;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                            Control Signal Table                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// |  opcode_i  | RegWrite_o | ALUsrcAsel_o | ALUsrcBsel_o | MemWrite_o | MemRead_o | Branch_o | Jal_o | Jalr_o | ALUop_o  |                 Description                 |//
// |------------+------------+--------------+--------------+------------+-----------+----------+-------+--------+----------+---------------------------------------------|//
// |  5'b01100  |     1      |      0       |      0       |     f      |     0     |     0    |   0   |    0   |     1    | RTYPE                                       |//
// |  5'b00100  |     1      |      0       |      1       |     f      |     0     |     0    |   0   |    0   |     2    | ITYPE (RTYPE imm)                           |//
// |  5'b11001  |     1      |      1       |      2       |     f      |     0     |     0    |   0   |    1   |     0    | JALR  (rd = PC + 4 ; PC = imm + rs1)        |//
// |  5'b00000  |     1      |      0       |      1       |     f      |     1     |     0    |   0   |    0   |     0    | LOAD  (rd = Mem[rs1+imm])                   |//
// |  5'b01000  |     0      |      0       |      1       |    case    |     0     |     0    |   0   |    0   |     0    | STYPE (Mem[rs1+imm] = rs2)                  |//
// |  5'b11000  |     0      |      0       |      0       |     f      |     0     |     1    |   0   |    0   |     0    | BTYPE (Compare rs1 & rs2 -> PC = PC + imm/4)|//
// |  5'b00101  |     1      |      1       |      1       |     f      |     0     |     0    |   0   |    0   |     0    | AUIPC (rd = PC + imm)                       |//
// |  5'b01101  |     1      |      2       |      1       |     f      |     0     |     0    |   0   |    0   |     0    | LUI   (rd = imm)                            |//
// |  5'b11011  |     1      |      1       |      2       |     f      |     0     |     0    |   1   |    0   |     0    | JTYPE (rd = PC + 4 ; PC = PC + imm)         |//
// |  5'b11100  |     1      |      2       |      3       |     f      |     0     |     0    |   0   |    0   |     0    | CSR   (rd = cycle or instret)               |//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// ========================= Note =========================

// << ALUsrcAsel_o >>
// 0 : srcA or Forwarding
// 1 : PC
// 2 : 32'd0
// 3 : don't care

// << ALUsrcBsel_o >>
// 0 : srcB or Forwarding
// 1 : immediate value
// 2 : 32'd4
// 3 : CSR value

//---------------------------------------------------------------------
//        ALWAYS BLOCK                             
//---------------------------------------------------------------------

// << RegWrite_o >>
always_comb begin
  unique case(opcode_i)
    `RTYPE, `ITYPE, `LOAD, `JALR, `AUIPC, `LUI, `JTYPE, `CSR:RegWrite_o = 1'b1;
    default:RegWrite_o = 1'b0;
  endcase
end

// << ALUsrcAsel_o >>
always_comb begin
  unique case(opcode_i)
    `JALR, `AUIPC, `JTYPE:ALUsrcAsel_o = 2'd1;// PC
    `LUI, `CSR:           ALUsrcAsel_o = 2'd2;// 32'd0
    default:              ALUsrcAsel_o = 2'd0;// rs1 or Forwarding
  endcase
end

// << ALUsrcBsel_o >>
always_comb begin
  unique case(opcode_i)
    `ITYPE, `STYPE, `LOAD, `AUIPC, `LUI:ALUsrcBsel_o = 2'd1;// immediate
    `JALR, `JTYPE:                      ALUsrcBsel_o = 2'd2;// 32'd4
    `CSR:                               ALUsrcBsel_o = 2'd3;// CSR value
    default:                            ALUsrcBsel_o = 2'd0;// rs2 or Forwarding
  endcase
end

// << MemWrite_o >>
always_comb begin
  unique if(opcode_i == `STYPE)begin
    unique case(funct3_i[1:0])
      2'd0:MemWrite_o = 4'b1110;// Store Byte
      2'd1:MemWrite_o = 4'b1100;// Store Half
      2'd2:MemWrite_o = 4'b0000;// Store Word
      default:MemWrite_o = 4'b1111;
    endcase
  end
  else begin
    MemWrite_o = 4'b1111;
  end 
end

// << MemRead_o >>
always_comb begin
  unique if(opcode_i == `LOAD)MemRead_o = 1'b1;
  else                        MemRead_o = 1'b0;
end

// << Branch_o >>
always_comb begin
  unique if(opcode_i == `BTYPE)Branch_o = 1'b1;
  else                         Branch_o = 1'b0;
end

// << Jal_o >>
always_comb begin
  unique if(opcode_i == `JTYPE)Jal_o = 1'b1;
  else                         Jal_o = 1'b0;
end

// << Jalr_o >>
always_comb begin
  unique if(opcode_i == `JALR)Jalr_o = 1'b1;
  else                        Jalr_o = 1'b0;
end

// << ALUop_o >>
always_comb begin
  unique case(opcode_i)
    `RTYPE: ALUop_o = 2'd1;
    `ITYPE: ALUop_o = 2'd2;
    default:ALUop_o = 2'd0;
  endcase
end

endmodule
*/



// ----------------------------------- opcode 5-bits ALL MUX -----------------------------------

/*
module Controller(
  opcode_i,
  funct3_i,
  flush_i,
  RegWrite_o,
  ALUsrcAsel_o,
  ALUsrcBsel_o,
  MemWrite_o,
  MemRead_o,
  Branch_o,
  Jal_o,
  Jalr_o,
  ALUop_o
);
//---------------------------------------------------------------------
//        PORTS DECLARATION                             
//---------------------------------------------------------------------
input  logic [`OP_WIDTH-1:0]     opcode_i;
input  logic [2:0]               funct3_i;
input  logic                      flush_i;//prevent the nop instruction(for Load type)
output logic                   RegWrite_o;
output logic [1:0]           ALUsrcAsel_o;
output logic [1:0]           ALUsrcBsel_o;
output logic [3:0]             MemWrite_o;
output logic                    MemRead_o;
output logic                     Branch_o;
output logic                        Jal_o;
output logic                       Jalr_o;
output logic [1:0]                ALUop_o;
//---------------------------------------------------------------------
//        LOGIC & VARIABLES DECLARATION                            
//---------------------------------------------------------------------
logic                            no_flush;
assign no_flush = ~flush_i;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                            Control Signal Table                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// |  opcode_i  | RegWrite_o | ALUsrcAsel_o | ALUsrcBsel_o | MemWrite_o | MemRead_o | Branch_o | Jal_o | Jalr_o | ALUop_o  |                 Description                 |//
// |------------+------------+--------------+--------------+------------+-----------+----------+-------+--------+----------+---------------------------------------------|//
// |  5'b01100  |     1      |      0       |      0       |     f      |     0     |     0    |   0   |    0   |     1    | RTYPE                                       |//
// |  5'b00100  |     1      |      0       |      1       |     f      |     0     |     0    |   0   |    0   |     2    | ITYPE (RTYPE imm)                           |//
// |  5'b11001  |     1      |      1       |      2       |     f      |     0     |     0    |   0   |    1   |     0    | JALR  (rd = PC + 4 ; PC = imm + rs1)        |//
// |  5'b00000  |     1      |      0       |      1       |     f      |     1     |     0    |   0   |    0   |     0    | LOAD  (rd = Mem[rs1+imm])                   |//
// |  5'b01000  |     0      |      0       |      1       |    case    |     0     |     0    |   0   |    0   |     0    | STYPE (Mem[rs1+imm] = rs2)                  |//
// |  5'b11000  |     0      |      0       |      0       |     f      |     0     |     1    |   0   |    0   |     0    | BTYPE (Compare rs1 & rs2 -> PC = PC + imm/4)|//
// |  5'b00101  |     1      |      1       |      1       |     f      |     0     |     0    |   0   |    0   |     0    | AUIPC (rd = PC + imm)                       |//
// |  5'b01101  |     1      |      2       |      1       |     f      |     0     |     0    |   0   |    0   |     0    | LUI   (rd = imm)                            |//
// |  5'b11011  |     1      |      1       |      2       |     f      |     0     |     0    |   1   |    0   |     0    | JTYPE (rd = PC + 4 ; PC = PC + imm)         |//
// |  5'b11100  |     1      |      2       |      3       |     f      |     0     |     0    |   0   |    0   |     0    | CSR   (rd = cycle or instret)               |//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// ========================= Note =========================

// << ALUsrcAsel_o >>
// 0 : srcA or Forwarding
// 1 : PC
// 2 : 32'd0
// 3 : don't care

// << ALUsrcBsel_o >>
// 0 : srcB or Forwarding
// 1 : immediate value
// 2 : 32'd4
// 3 : CSR value

//---------------------------------------------------------------------
//        ALWAYS BLOCK                             
//---------------------------------------------------------------------

always_comb begin
  RegWrite_o    = 1'b0;
  ALUsrcAsel_o  = 2'd0;
  ALUsrcBsel_o  = 2'd0;
  MemWrite_o    = 4'hf;
  MemRead_o     = 1'b0;
  Branch_o      = 1'b0;
  Jal_o         = 1'b0;
  Jalr_o        = 1'b0;
  ALUop_o       = 2'd0;
  unique case(opcode_i)
    `RTYPE:begin
      RegWrite_o    = 1'b1;
      ALUsrcAsel_o  = 2'd0;
      ALUsrcBsel_o  = 2'd0;
      MemWrite_o    = 4'hf;
      MemRead_o     = 1'b0;
      Branch_o      = 1'b0;
      Jal_o         = 1'b0;
      Jalr_o        = 1'b0;
      ALUop_o       = 2'd1;
    end
    `ITYPE:begin
      RegWrite_o    = 1'b1;
      ALUsrcAsel_o  = 2'd0;
      ALUsrcBsel_o  = 2'd1;
      MemWrite_o    = 4'hf;
      MemRead_o     = 1'b0;
      Branch_o      = 1'b0;
      Jal_o         = 1'b0;
      Jalr_o        = 1'b0;
      ALUop_o       = 2'd2;
    end 
    `JALR:begin
      RegWrite_o    = 1'b1;
      ALUsrcAsel_o  = 2'd1;
      ALUsrcBsel_o  = 2'd2;
      MemWrite_o    = 4'hf;
      MemRead_o     = 1'b0;
      Branch_o      = 1'b0;
      Jal_o         = 1'b0;
      Jalr_o        = 1'b1;
      ALUop_o       = 2'd0;
    end  
    `LOAD:begin
      RegWrite_o    = no_flush;
      ALUsrcAsel_o  = 2'd0;
      ALUsrcBsel_o  = 2'd1 & {2{no_flush}};
      MemWrite_o    = 4'hf;
      MemRead_o     = no_flush;
      Branch_o      = 1'b0;
      Jal_o         = 1'b0;
      Jalr_o        = 1'b0;
      ALUop_o       = 2'd0;
    end  
    `STYPE:begin
      RegWrite_o    = 1'b0;
      ALUsrcAsel_o  = 2'd0;
      ALUsrcBsel_o  = 2'd1;
      unique case(funct3_i[1:0])
        2'd0:MemWrite_o  = 4'b1110;// Store Byte
        2'd1:MemWrite_o  = 4'b1100;// Store Half
        2'd2:MemWrite_o  = 4'b0000;// Store Word
        default:MemWrite_o = 4'b1111;
      endcase
      MemRead_o     = 1'b0;
      Branch_o      = 1'b0;
      Jal_o         = 1'b0;
      Jalr_o        = 1'b0;
      ALUop_o       = 2'd0;
    end	
    `BTYPE:begin
      RegWrite_o    = 1'b0;
      ALUsrcAsel_o  = 2'd0;
      ALUsrcBsel_o  = 2'd0;
      MemWrite_o    = 4'hf;
      MemRead_o     = 1'b0;
      Branch_o      = 1'b1;
      Jal_o         = 1'b0;
      Jalr_o        = 1'b0;
      ALUop_o       = 2'd0;
    end	
    `AUIPC:begin
      RegWrite_o    = 1'b1;
      ALUsrcAsel_o  = 2'd1;
      ALUsrcBsel_o  = 2'd1;
      MemWrite_o    = 4'hf;
      MemRead_o     = 1'b0;
      Branch_o      = 1'b0;
      Jal_o         = 1'b0;
      Jalr_o        = 1'b0;
      ALUop_o       = 2'd0;
    end 
    `LUI:begin
      RegWrite_o    = 1'b1;
      ALUsrcAsel_o  = 2'd2;
      ALUsrcBsel_o  = 2'd1;
      MemWrite_o    = 4'hf;
      MemRead_o     = 1'b0;
      Branch_o      = 1'b0;
      Jal_o         = 1'b0;
      Jalr_o        = 1'b0;
      ALUop_o       = 2'd0;
    end   
    `JTYPE:begin
      RegWrite_o    = 1'b1;
      ALUsrcAsel_o  = 2'd1;
      ALUsrcBsel_o  = 2'd2;
      MemWrite_o    = 4'hf;
      MemRead_o     = 1'b0;
      Branch_o      = 1'b0;
      Jal_o         = 1'b1;
      Jalr_o        = 1'b0;
      ALUop_o       = 2'd0;
    end 
    `CSR:begin
      RegWrite_o    = 1'b1;
      ALUsrcAsel_o  = 2'd2;
      ALUsrcBsel_o  = 2'd3;
      MemWrite_o    = 4'hf;
      MemRead_o     = 1'b0;
      Branch_o      = 1'b0;
      Jal_o         = 1'b0;
      Jalr_o        = 1'b0;
      ALUop_o       = 2'd0;
    end
    default:begin
      RegWrite_o    = 1'b0;
      ALUsrcAsel_o  = 2'd0;
      ALUsrcBsel_o  = 2'd0;
      MemWrite_o    = 4'hf;
      MemRead_o     = 1'b0;
      Branch_o      = 1'b0;
      Jal_o         = 1'b0;
      Jalr_o        = 1'b0;
      ALUop_o       = 2'd0;
    end
  endcase
end

endmodule
*/

// ----------------------------------- opcode 5-bits MUX & if -----------------------------------

/*
module Controller(
  opcode_i,
  funct3_i,
  flush_i,
  RegWrite_o,
  ALUsrcAsel_o,
  ALUsrcBsel_o,
  MemWrite_o,
  MemRead_o,
  Branch_o,
  Jal_o,
  Jalr_o,
  ALUop_o
);
//---------------------------------------------------------------------
//        PORTS DECLARATION                             
//---------------------------------------------------------------------
input  logic [`OP_WIDTH-1:0]     opcode_i;
input  logic [2:0]               funct3_i;
input  logic                      flush_i;//prevent the nop instruction(for Load type)
output logic                   RegWrite_o;
output logic [1:0]           ALUsrcAsel_o;
output logic [1:0]           ALUsrcBsel_o;
output logic [3:0]             MemWrite_o;
output logic                    MemRead_o;
output logic                     Branch_o;
output logic                        Jal_o;
output logic                       Jalr_o;
output logic [1:0]                ALUop_o;
//---------------------------------------------------------------------
//        LOGIC & VARIABLES DECLARATION                            
//---------------------------------------------------------------------
logic                            no_flush;
assign no_flush = ~flush_i;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                            Control Signal Table                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// |  opcode_i  | RegWrite_o | ALUsrcAsel_o | ALUsrcBsel_o | MemWrite_o | MemRead_o | Branch_o | Jal_o | Jalr_o | ALUop_o  |                 Description                 |//
// |------------+------------+--------------+--------------+------------+-----------+----------+-------+--------+----------+---------------------------------------------|//
// |  5'b01100  |     1      |      0       |      0       |     f      |     0     |     0    |   0   |    0   |     1    | RTYPE                                       |//
// |  5'b00100  |     1      |      0       |      1       |     f      |     0     |     0    |   0   |    0   |     2    | ITYPE (RTYPE imm)                           |//
// |  5'b11001  |     1      |      1       |      2       |     f      |     0     |     0    |   0   |    1   |     0    | JALR  (rd = PC + 4 ; PC = imm + rs1)        |//
// |  5'b00000  |     1      |      0       |      1       |     f      |     1     |     0    |   0   |    0   |     0    | LOAD  (rd = Mem[rs1+imm])                   |//
// |  5'b01000  |     0      |      0       |      1       |    case    |     0     |     0    |   0   |    0   |     0    | STYPE (Mem[rs1+imm] = rs2)                  |//
// |  5'b11000  |     0      |      0       |      0       |     f      |     0     |     1    |   0   |    0   |     0    | BTYPE (Compare rs1 & rs2 -> PC = PC + imm/4)|//
// |  5'b00101  |     1      |      1       |      1       |     f      |     0     |     0    |   0   |    0   |     0    | AUIPC (rd = PC + imm)                       |//
// |  5'b01101  |     1      |      2       |      1       |     f      |     0     |     0    |   0   |    0   |     0    | LUI   (rd = imm)                            |//
// |  5'b11011  |     1      |      1       |      2       |     f      |     0     |     0    |   1   |    0   |     0    | JTYPE (rd = PC + 4 ; PC = PC + imm)         |//
// |  5'b11100  |     1      |      2       |      3       |     f      |     0     |     0    |   0   |    0   |     0    | CSR   (rd = cycle or instret)               |//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// ========================= Note =========================

// << ALUsrcAsel_o >>
// 0 : srcA or Forwarding
// 1 : PC
// 2 : 32'd0
// 3 : don't care

// << ALUsrcBsel_o >>
// 0 : srcB or Forwarding
// 1 : immediate value
// 2 : 32'd4
// 3 : CSR value

//---------------------------------------------------------------------
//        ALWAYS BLOCK                             
//---------------------------------------------------------------------

// << RegWrite_o >>
always_comb begin
  unique case(opcode_i)
    `RTYPE, `ITYPE, `JALR, `AUIPC, `LUI, `JTYPE, `CSR:RegWrite_o = 1'b1;
    `LOAD:RegWrite_o = no_flush;
    default:RegWrite_o = 1'b0;
  endcase
end

// << ALUsrcAsel_o >>
always_comb begin
  unique case(opcode_i)
    `JALR, `AUIPC, `JTYPE:ALUsrcAsel_o = 2'd1;// PC
    `LUI, `CSR:           ALUsrcAsel_o = 2'd2;// 32'd0
    default:              ALUsrcAsel_o = 2'd0;// rs1 or Forwarding
  endcase
end

// << ALUsrcBsel_o >>
always_comb begin
  unique case(opcode_i)
    `ITYPE, `STYPE, `AUIPC, `LUI:ALUsrcBsel_o = 2'd1;// immediate
    `LOAD:                       ALUsrcBsel_o = 2'd1 & {2{no_flush}};// immediate
    `JALR, `JTYPE:               ALUsrcBsel_o = 2'd2;// 32'd4
    `CSR:                        ALUsrcBsel_o = 2'd3;// CSR value
    default:                     ALUsrcBsel_o = 2'd0;// rs2 or Forwarding
  endcase
end

// << MemWrite_o >>
always_comb begin
  unique if(opcode_i == `STYPE)begin
    unique case(funct3_i[1:0])
      2'd0:MemWrite_o = 4'b1110;// Store Byte
      2'd1:MemWrite_o = 4'b1100;// Store Half
      2'd2:MemWrite_o = 4'b0000;// Store Word
      default:MemWrite_o = 4'b1111;
    endcase
  end
  else begin
    MemWrite_o = 4'b1111;
  end 
end

// << MemRead_o >>
always_comb begin
  unique if(opcode_i == `LOAD)MemRead_o = no_flush;
  else                        MemRead_o = 1'b0;
end

// << Branch_o >>
always_comb begin
  unique if(opcode_i == `BTYPE)Branch_o = 1'b1;
  else                         Branch_o = 1'b0;
end

// << Jal_o >>
always_comb begin
  unique if(opcode_i == `JTYPE)Jal_o = 1'b1;
  else                         Jal_o = 1'b0;
end

// << Jalr_o >>
always_comb begin
  unique if(opcode_i == `JALR)Jalr_o = 1'b1;
  else                        Jalr_o = 1'b0;
end

// << ALUop_o >>
always_comb begin
  unique case(opcode_i)
    `RTYPE: ALUop_o = 2'd1;
    `ITYPE: ALUop_o = 2'd2;
    default:ALUop_o = 2'd0;
  endcase
end

endmodule

*/






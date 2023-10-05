module ALU(
  srcA_i,
  srcB_i,
  ALUctrl_i,
  sign_i,
  ALUresult_o
);
//---------------------------------------------------------------------
//        PORTS DECLARATION                             
//---------------------------------------------------------------------
input  logic signed [`DATA_WIDTH-1:0]      srcA_i;
input  logic signed [`DATA_WIDTH-1:0]      srcB_i;
input  logic signed [3:0]               ALUctrl_i;
input  logic                               sign_i;
output logic signed [`DATA_WIDTH-1:0] ALUresult_o;
//---------------------------------------------------------------------
//        LOGIC & VARIABLES DECLARATION                            
//---------------------------------------------------------------------
logic  [`DATA_WIDTH-1:0]            srcA_unsigned;
logic  [`DATA_WIDTH-1:0]            srcB_unsigned;
logic  signed [`DATA_WIDTH:0]            mul_srcA;
logic  signed [`DATA_WIDTH:0]            mul_srcB;
logic  signed [`DATA_WIDTH*2+1:0]       mulResult;
//---------------------------------------------------------------------
//        WIRE CONNECTION                             
//---------------------------------------------------------------------
assign srcA_unsigned = srcA_i;
assign srcB_unsigned = srcB_i;
assign mulResult = mul_srcA * mul_srcB;
//---------------------------------------------------------------------
//        ALWAYS BLOCK                             
//---------------------------------------------------------------------

// << mul_srcA >> 
always_comb begin
  unique case(ALUctrl_i)
    `MUL:   mul_srcA = {1'b0, srcA_unsigned};
    `MULH:  mul_srcA = {srcA_i[31], srcA_i};
    `MULHSU:mul_srcA = {srcA_i[31], srcA_i};
    `MULHU: mul_srcA = {1'b0, srcA_unsigned};
    default:mul_srcA = 33'd0;
  endcase
end

// << mul_srcB >> 
always_comb begin
  unique case(ALUctrl_i)
    `MUL:   mul_srcB = {1'b0, srcB_unsigned};
    `MULH:  mul_srcB = {srcB_i[31], srcB_i};
    `MULHSU:mul_srcB = {1'b0, srcB_unsigned};
    `MULHU: mul_srcB = {1'b0, srcB_unsigned};
    default:mul_srcB = 33'd0;
  endcase
end

// << ALUresult_o >>
always_comb begin
  unique case(ALUctrl_i)
    `ADD:              ALUresult_o = srcA_i + srcB_i;
    `SUB:              ALUresult_o = srcA_i - srcB_i;
    `SLL:              ALUresult_o = srcA_i << srcB_i[4:0];
    `SLT_SLTU:begin
      unique if(sign_i)ALUresult_o = ( srcA_i < srcB_i )?(32'd1):(32'd0);
      else             ALUresult_o = (srcA_unsigned < srcB_unsigned)?(32'd1):(32'd0);
    end
    `XOR:              ALUresult_o = srcA_i ^ srcB_i;
    `SRL_SRA:begin
      unique if(sign_i)ALUresult_o = srcA_i >>> srcB_i[4:0];
      else             ALUresult_o = srcA_unsigned >> srcB_unsigned[4:0];
    end
    `OR:               ALUresult_o = srcA_i | srcB_i;
    `AND:              ALUresult_o = srcA_i & srcB_i;
    `MUL:              ALUresult_o = mulResult[31: 0];
    `MULH:             ALUresult_o = mulResult[63:32];
    `MULHSU:           ALUresult_o = mulResult[63:32];
    `MULHU:            ALUresult_o = mulResult[63:32];
    default:           ALUresult_o = 32'd0;
  endcase
end


endmodule

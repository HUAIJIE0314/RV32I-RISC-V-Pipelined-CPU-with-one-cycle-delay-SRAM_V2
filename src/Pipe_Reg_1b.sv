module Pipe_Reg_1b(
  clk_i,
  rst_i,
  data_i,
  data_o
);
//---------------------------------------------------------------------
//        PORTS DECLARATION                             
//---------------------------------------------------------------------
input  logic              clk_i;
input  logic              rst_i;
input  logic             data_i;
output logic             data_o;

//---------------------------------------------------------------------
//        ALWAYS BLOCK                             
//---------------------------------------------------------------------
always_ff@(posedge clk_i or posedge rst_i)begin
  if(rst_i)data_o <= 1'b0;
  else data_o <= data_i;
end

endmodule
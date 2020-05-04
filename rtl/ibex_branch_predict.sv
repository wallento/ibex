module ibex_branch_predict (
  input [31:0]  fetch_rdata,
  input [31:0]  fetch_pc,
  input         fetch_valid,

  output        predict_branch_taken_o,
  output [31:0] predict_branch_pc_o
);
  import ibex_pkg::*;

  logic [31:0] imm_j_type;
  logic [31:0] imm_b_type;
  logic [31:0] imm_cj_type;
  logic [31:0] imm_cb_type;

  logic [31:0] branch_imm;

  logic instr_j;
  logic instr_b;
  logic instr_cj;
  logic instr_cb;

  logic instr_b_taken;

  assign imm_j_type = { {12{fetch_rdata[31]}}, fetch_rdata[19:12], fetch_rdata[20], fetch_rdata[30:21], 1'b0 };
  assign imm_b_type = { {19{fetch_rdata[31]}}, fetch_rdata[31], fetch_rdata[7], fetch_rdata[30:25], fetch_rdata[11:8], 1'b0 };

  assign imm_cj_type = { {20{fetch_rdata[12]}}, fetch_rdata[12], fetch_rdata[8], fetch_rdata[10:9],
    fetch_rdata[6], fetch_rdata[7], fetch_rdata[2], fetch_rdata[11], fetch_rdata[5:3], 1'b0 };

  assign imm_cb_type = { {23{fetch_rdata[12]}}, fetch_rdata[12], fetch_rdata[6:5], fetch_rdata[2],
    fetch_rdata[11:10], fetch_rdata[4:3], 1'b0};


  assign instr_b = opcode_e'(fetch_rdata[6:0]) == OPCODE_BRANCH;
  assign instr_j = opcode_e'(fetch_rdata[6:0]) == OPCODE_JAL;
  assign instr_cb = (fetch_rdata[1:0] == 2'b01) && ((fetch_rdata[15:13] == 3'b110) | (fetch_rdata[15:13] == 3'b111));
  assign instr_cj = (fetch_rdata[1:0] == 2'b01) && ((fetch_rdata[15:13] == 3'b101) | (fetch_rdata[15:13] == 3'b001));

  always_comb begin
    branch_imm = imm_b_type;

    unique case (1'b1)
      instr_j  : branch_imm = imm_j_type;
      instr_b  : branch_imm = imm_b_type;
      instr_cj : branch_imm = imm_cj_type;
      instr_cb : branch_imm = imm_cb_type;
      default : ;
    endcase
  end

  assign instr_b_taken = (instr_b && imm_b_type[31]) || (instr_cb && imm_cb_type[31]);

  //assign predict_branch_taken_o = 1'b0;
  assign predict_branch_taken_o = fetch_valid & (instr_j | instr_cj | instr_b_taken);
  assign predict_branch_pc_o    = fetch_pc + branch_imm;
endmodule

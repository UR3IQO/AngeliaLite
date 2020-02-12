
`timescale 1us/1ns

module mix_tx (
  clk,
  rst,
  phi,
  i_data,
  q_data,
  dac
);

input                 clk;
input                 rst;
input         [31:0]  phi;
output reg signed [13:0]  dac;
input signed [17:0]  i_data;
input signed [17:0]  q_data;

logic         [18:0]  sin, ssin;
logic         [18:0]  cos, scos;

reg  signed [17:0]  ssin_q, scos_q;
 
reg  signed [35:0]  dac_d;  

nco1 #(.CALCTYPE(4)) nco1_i (
  .clk(clk),
  .rst(rst),
  .phi(phi),
  .cos(cos),
  .sin(sin)
);

assign ssin = {sin[18],~sin[17:0]} + 19'h01;
assign scos = {cos[18],~cos[17:0]} + 19'h01;

always @(posedge clk) begin
  ssin_q <= sin[18] ? ssin[18:1] : sin[18:1];
  scos_q <= cos[18] ? scos[18:1] : cos[18:1];
end


always @(posedge clk) begin
  dac_d <= $signed(i_data) * scos_q + $signed(q_data) * ssin_q;
  dac <= dac_d[34:21] + {13'h00,dac_d[20]};
end


endmodule 



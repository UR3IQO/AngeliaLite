
`timescale 1us/1ns

module mix2 (
  clk,
  clk_2x,
  rst,
  phi0,
  phi1,
  adc0,
  adc1,
  mixdata0_i,
  mixdata0_q,
  mixdata1_i,
  mixdata1_q
);

input                 clk;
input                 clk_2x;
input                 rst;
input         [31:0]  phi0;
input         [31:0]  phi1;
input  signed [13:0]  adc0;
input  signed [13:0]  adc1;
output reg signed [17:0]  mixdata0_i;
output reg signed [17:0]  mixdata0_q;
output reg signed [17:0]  mixdata1_i;
output reg signed [17:0]  mixdata1_q;

parameter CALCTYPE = 0;

logic         [18:0]  sin, ssin;
logic         [18:0]  cos, scos;

logic  signed [17:0]  ssin_q, scos_q;
reg  signed [35:0]  i_data_d, q_data_d;  
reg  signed [17:0]  i_rounded, q_rounded;
reg  signed [17:0]  i_rounded0, q_rounded0;
reg  signed [17:0]  i_rounded1, q_rounded1;

reg signed  [13:0]  adci0, adci1, adcq0, adcq1;

wire state;
assign state = clk;


nco2 #(.CALCTYPE(CALCTYPE)) nco2_i (
  .state(state),
  .clk_2x(clk_2x),
  .rst(rst),
  .phi0(phi0),
  .phi1(phi1),
  .cos(cos),
  .sin(sin)
);


assign ssin = {sin[18],~sin[17:0]} + 19'h01;
assign scos = {cos[18],~cos[17:0]} + 19'h01;

always @(posedge clk_2x) begin
  ssin_q <= sin[18] ? ssin[18:1] : sin[18:1];
  scos_q <= cos[18] ? scos[18:1] : cos[18:1];
end

always @(posedge clk_2x) 
begin
 if (state) 
   begin
      adci0 <= adc1;
      adcq0 <= adc1;
   end 
   else 
   begin
      adci0 <= adc0;
      adcq0 <= adc0;
   end    
end

always @(posedge clk_2x) 
begin
   i_data_d <= $signed(adci0) * scos_q;
   q_data_d <= $signed(adcq0) * ssin_q;
end

always@(posedge clk_2x) 
begin
   i_rounded <= i_data_d[30:13] + {17'h00,i_data_d[12]};
   q_rounded <= q_data_d[30:13] + {17'h00,q_data_d[12]};      
end


always @(posedge clk_2x) 
begin
   if (state) 
   begin
      i_rounded0 <= i_rounded;
      q_rounded0 <= q_rounded;
   end 
   else 
   begin
      i_rounded1 <= i_rounded;
      q_rounded1 <= q_rounded;
   end
end

always @(posedge clk)
begin
    mixdata0_i <= i_rounded0;
    mixdata0_q <= q_rounded0;
    mixdata1_i <= i_rounded1;
    mixdata1_q <= q_rounded1;
end


endmodule 



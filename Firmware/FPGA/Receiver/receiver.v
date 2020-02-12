/*
--------------------------------------------------------------------------------
This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.
This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.
You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the
Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
Boston, MA  02110-1301, USA.
--------------------------------------------------------------------------------
*/


//------------------------------------------------------------------------------
//           Copyright (c) 2008 Alex Shovkoplyas, VE3NEA
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//           Copyright (c) 2013 Phil Harman, VK6APH 
//------------------------------------------------------------------------------

// 2013 Jan 26 - varcic now accepts 2...40 as decimation and CFIR
//               replaced with Polyphase FIR - VK6APH

// 2015 Jan 31 - updated for Hermes-Lite 12bit Steve Haynal KF7O

//April 2019 - changed to use in AngeliaLite by Oleg Skydan UR3IQO

module receiver(
  input reset,
  input clock,                  //77.760 MHz
  input [15:0] sample_rate,             //48k....192k
  output out_strobe,
  input signed [17:0] in_data_I,
  input signed [17:0] in_data_Q,
  output [23:0] out_data_I,
  output [23:0] out_data_Q
  );

parameter CICRATE = 9;

// Select CIC decimation rates based on sample_rate
reg [5:0] rate;

always @ (sample_rate)				
begin 
   case (sample_rate)	
      16'd48: rate <= 6'd20;
      16'd96: rate <= 6'd10;		 
      16'd192: rate <= 6'd5;		  
      default: rate <= 6'd20;
   endcase
end 

reg signed [17:0] in_data_Ir;
reg signed [17:0] in_data_Qr;

//Register input data
always @(posedge clock)
begin
   in_data_Ir <= in_data_I;
   in_data_Qr <= in_data_Q;
end

wire signed [23:0] out_data_I2;
wire signed [23:0] out_data_Q2;
assign out_data_I = out_data_I2; //<<< 3);
assign out_data_Q = out_data_Q2; //<<< 3);


//------------------------------------------------------------------------------
//                     register-based CIC decimator
//------------------------------------------------------------------------------
//3 stages CIC decimator
//R = 9
//Amin = -116.426653dB
//BWmin = -0.005213dB
//ACCgrow = 10.000000 bits
//OUTgrow = 2.000000 bits
//I channel
cic #(.STAGES(3), .DECIMATION(CICRATE), .IN_WIDTH(18), .ACC_WIDTH(28), .OUT_WIDTH(20))
  cic_inst_I1(
    .clock(clock),
    .in_strobe(1'b1),
    .out_strobe(cic_outstrobe_1),
    .in_data(in_data_Ir),
    .out_data(cic_outdata_I1)
    );

//Q channel
cic #(.STAGES(3), .DECIMATION(CICRATE), .IN_WIDTH(18), .ACC_WIDTH(28), .OUT_WIDTH(20))
  cic_inst_Q1(
    .clock(clock),
    .in_strobe(1'b1),
    .out_strobe(),
    .in_data(in_data_Qr),
    .out_data(cic_outdata_Q1)
    );

wire cic_outstrobe_1;
wire signed [19:0] cic_outdata_I1;
wire signed [19:0] cic_outdata_Q1;

//2nd CIC
//5 stages CIC decimator
//R = 20, output samplerate 9*48kSPS
//Amin = -123.092295dB
//BWmin = -0.219813dB
//ACCgrow = 22.000000 bits
//OUTgrow = 3.000000 bits
//
//R = 10, output samplerate 9*96kSPS
//Amin = -122.612638dB
//BWmin = -0.218402dB
//ACCgrow = 17.000000 bits
//OUTgrow = 2.000000 bits
//
//R = 5, output samplerate 9*192kSPS
//Amin = -120.684762dB
//BWmin = -0.211849dB
//ACCgrow = 12.000000 bits
//OUTgrow = 2.000000 bits


//I channel
varcic #(.STAGES(5), .IN_WIDTH(20), .ACC_WIDTH(42), .OUT_WIDTH(18))
  varcic_inst_I1(
    .clock(clock),
    .in_strobe(cic_outstrobe_1),
    .decimation(rate),
    .out_strobe(cic_outstrobe_2),
    .in_data(cic_outdata_I1),
    .out_data(cic_outdata_I2)
    );

//Q channel
varcic #(.STAGES(5), .IN_WIDTH(20), .ACC_WIDTH(42), .OUT_WIDTH(18))
  varcic_inst_Q1(
    .clock(clock),
    .in_strobe(cic_outstrobe_1),
    .decimation(rate),
    .out_strobe(),
    .in_data(cic_outdata_Q1),
    .out_data(cic_outdata_Q2)
    );

wire cic_outstrobe_2;
wire signed [17:0] cic_outdata_I2;
wire signed [17:0] cic_outdata_Q2;


//firX5R5 fir2 (clock, cic_outstrobe_2, cic_outdata_I2, cic_outdata_Q2, out_strobe, out_data_I2, out_data_Q2);
FIRDecim fir2 (.clock(clock), 
               .strobe_in(cic_outstrobe_2), 
               .x_real(cic_outdata_I2), 
               .x_imag(cic_outdata_Q2), 
               .strobe_out(out_strobe), 
               .y_real(out_data_I2), 
               .y_imag(out_data_Q2));


endmodule

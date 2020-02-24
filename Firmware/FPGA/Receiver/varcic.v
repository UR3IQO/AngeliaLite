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

// 2013 Jan 26	- Modified to accept decimation values from 1-40. VK6APH 
// April 2019 - changed to use in AngeliaLite by Oleg Skydan UR3IQO


module varcic(decimation, clock, in_strobe,  out_strobe, in_data, out_data );

  //design parameters
  parameter STAGES = 5;
  parameter IN_WIDTH = 18;
  parameter ACC_WIDTH = 45;
  parameter OUT_WIDTH = 18;
  
  input [5:0] decimation; 
  
  input clock;
  input in_strobe;
  output reg out_strobe;

  input signed [IN_WIDTH-1:0] in_data;
  output reg signed [OUT_WIDTH-1:0] out_data;


//------------------------------------------------------------------------------
//                               control
//------------------------------------------------------------------------------
reg [15:0] sample_no;
initial sample_no = 16'd0;


always @(posedge clock)
  if (in_strobe)
    begin
    if (sample_no == (decimation - 1))
      begin
      sample_no <= 0;
      out_strobe <= 1;
      end
    else
      begin
      sample_no <= sample_no + 8'd1;
      out_strobe <= 0;
      end
    end

   else
     out_strobe <= 0;


//------------------------------------------------------------------------------
//                                stages
//------------------------------------------------------------------------------
wire signed [ACC_WIDTH-1:0] integrator_data [0:STAGES];
wire signed [ACC_WIDTH-1:0] comb_data [0:STAGES];


assign integrator_data[0] = in_data;
assign comb_data[0] = integrator_data[STAGES];


genvar i;
generate
  for (i=0; i<STAGES; i=i+1)
    begin : cic_stages

    cic_integrator #(ACC_WIDTH) cic_integrator_inst(
      .clock(clock),
      .strobe(in_strobe),
      .in_data(integrator_data[i]),
      .out_data(integrator_data[i+1])
      );


    cic_comb #(ACC_WIDTH) cic_comb_inst(
      .clock(clock),
      .strobe(out_strobe),
      .in_data(comb_data[i]),
      .out_data(comb_data[i+1])
      );
    end
endgenerate


//------------------------------------------------------------------------------
//                            output rounding
//------------------------------------------------------------------------------

/*
-----------------------------------------------------
 Output rounding calculations for 5 stages 

 bits growth is (Stages number) * log2(Decimation Ratio)

 sample rate (ksps)  decimation 	 bit growth  
 		   48						36			25
			96						18			20
		  192						 9			15
-------------------------------------------------------		  
*/		

localparam GROWTH2  =  5;
localparam GROWTH3  = 10;
localparam GROWTH4  = 10;
localparam GROWTH5  = 12;
localparam GROWTH6  = 16;
localparam GROWTH8  = 15;
localparam GROWTH9  = 16;
localparam GROWTH10 = 17;
localparam GROWTH12 = 22;
localparam GROWTH16 = 20;
localparam GROWTH18 = 21;
localparam GROWTH20 = 22;
localparam GROWTH32 = 25;
localparam GROWTH36 = 26;
localparam GROWTH40 = 27;

localparam MSB3  =  (IN_WIDTH + GROWTH3)  - 1;           // 18 + 15 - 1 = 32
localparam LSB3  =  (IN_WIDTH + GROWTH3)  - OUT_WIDTH;   // 15

localparam MSB6 =  (IN_WIDTH + GROWTH6) - 1;           // 18 + 20 - 1 = 37
localparam LSB6 =  (IN_WIDTH + GROWTH6) - OUT_WIDTH;   // 17 

localparam MSB12 =  (IN_WIDTH + GROWTH12) - 1;           // 18 + 25 - 1 = 42
localparam LSB12 =  (IN_WIDTH + GROWTH12) - OUT_WIDTH;   // 25 


localparam MSB5  =  (IN_WIDTH + GROWTH5)  - 1;           // 18 + 15 - 1 = 32
localparam LSB5  =  (IN_WIDTH + GROWTH5)  - OUT_WIDTH;   // 15

localparam MSB10 =  (IN_WIDTH + GROWTH10) - 1;           // 18 + 20 - 1 = 37
localparam LSB10 =  (IN_WIDTH + GROWTH10) - OUT_WIDTH;   // 17 

localparam MSB20 =  (IN_WIDTH + GROWTH20) - 1;           // 18 + 25 - 1 = 42
localparam LSB20 =  (IN_WIDTH + GROWTH20) - OUT_WIDTH;   // 25 


localparam MSB9  =  (IN_WIDTH + GROWTH9)  - 1;           // 18 + 15 - 1 = 32
localparam LSB9  =  (IN_WIDTH + GROWTH9)  - OUT_WIDTH;   // 15

localparam MSB18 =  (IN_WIDTH + GROWTH18) - 1;           // 18 + 20 - 1 = 37
localparam LSB18 =  (IN_WIDTH + GROWTH18) - OUT_WIDTH;   // 17 

localparam MSB36 =  (IN_WIDTH + GROWTH36) - 1;           // 18 + 25 - 1 = 42
localparam LSB36 =  (IN_WIDTH + GROWTH36) - OUT_WIDTH;   // 25 

always @(posedge clock)
begin
   if (out_strobe)
      case (decimation)
         //    3: out_data <= comb_data[STAGES][MSB3:LSB3]   + comb_data[STAGES][LSB3-1];
         //    6: out_data <= comb_data[STAGES][MSB6:LSB6] + comb_data[STAGES][LSB6-1];
         //   12: out_data <= comb_data[STAGES][MSB12:LSB12] + comb_data[STAGES][LSB12-1];

         //    9: out_data <= comb_data[STAGES][MSB9:LSB9]   + comb_data[STAGES][LSB9-1];
         //   18: out_data <= comb_data[STAGES][MSB18:LSB18] + comb_data[STAGES][LSB18-1];
         //   36: out_data <= comb_data[STAGES][MSB36:LSB36] + comb_data[STAGES][LSB36-1];
 
          5: out_data <= comb_data[STAGES][MSB5:LSB5] + comb_data[STAGES][LSB5-1];
         10: out_data <= comb_data[STAGES][MSB10:LSB10] + comb_data[STAGES][LSB10-1];
         20: out_data <= comb_data[STAGES][MSB20:LSB20] + comb_data[STAGES][LSB20-1];  
      endcase
end


endmodule

  

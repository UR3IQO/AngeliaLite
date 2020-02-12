//
//  HPSDR - High Performance Software Defined Radio
//
//  Hermes code. 
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

// Based on code  by James Ahlstrom, N2ADR,  (C) 2011
// Modified for use with HPSDR by Phil Harman, VK6PH, (C) 2013
// April 2019: Changed for use in AngeliaLite by Oleg Skydan UR3IQO

// Interpolating CIC filter, order 5.
// Produce an output when clock_en is true.  Output a strobe on req
// to request an input from the next filter.

module CicInterpMx(
	input clock,
	input clock_en,				// enable an output sample
	output reg req,				// request the next input sample
	input signed [IBITS-1:0] x_real,	// input samples
	input signed [IBITS-1:0] x_imag,
	output signed [OBITS-1:0] y_real,	// output samples
	output signed [OBITS-1:0] y_imag
	);
	
	parameter RATIO = 320;		// interpolation; limited by size of counter
	parameter IBITS = 20;		// input bits
	parameter OBITS = 16;		// output bits
	parameter GBITS = 34;		//log2(RATIO ** 4);	// growth bits: growth is R**M / R
   parameter STAGES = 5;
	// Note: log2() rounds UP to the next integer - Not available in Verilog!
	localparam CBITS = IBITS + GBITS;	// calculation bits

	reg [9:0] counter;		// increase for higher maximum RATIO  **** was [7:0]

	reg signed [CBITS-1:0] x[0:STAGES], dx[0:STAGES-1];		// variables for comb, real
	reg signed [CBITS-1:0] y[1:STAGES];	// variables for integrator, real
	reg signed [CBITS-1:0] q[0:STAGES], dq[0:STAGES-1];		// variables for comb, imag
	reg signed [CBITS-1:0] s[1:STAGES];	// variables for integrator, imag

	wire signed [CBITS-1:0] sxtxr, sxtxi;
	assign sxtxr = {{(CBITS - IBITS){x_real[IBITS-1]}}, x_real};	// sign extended
	assign sxtxi = {{(CBITS - IBITS){x_imag[IBITS-1]}}, x_imag};
	assign y_real = y[STAGES][CBITS-1 -:OBITS] + y[STAGES][(CBITS-1)-OBITS];		// output data  with truncation to remove DC spur
	assign y_imag = s[STAGES][CBITS-1 -:OBITS] + s[STAGES][(CBITS-1)-OBITS];
	
	initial
	begin
		counter = 0;
		req = 0;
	end

	always @(posedge clock)
	begin
		if (clock_en)
		begin
			// (x0, q0) -> comb -> (x5, q5) -> interpolate -> integrate -> (y5, s5)
			if (counter == RATIO - 1)
			begin	// Process the sample (x0, q0) to get (x5, q5)
				counter <= 1'd0;
				x[0] <= sxtxr;
				q[0] <= sxtxi;
				req <= 1'd1;

            // Comb for real data for last stage
            x[STAGES] <= x[STAGES-1] - dx[STAGES-1];
            dx[i] <= x[i];
            // Comb for imaginary data for last stage
            q[STAGES] <= q[STAGES-1] - dq[STAGES-1];
            dq[STAGES-1] <= q[STAGES-1];

			end
			else
			begin
				counter <= counter + 1'd1;
				x[STAGES] <= 0;	// stuff a zero for last stage
				q[STAGES] <= 0;
				req <= 1'd0;
			end
			// Integrate the sample (x5, q5) to get the output (y5, s5)
         // Integrator for real data; input is x[STAGES]
         y[1] <= y[1] + x[STAGES];
         s[1] <= s[1] + q[STAGES];
		end
		else
		begin
			req <= 1'd0;
		end
	end


generate 
genvar i;
   for(i = 0; i < STAGES - 1; i = i + 1)
   begin : comb_stages

      always @(posedge clock)
         if(clock_en && counter == RATIO - 1)
         begin
            // Comb for real data
            x[i+1] <= x[i] - dx[i];
            dx[i] <= x[i];
            // Comb for imaginary data
            q[i+1] <= q[i] - dq[i];
            dq[i] <= q[i];
         end
   end
endgenerate   

generate 
genvar k;
   for(k = 2; k <= STAGES; k = k + 1)
   begin : int_stages

      always @(posedge clock)
         if(clock_en)
         begin
            // Integrator for real data; input is x5
            y[k] <= y[k] + y[k-1];
            // Integrator for imaginary data; input is q5
            s[k] <= s[k] + s[k-1];
         end
   end
endgenerate

endmodule


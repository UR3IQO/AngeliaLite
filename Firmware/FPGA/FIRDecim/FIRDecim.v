//Decimation FIR filter. Optimized for resources (well, it can be more optimized, but it fits in current FPGA, so no need to do it)  
//Copyright (C) by Oleg Skydan UR3IQO 2019


module FIRDecim (	
	input clock,
	input strobe_in,									// new sample is available
	input signed [IBITS-1:0] x_real,			// x is the sample input
	input signed [IBITS-1:0] x_imag,
	output reg strobe_out,							// new output is available
	output reg signed [OBITS-1:0] y_real,	// y is the filtered output
	output reg signed [OBITS-1:0] y_imag);
	
	localparam ADDRBITS	= 10;					// Address bits for 18/36 X 1024 rom/ram blocks
	
	parameter
	   IBITS	      = 18,						// multiplier bits == input bits	
		OBITS			= 24,							// output bits
      RATIO       = 9,
		TAPS 			= 774,				// Must be even by 9 and 2
   	ABITS			= 35,
      GBITS       = 4;

reg [ADDRBITS-1:0] addr_in = 0;
reg [ADDRBITS-1:0] x_addr_calc1 = 0;
reg [ADDRBITS-1:0] x_addr_calc2 = 0;
reg [ADDRBITS-2:0] h_addr_calc = 0;
reg signed [ABITS+GBITS-1:0] acc_r, acc_i;
reg [3:0] in_cnt = 0;

wire signed [IBITS-1:0] x1_r, x1_i, x2_r, x2_i;
wire signed [IBITS-1:0] h;

FIRDecimRAM X( .clock(clock), 
               
               .address_a(strobe_in ? addr_in : x_addr_calc1), 
               .wren_a(strobe_in), 
               .data_a({ x_real, x_imag }), 
               .q_a({x1_r, x1_i}),

               .address_b(x_addr_calc2),	
               .wren_b(1'b0),	
               .data_b(), 
               .q_b({x2_r, x2_i}) );   

FIRDecimROM H(.clock(clock), .address(h_addr_calc), .q(h));

reg strobe_in1;
reg strobe_in2;
reg strobe_in3;

reg [IBITS*2-1:0] mult_r, mult_i;

always @(posedge clock)
begin
   //Delay strobe_in pulse, so it will be 
   strobe_in1 <= strobe_in;
   strobe_in2 <= strobe_in1;
   strobe_in3 <= strobe_in2;

   if(strobe_in)
   begin
      addr_in <= addr_in - 1'b1;
      if(in_cnt == RATIO-1)in_cnt <= 0;
      else in_cnt <= in_cnt + 1'b1;
      if(in_cnt == 0)strobe_out <= 1'b1;
      else strobe_out <= 1'b0;
   end
   else strobe_out <= 1'b0;

   if(h_addr_calc < TAPS/2 + 3 /*pipeline delay*/)
   begin
      if(!strobe_in)
      begin
         x_addr_calc1 <= x_addr_calc1 + 1'b1;
         x_addr_calc2 <= x_addr_calc2 - 1'b1;
         h_addr_calc <= h_addr_calc + 1'b1;
      end

      if(!strobe_in2)
      begin
         //After multiplication we have 36bits result with two sign bits
         //We are adding results of two multiplications, the most significant bit 
         //will be discarded and bit 35 should go to the GBITs.
         mult_r <= h * x1_r + h * x2_r;
         mult_i <= h * x1_i + h * x2_i;
      end

      if(h_addr_calc == 2)
      begin
         acc_r <= 0;
         acc_i <= 0;
      end
      else if(!strobe_in3)
      begin   
         //Round down to ABITS width and fill GBITS with sign
         //The total accumulator size is GBITS + ABITS bits
         //GBITS are used to allow FIR gain > 1, so taps bits are used maximally effective 
         acc_r <= acc_r + { { (GBITS){ mult_r[35] }}, mult_r[34:34-ABITS+1] };// + mult_r[34-ABITS];
         acc_i <= acc_i + { { (GBITS){ mult_i[35] }}, mult_i[34:34-ABITS+1] };// + mult_i[34-ABITS];
      end   
   end
   else if(h_addr_calc == TAPS/2 + 3 /*pipeline delay*/)
   begin
      y_real <= acc_r[GBITS + ABITS - 1 : GBITS + ABITS - OBITS] + acc_r[GBITS + ABITS - 1 - OBITS];
      y_imag <= acc_i[GBITS + ABITS - 1 : GBITS + ABITS - OBITS] + acc_i[GBITS + ABITS - 1 - OBITS];
      h_addr_calc <= h_addr_calc + 1'b1;
   end
   else
   begin
      if(in_cnt == 0)
      begin
         x_addr_calc1 <= addr_in;
         x_addr_calc2 <= addr_in + (TAPS[ADDRBITS-1:0] - 1'b1);
         h_addr_calc <= 0;
      end
   end
end


endmodule
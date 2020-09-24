//Decimation FIR filter. Optimized for resources (well, it can be more optimized, 
//but it fits in current FPGA, so no need to do it)  
//Copyright (C) by Oleg Skydan UR3IQO 2019


module FIRDecim (	
   input clock,
   input strobe_in,									// new sample is available
   input signed [IBITS-1:0] x_real,			// x is the sample input
   input signed [IBITS-1:0] x_imag,
   output reg strobe_out,							// new output is available
   output reg signed [OBITS-1:0] y_real,	// y is the filtered output
   output reg signed [OBITS-1:0] y_imag);
      
   parameter
      IBITS	 =  22,	  //input width	
      HBITS  =  18,   //taps width
      OBITS	 =  24,	  //output width
      RATIO  =  9,    //decimation ratio
      TAPS 	 =  774,  //taps number, must be even by RATIO and 2
      ABITS	 =  35,   //accumulator size fractional part
      GBITS  =  4;    //accumulator size integer part and sign bit

   localparam ADDRBITS  =  10,			//address bits for 18/54 X 1024 rom/ram blocks
              MBITS = IBITS + HBITS;   //multiple-add reslut size for h*(x[i]+x[N-i]) operation
                                       //We are adding two samples of IBITS width, the result is IBITS+1 width
                                       //After multiplication we have result of HBITS+IBITS+1 width with 
                                       //two sign bits. The most significant bit will be discarded.
                                       //So the result width is HBITS+IBITS
                                       //NOTE: MSB of the result should go to the GBITs part of the accumulator.


reg [ADDRBITS-1:0] addr_in = 0;
reg [ADDRBITS-1:0] x_addr_calc1 = 0;
reg [ADDRBITS-1:0] x_addr_calc2 = 0;
reg [ADDRBITS-2:0] h_addr_calc = 0;
reg signed [ABITS+GBITS-1:0] acc_r, acc_i;
reg [3:0] in_cnt = 0;

wire signed [IBITS-1:0] x1_r, x1_i, x2_r, x2_i;
wire signed [HBITS-1:0] h;

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

reg [MBITS-1:0] mult_r, mult_i;

always @(posedge clock)
begin
   //Delay strobe_in pulse, it will be used to stop and synchronize 
   //different stages of pipline when the new sample is added to input delay line
   strobe_in1 <= strobe_in;
   strobe_in2 <= strobe_in1;
   strobe_in3 <= strobe_in2;

   if(strobe_in)
   begin
      //new input sample arrived
      //update delay line address for the next new sample
      addr_in <= addr_in - 1'b1;
      //count saved samples
      if(in_cnt == RATIO-1)in_cnt <= 0;
      else in_cnt <= in_cnt + 1'b1;
      //generate output strobe
      if(in_cnt == 0)strobe_out <= 1'b1;
      else strobe_out <= 1'b0;
   end
   else strobe_out <= 1'b0;

   if(h_addr_calc < TAPS/2 + 3 /*pipeline delay*/)
   begin
      if(!strobe_in)
      begin
         //increment addesses only if there is no new input sample
         //otherwise stall calc operation for one clock cycle until new sample
         //is written to the input delay line
         x_addr_calc1 <= x_addr_calc1 + 1'b1;
         x_addr_calc2 <= x_addr_calc2 - 1'b1;
         h_addr_calc <= h_addr_calc + 1'b1;
      end

      if(!strobe_in2)
      begin
         //propagate pipline stall 
         //multiply-add h[i]*(x[i]+x[N-i])
         mult_r <= h * (x1_r + x2_r);
         mult_i <= h * (x1_i + x2_i);
      end

      if(h_addr_calc == 2)
      begin
         //reset accumulators for the new FIR calculation cycle
         acc_r <= 0;
         acc_i <= 0;
      end
      else if(!strobe_in3)
      begin   
         //propagate pipline stall 
         //Round mult_r/mult_i down to ABITS width and fill GBITS with sign
         //The total accumulator size is GBITS + ABITS bits
         //GBITS are used to allow FIR gain > 1, so taps bits are used maximally effective 
         acc_r <= acc_r + { { (GBITS){ mult_r[ MBITS-1 ] }}, mult_r[ MBITS-2 : MBITS-ABITS-1 ] } + mult_r[MBITS-ABITS-2];
         acc_i <= acc_i + { { (GBITS){ mult_i[ MBITS-1 ] }}, mult_i[ MBITS-2 : MBITS-ABITS-1 ] } + mult_i[MBITS-ABITS-2];
      end   
   end
   else if(h_addr_calc == TAPS/2 + 3 /*pipeline delay*/)
   begin
      //round and register result
      y_real <= acc_r[ GBITS+ABITS-1 : GBITS+ABITS-OBITS ] + acc_r[ GBITS+ABITS-1-OBITS];
      y_imag <= acc_i[ GBITS+ABITS-1 : GBITS+ABITS-OBITS ] + acc_i[ GBITS+ABITS-1-OBITS];
      h_addr_calc <= h_addr_calc + 1'b1;
   end
   else
   begin
      if(in_cnt == 0)
      begin
         //run new FIR caclulation cycle
         x_addr_calc1 <= addr_in;
         x_addr_calc2 <= addr_in + (TAPS[ADDRBITS-1:0] - 1'b1);
         h_addr_calc <= 0;
      end
   end
end


endmodule
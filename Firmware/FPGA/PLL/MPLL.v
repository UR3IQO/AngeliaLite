//Copyright (C) by Oleg Skydan UR3IQO 2019


//****************************************************************************
// Main VCXO PLL 
//****************************************************************************

module MPLL( 
      input vcxo_clk,
      input ref_clk,
      output pol,
      output enable
   );

   wire r_clk;

   reg v_clk;
   //Divide 10MHz reference down to 400kHz

   Divider #(.WIDTH(5))  DivR(ref_clk /*clock*/, 1 /*strobe_in*/, r_clk /*strobe_out*/, 25 /*ratio*/);

   always @(posedge vcxo_clk)
      v_clk = !v_clk;

   //Compare phases
   PFD pfd80k(v_clk /*osc*/, r_clk /*reference*/, pol /*PFD output polarity*/, enable /*PFD output enable*/);

endmodule
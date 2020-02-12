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
   wire v_clk;

   //Divide 10MHz reference down to 80kHz
   Divider #(.WIDTH(7))  DivR(ref_clk /*clock*/, 1 /*strobe_in*/, r_clk /*strobe_out*/, 125 /*ratio*/);
 
  //Divide 155.52MHz VCXO down to 80kHz
   Divider #(.WIDTH(11)) DivN(vcxo_clk /*clock*/, 1 /*strobe_in*/, v_clk /*strobe_out*/, 1944 /*ratio*/);

   //Compare phases
   PFD pfd80k(v_clk /*osc*/, r_clk /*reference*/, pol /*PFD output polarity*/, enable /*PFD output enable*/);

endmodule
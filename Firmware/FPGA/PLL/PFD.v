//Copyright (C) by Oleg Skydan UR3IQO 2019

//*******************************************************
// The three state two DFF PFD 
//*******************************************************

module PFD( 
      input vcxo_clk,
      input ref_clk,
      output pol,
      output enable
   );

   reg r; //reference DFF
   reg o; //vcxo DFF

   wire rst; //DFF reset line 
   assign rst = r & o;

   assign pol = r;  //PFD output polarity 
   assign enable = !(r ^ o); //PFD output enable 

   always @(posedge ref_clk or posedge vcxo_clk or posedge rst)
   begin
      if(rst)
      begin
         r <= 1'b0;
         o <= 1'b0;
      end
      else 
      begin
         if(ref_clk)r <= 1'b1;
         if(vcxo_clk)o <= 1'b1;
      end     
   end

endmodule
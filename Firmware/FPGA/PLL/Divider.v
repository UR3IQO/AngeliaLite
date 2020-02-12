//Copyright (C) by Oleg Skydan UR3IQO 2019




module Divider(clock, strobe_in, strobe_out, R);

parameter WIDTH = 7;

input clock;
input strobe_in;
output reg strobe_out;
input [WIDTH-1:0] R;

reg [WIDTH-1:0] cycle;

initial cycle <= 0;

always @(posedge clock)
begin
   if (strobe_in) 
   begin
      if(cycle == (R - 1))
      begin
         strobe_out <= 1;
         cycle <= 0;
      end
      else
      begin
         strobe_out <= 0;
         cycle <= cycle + 1'b1;  
      end
   end
   else
      strobe_out <= 0;
end


endmodule

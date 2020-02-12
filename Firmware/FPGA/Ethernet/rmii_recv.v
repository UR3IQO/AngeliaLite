//-----------------------------------------------------------------------------
//                    Copyright (c) 2012 HPSDR Team
//-----------------------------------------------------------------------------
//  April 2019, UR3IQO Changed to work in AngeliaLite  (LAN8720A PHY, 100Mbit/s speed)


//-----------------------------------------------------------------------------
// demultiplex phy nibbles
//-----------------------------------------------------------------------------


module rmii_recv (
  input reset, 

  //receive: data and active are valid at posedge of clock
  input  clock, 
  output [7:0] data,
  output active,
  
  //hardware pins
  input  PHY_CLK50,
  input  [1:0]PHY_RX,     
  input  PHY_CRS
  );

//-----------------------------------------------------------------------------
//          de-multiplex nibbles 
//-----------------------------------------------------------------------------
reg [7:0] shift_reg;
reg [3:0] crs;

always @(posedge PHY_CLK50)
begin
   shift_reg <= { PHY_RX, shift_reg[7:2] };
   crs <= { PHY_CRS & ~reset, crs[3:1]};
end


  
//-----------------------------------------------------------------------------
//          clock recovery and data synchronization
//-----------------------------------------------------------------------------
reg idle = 1'b1;
reg [1:0] cnt = 2'd3;
reg [7:0] data_sync;

always @(posedge PHY_CLK50) 
   if(idle)
   begin
      if(crs == 4'b1111 && shift_reg == 8'h55) 
      begin
         idle <= 1'b0;
         data_sync <= shift_reg;
      end
      cnt <= 2'd3;
   end
   else
   begin
      if(cnt == 2'b0)
      begin
         if(crs != 4'b0000/*crs == 4'b1111 || crs == 4'b0101 || crs == 4'b0111*/)
            data_sync <= shift_reg;
         else
            idle <= 1'b1;
      end 
      cnt <= cnt - 2'b1;
   end  


//-----------------------------------------------------------------------------
//                          preamble detector
//-----------------------------------------------------------------------------
localparam MIN_PREAMBLE_LENGTH = 3'd5;

reg [2:0] preamble_cnt;
reg payload_coming = 0;
//reg data_coming;

assign active = ~idle & payload_coming;
assign data = data_sync;

always @(posedge clock) 
begin
  if (idle) 
  begin 
      //RX-DV low, nothing is being received
      payload_coming <= 1'b0; 
      preamble_cnt <= MIN_PREAMBLE_LENGTH; 
  end
  else if (!payload_coming) 
    //RX-DV high, but payload is not being received yet
    //count preamble bytes
    if (data_sync == 8'h55) 
    begin 
      if (preamble_cnt != 0) preamble_cnt <= preamble_cnt - 3'd1; 
    end
    else if ((preamble_cnt == 0) && (data_sync == 8'hD5)) payload_coming <= 1'b1;
    //wrong byte received, reset preamble byte count
    else preamble_cnt <= MIN_PREAMBLE_LENGTH;

   //data_coming <= ~idle;

   //data <= data_sync;

end      
  
endmodule
  
//Copyright (C) Oleg Skydan UR3IQO 2019

module SPI_DVGA(input clock, 
                 input clock_en,
                 input [15:0] data,
                 output reg sclk,
                 output reg sdata,
                 output reg sload);

//FSM state
//33 - Transfer initiated 
//32 - pause
//31 - sclk negative edge, clock out data[15]
//30 - sclk positive edge, (clock in data[15] into slave)
//29 - sclk negative edge, clock out data[14]
//.....
//1 - sclk negative edge, clock out data[0] 
//0 - sclk positive edge (clock in data[0] into slave)
//63 - load positive edge
//62 - pause
//61 - idle
reg [15:0] data_sent;
reg [5:0] state;
reg [15:0] shift_reg;

always @(posedge clock)
   if(clock_en)
   begin
      if(state != 6'd61)
      begin
         state <= state - 1'b1;
         //Not an IDLE state and valid data change time
         if(~state[5] & state[0]) sdata <= shift_reg[state[4:1]];
      end
      else if(data_sent != data)
      begin
         //New transaction start
        shift_reg <= data;
        data_sent <= data;
        state <= 6'd32;
      end

      sclk <= (~state[0] | state[5]);
      sload <= state[5];
   end

initial
begin
   state <= 6'd32;
   shift_reg <= 16'h6B6B;
   data_sent <= 16'hAAAA;
end

endmodule
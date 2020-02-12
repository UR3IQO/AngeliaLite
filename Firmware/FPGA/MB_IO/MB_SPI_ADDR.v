//Copyright (C) by Oleg Skydan UR3IQO 2019


//****************************************************************************
// slave SPI, communication with MCU
// read static IP and MAC from MCU
//****************************************************************************

module MB_SPI_ADDR (
  //control
  input clock,
  
  //data
  output reg [47:0] mac,
  output reg [31:0] ip,
  output reg addr_read,

  //hardware pins
  input CLK,                  
  input MOSI,                   
  input MAC_LOAD
);


reg [1:0] MAC_LOAD_1;
reg [1:0] CLK_1;
reg [6:0] bit_no;

always @(posedge clock)
begin
   if(MAC_LOAD_1 == 2'b10)
   begin
      //Negative edge of MAC_LOAD found
      bit_no <= 7'b0;
   end
   else if(MAC_LOAD_1 == 2'b01 && bit_no == 7'd80)
   begin
      addr_read <= 1'b1;
   end
   else if(MAC_LOAD_1 == 2'b00 && CLK_1 == 1'b01)
   begin
      ip[31:0] <= { ip[30:0], MOSI };
      mac[47:0] <= { mac[46:0], ip[31] };
      bit_no <= bit_no + 7'b1;
   end
   
   MAC_LOAD_1 <= { MAC_LOAD_1[0], MAC_LOAD };
   CLK_1 <= { CLK_1[0], CLK };
end

initial
begin
   addr_read <= 1'b0;
end

endmodule

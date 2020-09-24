//Copyright (C) by Oleg Skydan UR3IQO 2019


//****************************************************************************
// slave SPI, communication with MCU
// exchange ADC/Alex/OC/LEDs/PWR ctrl and other data with MB MCU
//****************************************************************************


module MB_SPI_IO (
   //control
   input clock,
  
   //ADC
   output reg [11:0] AIN1,
   output reg [11:0] AIN2,
   output reg [11:0] AIN3,
   output reg [11:0] AIN4,
   output reg [11:0] AIN5,
   output reg [11:0] AIN6,
   output reg [1:0] dither_override,
   output reg reference_en, 
   output reg pll_on,
   output reg IO4,

   input pk_detect_reset,
   output reg pk_detect_ack,
   
   //ALEX
   input enable, 
   input [47:0] Alex_data,

   //LEDs
   input [7:0] leds,

   //OC
   input [6:0] OC,

   //DAC
   input [7:0] DAC,

   //hardware pins
   input CLK,                  
   input MOSI,                   
   output reg MISO,
   input LOAD
);


reg [1:0] LOAD_1;
reg [1:0] CLK_1;
reg [79:0] data;
reg [6:0] bit_no;

always @(posedge clock)
begin
   if(LOAD_1 == 2'b10)
   begin
      //Negative edge of LOAD found
      //FPGA => MCU
      //  DAC[8] | OC[7] | 0 | pk_detect_reset[1] | ALEX enable[1] | ALEX data[48] | LEDs[8]                        
      data <= { DAC, 6'b0, OC[0], OC[1], OC[2], OC[3], OC[4], OC[5], OC[6], 1'b0, pk_detect_reset, enable, Alex_data[47:0], leds[7:0] };
   end
   else if(LOAD_1 == 2'b01)
   begin
      //Positive edge of LOAD found
      AIN1 <= data[11:0];
      AIN2 <= data[23:12];
      AIN3 <= data[35:24];
      AIN4 <= data[47:36];
      AIN5 <= data[59:48];
      AIN6 <= data[71:60];
      pk_detect_ack <= data[72];
      dither_override <= data[74:73];
      IO4 <= data[75];
      reference_en <= data[76];
      pll_on <= data[77];
   end
   else if(LOAD_1 == 2'b00)
   begin
      if(CLK_1 == 2'b01)
      begin
         data <= { data[78:0], MOSI };
      end
      else if(CLK_1 == 2'b10)
      begin
         MISO <= data[79];
      end
   end
   LOAD_1 <= { LOAD_1[0], LOAD };
   CLK_1 <= { CLK_1[0], CLK };
end

initial
begin
      AIN1 <= 12'b0;
      AIN2 <= 12'b0;
      AIN3 <= 12'b0;
      AIN4 <= 12'b0;
      AIN5 <= 12'b0;
      AIN6 <= 12'b0;
      pk_detect_ack <= 1'b0;
      dither_override <= 2'b11;
      IO4 <= 1'b0;
end

endmodule

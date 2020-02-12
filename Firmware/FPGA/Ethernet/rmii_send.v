//
//  HPSDR - High Performance Software Defined Radio
//
//  Metis code.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


//  Metis code copyright 2010, 2011, 2012, 2013 Alex Shovkoplyas, VE3NEA.
//  April 2019, UR3IQO Changed to work in AngeliaLite  (RMII, LAN8720A PHY, 100Mbit/s speed)


module rmii_send (
  input [7:0] data,
  input tx_enable,   //TX enable signal syncronous to negative edge of the 'clock'
  output active,
  input clock,    //TX clock 12.5MHz

  //hardware pins
  input PHY_CLK50, //RMII PHY clock 50MHz
  output [1:0] PHY_TX,
  output reg PHY_TX_EN
  );



//-----------------------------------------------------------------------------
//                            shift reg
//-----------------------------------------------------------------------------
localparam PREAMBLE_BYTES = 64'h55555555555555D5;
localparam PREAMB_LEN = 4'd8;
localparam HI_BIT = 8*PREAMB_LEN - 1;
//localparam HI_BIT = 8 - 1;
reg [HI_BIT:0] shift_reg;
reg [3:0] bytes_left;






//-----------------------------------------------------------------------------
//                           state machine
//-----------------------------------------------------------------------------
//localparam ST_IDLE = 1, ST_SEND = 2; //, ST_GAP = 4;
//reg [2:0] state = ST_IDLE;
reg [1:0] nibble_phase;

// reg sending = 0;

// assign PHY_TX_EN = sending;
// assign active = sending;

// always @(negedge clock)
// begin
//    if(tx_enable)
//    begin
//       shift_reg <= data;
//       sending <= 1'b1;
//    end
//    else 
//    begin
//       sending <= 1'b0;  
//    end
// end

reg [7:0] byte_reg;

localparam ST_IDLE = 1, ST_SEND = 2, ST_GAP = 4;
reg [2:0] state = ST_IDLE;

reg sending = 1'b0;
assign active = sending | (state == ST_GAP);
//assign PHY_TX_EN = sending;

always @(posedge clock)
  begin

  if (tx_enable | (state == ST_SEND))
      begin
         byte_reg <= shift_reg[HI_BIT -: 8];
         shift_reg <= {shift_reg[HI_BIT-8:0], data};
         sending <= 1'b1;
      end
  else 
   begin
      shift_reg <= PREAMBLE_BYTES;
      sending <= 1'b0;
   end

  case (state)
    ST_IDLE:
      //receiving the first payload byte 
      if (tx_enable) state <= ST_SEND;

    ST_SEND:
      //receiving payload data
      if (tx_enable) bytes_left <= PREAMB_LEN - 4'd1;
      //purging shift register
      else if (bytes_left != 0) bytes_left <= bytes_left - 4'd1;
      //starting inter-frame gap
      else begin bytes_left <= 4'd12; state <= ST_GAP; end
      
    ST_GAP:
      if (bytes_left != 0) bytes_left <= bytes_left - 4'd1;
      else state <= ST_IDLE;
    endcase
  end
  

//-----------------------------------------------------------------------------
//                             output
//-----------------------------------------------------------------------------


always @(posedge PHY_CLK50)
begin
   PHY_TX_EN <= sending;
   if(sending)
   begin
      case (nibble_phase)
         0: PHY_TX <= byte_reg[1:0];
         1: PHY_TX <= byte_reg[3:2];
         2: PHY_TX <= byte_reg[5:4];
         3: PHY_TX <= byte_reg[7:6];
      endcase
      nibble_phase <= nibble_phase + 1'b1;
   end
   else
      nibble_phase <= 2'b0;
end

endmodule

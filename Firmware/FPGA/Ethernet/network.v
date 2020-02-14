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


//  Metis code copyright 2010, 2011, 2012, 2013 Phil Harman VK6APH, Alex Shovkoplyas, VE3NEA.
//  April 2016, N2ADR: Added dhcp_seconds_timer
//  January 2017, N2ADR: Added remote_mac_sync to the dhcp module
//  January 2017, N2ADR: Added ST_DHCP_RENEW states to allow IO to continue during DHCP lease renewal
//  April   2019, UR3IQO: Changed to work in AngeliaLite  
//  8 Dec 2019, UR3IQO: Fixed incorrect DHCP client behavior: 
//                When link was down and then up again the DHCP renewal
//                procedure is run (not sure it is correct behavior).
//                If renewal failed, DHCP client should start REBIND, so
//                it should restart DHCP procedure from the start and
//                use multicast DHCPREQUECT packet.
//                This is particular important cause otherwise it may not 
//                obtain address when the ethernet cable was unplugged and 
//                then plugged back to the board.
//                So if DHCP timeout or fail occured during renewal, DHCP
//                will be restarted

module network (
	output clock_25MHz,
	output clock_12_5MHz,
	output clock_2_5MHz,

	//input
	input udp_tx_request,
	input [15:0] udp_tx_length, 
	input [7:0] udp_tx_data,
	input speed,
	input set_ip,
	input [31:0] assign_ip,
	input [7:0] port_ID,
  input run,
	
	//output
	output rx_clock,
	output tx_clock,
	output udp_rx_active,
	output udp_tx_enable,
	output [7:0] udp_rx_data,
	output udp_tx_active,
	output [47:0] local_mac,
	output broadcast,
	output IP_write_done,
	output [15:0]to_port,
	output dst_unreachable,


  //status output
  output speed_1Gbit,
  //output [3:0] network_state, 
  output network_state, 
  output [7:0] network_status,
  output static_ip_assigned,
  output dhcp_timeout,
  output reg dhcp_success,
  output dhcp_failed,
  output icmp_rx_enable,  // *** test for ping bug

  //hardware pins
  output [2:0]PHY_TX,
  output PHY_TX_EN,            
  input  [1:0]PHY_RX,     
  input  PHY_CRS,                
  input  PHY_CLK50,           

  input rst_n,
  input macbit,
        
  
  inout  PHY_MDIO,             
  output PHY_MDC,           
  
   input MCU_CLK,
   input MCU_MOSI,
   input MCU_MAC_LOAD,

  input MODE2
  );

assign IP_write_done = 1'b0; //AngeliaLite does not support IP address setting using Ethernet
wire [31:0] static_ip;
wire eeprom_ready;
//wire [1:0] phy_speed;
wire phy_duplex;
wire phy_connected;// = phy_duplex && (phy_speed[1] != phy_speed[0]); 
assign dhcp_timeout = (dhcp_seconds_timer == 15);
wire dhcp_success0;

//-----------------------------------------------------------------------------
//                             state machine
//-----------------------------------------------------------------------------
//IP addresses
reg  [31:0] local_ip;
wire [31:0] apipa_ip = {8'd169, 8'd254, local_mac[15:0]};
//wire [31:0] ip_to_write;
assign static_ip_assigned = (static_ip != 32'hFFFFFFFF) && (static_ip != 32'd0);


localparam 
  ST_START         = 4'd0, 
  ST_EEPROM_START  = 4'd1, 
  ST_EEPROM_READ   = 4'd2, 
  ST_PHY_INIT      = 4'd3, 
  ST_PHY_CONNECT   = 4'd4, 
  ST_PHY_SETTLE    = 4'd5, 
  ST_DHCP_REQUEST  = 4'd6,
  ST_DHCP          = 4'd7,
  ST_DHCP_RETRY    = 4'd8,
  ST_RUNNING       = 4'd9,
  ST_DHCP_RENEW_WAIT	= 4'd10,
  ST_DHCP_RENEW_REQ		= 4'd11,
  ST_DHCP_RENEW_ACK		= 4'd12;
  

assign rx_clock = clock_12_5MHz;
assign tx_clock = clock_12_5MHz;

eth_pll eth_pll_inst( .inclk0(PHY_CLK50), .c0(clock_12_5MHz), .c1(clock_2_5MHz), .c2(clock_25MHz));


// Set Tx_reset (no sdr send) if network_state is True
assign network_state = reg_network_state;   // network_state is low when we have an IP address 
reg reg_network_state = 1'b1;					  // this is used in network.v to hold code in reset when high
reg [3:0] state = ST_START;

reg [21:0] dhcp_timer;
reg dhcp_tx_enable;
reg [17:0] dhcp_renew_timer;  // holds number of seconds before DHCP IP address must be renewed
reg [3:0] dhcp_seconds_timer;   // number of seconds since the DHCP request started
reg dhcp_rebind;
wire dhcp_is_renewal;

//reset all child modules
wire rx_reset, tx_reset;
sync sync_inst1(.clock(rx_clock), .sig_in(state <= ST_PHY_SETTLE), .sig_out(rx_reset));  
sync sync_inst2(.clock(tx_clock), .sig_in(state <= ST_PHY_SETTLE), .sig_out(tx_reset));  

always @(negedge clock_2_5MHz)
  //if connection lost, wait until reconnects
  if ((state > ST_PHY_CONNECT) && !phy_connected) 
  begin
    reg_network_state <= 1'b1;	
    dhcp_seconds_timer <= 4'd0; // zero seconds have elapsed
    dhcp_success <= 1'b0;
    state <= ST_PHY_CONNECT;
  end
    
  else
  case (state)
    //set eeprom read request
    ST_START: 
      begin
         state <= ST_EEPROM_START;
      end
    //clear eeprom read request
    ST_EEPROM_START:
      state <= ST_EEPROM_READ;

    //wait for eeprom
    ST_EEPROM_READ:
      if (eeprom_ready) 
      begin
        local_ip <= static_ip;
        //dhcp_timer <= 22'd2_500_000;    // set dhcp timer to one second
        //dhcp_seconds_timer <= 4'd0; // zero seconds have elapsed
        state <= ST_PHY_INIT;
      end

    //set phy initialization request
    ST_PHY_INIT:
      state <= ST_PHY_CONNECT;

    //clear phy initialization request
    //wait for phy to initialize and connect
    ST_PHY_CONNECT:
      if (phy_connected) begin
        dhcp_timer <= 22'd4_000_000; //a bit less than 2 seconds
        dhcp_success <= 1'b0;
        dhcp_rebind <= 1'b0;
        state <= ST_PHY_SETTLE;
      end

    //wait for connection to settle
    ST_PHY_SETTLE: 
       begin
         //when network has settled, get ip address, if static IP assigned then use it else try DHCP
         if (dhcp_timer == 0) 
         begin
            if (static_ip_assigned)
               state <= ST_RUNNING;
            else 
            begin
               local_ip <= 32'h00_00_00_00;    // needs to be 0.0.0.0 for DHCP
               dhcp_timer <= 22'd2_500_000;    // set dhcp timer to one second
               dhcp_seconds_timer <= 4'd0;     // zero seconds have elapsed
               state <= ST_DHCP_REQUEST;
            end
         end
         dhcp_timer <= dhcp_timer - 22'b1;          //no time out yet, count down
       end

    // send initial dhcp discover and request on power up
    ST_DHCP_REQUEST: 
      begin
         dhcp_tx_enable <= 1'b1;           // set dhcp flag
         dhcp_enable <= 1'b1;              // enable dhcp receive
         state <= ST_DHCP;
      end

    // wait for dhcp success, fail or time out.  Do time out here since same clock speed for 100/1000T
    // If DHCP provided IP address then set lease timeout to lease/2 seconds.
    ST_DHCP: 
      begin
         dhcp_tx_enable <= 1'b0;         // clear dhcp flag
         if (dhcp_success0) 
         begin
            dhcp_success <= 1'b1;
            local_ip <= ip_accept;
            dhcp_timer <= 22'd2_500_000;    // reset dhcp timers for next Renewal
            dhcp_seconds_timer <= 4'd0;
            reg_network_state <= 1'b0;    // Let network code know we have a valid IP address so can run when needed.
            if (lease == 32'd0 || lease[31:19] != 13'd0)
               dhcp_renew_timer <= 43_200;  // use 43,200 seconds (12 hours) if no lease time set or lease time > 2^19 seconds
            else
               dhcp_renew_timer <= lease[18:1];  // set timer to half lease time.
            //    dhcp_renew_timer <= (32'd10 * 2_500_000);     // **** test code - set DHCP renew to 10 seconds ****
            state <= ST_DHCP_RENEW_WAIT;
         end
         else if (dhcp_timer == 0) 
         begin  // another second has elapsed
            dhcp_renew_timer <= 18'h020000; // delay 50 ms
            dhcp_timer <= 22'd2_500_000;    // reset dhcp timer to one second
            dhcp_seconds_timer <= dhcp_seconds_timer + 4'd1;    // dhcp_seconds_timer still has its old value
            // Retransmit Discover at 1, 3, 7 seconds
            if (dhcp_seconds_timer == 0 || dhcp_seconds_timer == 2 || dhcp_seconds_timer == 6) 
            begin
               state <= ST_DHCP_RETRY;     // retransmit the Discover request
            end
            else if (dhcp_seconds_timer == 14) 
            begin    // no DHCP Offer received in 15 seconds 
               if(dhcp_is_renewal == 1'b1)
               begin //try rebinding
                  dhcp_rebind <= 1'b1;
                  state <= ST_PHY_CONNECT;
               end
               else
               begin //use apipa
                  local_ip <= apipa_ip;
                  state <= ST_RUNNING;
               end
            end
         end
         else
            dhcp_timer <= dhcp_timer - 22'd1;
      end

    ST_DHCP_RETRY: 
      begin  // Initial DHCP IP address was not obtained.  Try again.
         dhcp_enable <= 1'b0;                // disable dhcp receive
         if (dhcp_renew_timer == 0)
            state <= ST_DHCP_REQUEST;
         else
            dhcp_renew_timer <= dhcp_renew_timer - 18'h01;
      end

    // static ,DHCP or APIPA ip address obtained
    ST_RUNNING: 
      begin
         dhcp_enable <= 1'b0;          // disable dhcp receive
         reg_network_state <= 1'b0;    // let network.v know we have a valid IP address
      end

    // NOTE: reg_network_state is not set here so we can send DHCP packets whilst waiting for DHCP renewal.

    ST_DHCP_RENEW_WAIT: 
      begin // Wait until the DHCP lease expires
         dhcp_enable <= 1'b0;        // disable dhcp receive

         if (dhcp_timer == 0) 
         begin // another second has elapsed
            dhcp_renew_timer <= dhcp_renew_timer - 18'h01;
            dhcp_timer <= 22'd2_500_000;    // reset dhcp timer to one second
         end
         else 
         begin
            dhcp_timer <= dhcp_timer - 22'h01;
         end

         if (dhcp_renew_timer == 0)
            state <= ST_DHCP_RENEW_REQ;
      end

    ST_DHCP_RENEW_REQ: 
      begin // DHCP sends a request to renew the lease
         dhcp_tx_enable <= 1'b1;
         dhcp_enable <= 1'b1;
         dhcp_renew_timer <= 'd20;   // time to wait for ACK
         dhcp_timer <= 22'd2_500_000;    // reset dhcp timers for next Renewal
         state <= ST_DHCP_RENEW_ACK;
      end

    ST_DHCP_RENEW_ACK: 
      begin  // Wait for an ACK from the DHCP server in response to the request
         dhcp_tx_enable <= 1'b0;
         if (dhcp_success0) 
         begin
            dhcp_success <= 1'b1;
            if (lease == 32'd0 || lease[31:19] != 13'd0)
               dhcp_renew_timer <= 43_200;  // use 43,200 seconds (12 hours) if no lease time set
            else
               dhcp_renew_timer <= lease[18:1];  // set timer to half lease time.
            //  dhcp_renew_timer <= (32'd10 * 2_500_000);     // **** test code - set DHCP renew to 10 seconds ****
            dhcp_timer <= 22'd2_500_000;    // reset dhcp timers for next Renewal
            state <= ST_DHCP_RENEW_WAIT;
         end
         else if (dhcp_timer == 0) 
         begin  // another second has elapsed
            dhcp_timer <= 22'd2_500_000;    // reset dhcp timer to one second
            dhcp_renew_timer <= dhcp_renew_timer - 1'd1;
         end
         else if (dhcp_renew_timer == 0) 
         begin
            dhcp_renew_timer <= 18'd300; // time between renewal requests
            state <= ST_DHCP_RENEW_WAIT;
         end
         else 
         begin
            dhcp_timer <= dhcp_timer - 18'h01;
         end
      end
     
    endcase        
  
//-----------------------------------------------------------------------------
// reads mac and static ip from eeprom, writes static ip to eeprom
//-----------------------------------------------------------------------------
// eeprom eeprom_inst(
//   .clock(clock_2_5MHz),
//   .rd_request(state == ST_EEPROM_START),
//   .wr_request(set_ip),
//   .ready(eeprom_ready),
//   .mac(local_mac),
//   .ip(static_ip),
//   .ip_to_write(assign_ip),
//   .IP_write_done(IP_write_done),
//   .SCK(SCK),                  
//   .SI(SI),                   
//   .SO(SO),                   
//   .CS(CS)
// );

MB_SPI_ADDR MB_SPI_ADDR_inst (
      .clock(clock_12_5MHz),
      .addr_read(eeprom_ready),
      .mac(local_mac),
      .ip(static_ip),
      .CLK(MCU_CLK),
      .MOSI(MCU_MOSI),
      .MAC_LOAD(MCU_MAC_LOAD)
);


// assign local_mac = {8'h00,8'h1c,8'hc0,8'ha2,8'h22,8'h5d};
// assign static_ip = 32'd0; //{8'd192,8'd168,8'd122,8'd251};
// assign eeprom_ready = 1'b1;

//-----------------------------------------------------------------------------
// writes configuration words to the phy registers, reads phy state
//-----------------------------------------------------------------------------
phy_cfg phy_cfg_inst(
  .clock(clock_2_5MHz),  
  .init_request(state == ST_PHY_INIT),  
  .allow_1Gbit(MODE2),  
  .phy_connected(phy_connected),
  .duplex(phy_duplex),
  .mdio_pin(PHY_MDIO),
  .mdc_pin(PHY_MDC)  
);



//-----------------------------------------------------------------------------
//                           interconnections
//-----------------------------------------------------------------------------
localparam PT_ARP = 2'd0, PT_ICMP = 2'd1, PT_DHCP = 2'd2, PT_UDP = 2'd3;
localparam false = 1'b0, true = 1'b1;



reg tx_ready = false;
reg tx_start = false;
reg [1:0] tx_protocol;

wire tx_is_icmp = tx_protocol == PT_ICMP;
wire tx_is_arp = tx_protocol  == PT_ARP;
wire tx_is_udp = tx_protocol  == PT_UDP;
wire tx_is_dhcp = tx_protocol == PT_DHCP;



//udp = dhcp or udp, they have separate data
wire [7:0]  udp_data;
wire [15:0] udp_length;
wire [15:0] destination_port;
wire [31:0] to_ip;


//rgmii_recv out
wire rgmii_rx_active;  
wire [7:0] rx_data;

//mac_recv in
wire mac_rx_enable = rgmii_rx_active;

wire rx_is_arp;

//ip_recv in
wire ip_rx_enable = mac_rx_active && !rx_is_arp;
//ip_recv out
wire ip_rx_active;
wire rx_is_icmp;

//udp_recv in
wire udp_rx_enable = ip_rx_active && !rx_is_icmp;
assign udp_tx_enable = tx_start && (tx_is_udp || tx_is_dhcp);
//udp_recv out
assign udp_rx_data = rx_data;

//arp in
wire arp_rx_enable = mac_rx_active && rx_is_arp;
wire arp_tx_enable = tx_start && tx_is_arp;
//arp out
wire arp_tx_request;
wire arp_tx_active;
wire [7:0] arp_tx_data;
wire [47:0] arp_destination_mac;

// icmp in
assign  icmp_rx_enable = ip_rx_active && rx_is_icmp;
wire icmp_tx_enable = tx_start && tx_is_icmp;
//icmp out
wire icmp_tx_request;
wire icmp_tx_active;
wire [7:0] icmp_data;
wire [15:0] icmp_length;
wire [47:0] icmp_destination_mac;
wire [31:0] icmp_destination_ip;

//ip_send in
wire ip_tx_enable = icmp_tx_active || udp_tx_active;
wire [7:0] ip_tx_data_in = tx_is_icmp? icmp_data : udp_data;
wire [15:0] ip_tx_length = tx_is_icmp? icmp_length : udp_length;
wire [31:0] destination_ip = tx_is_icmp? icmp_destination_ip : (tx_is_dhcp ? dhcp_destination_ip : (run ? run_destination_ip :udp_destination_ip_sync));
//ip_send out
wire [7:0] ip_tx_data;
wire ip_tx_active;

//mac_send in
wire mac_tx_enable = arp_tx_active || ip_tx_active;
wire [7:0] mac_tx_data_in = tx_is_arp? arp_tx_data : ip_tx_data;
wire [47:0] destination_mac = tx_is_arp  ? arp_destination_mac  : 
										tx_is_icmp ? icmp_destination_mac :
										tx_is_dhcp ? dhcp_destination_mac : (run ? run_destination_mac : udp_destination_mac_sync);
//mac_send out
wire [7:0] mac_tx_data;
wire mac_tx_active;

//rgmii_send in
wire [7:0] rgmii_tx_data_in = mac_tx_data;
wire rgmii_tx_enable = mac_tx_active;
//rgmii_send out
wire rgmii_tx_active;

//dhcp
wire [15:0]dhcp_udp_tx_length        = tx_is_dhcp ? dhcp_tx_length        : udp_tx_length;
wire [7:0] dhcp_udp_tx_data          = tx_is_dhcp ? dhcp_tx_data          : udp_tx_data;
wire [15:0]local_port				    = tx_is_dhcp ? 16'd68 		           : 16'd1024; 
reg [15:0] run_destination_port;
reg [31:0] run_destination_ip;
reg [47:0] run_destination_mac;
// Hold destination port once run is set
always @(posedge tx_clock) 
	if (!run) begin
		run_destination_port <= udp_destination_port_sync;
		run_destination_ip <= udp_destination_ip_sync;
		run_destination_mac <= udp_destination_mac_sync;
	end
wire [15:0]dhcp_udp_destination_port = tx_is_dhcp ? dhcp_destination_port : (run ? run_destination_port : udp_destination_port_sync); 
wire dhcp_rx_active;
wire mac_rx_active; 
  

always @(posedge tx_clock)  
  if (rgmii_tx_active) 
    begin
		 tx_ready <= false;
		 tx_start <= false;
    end
  else if (tx_ready) tx_start <= true;
  else 
    begin
    if (arp_tx_request) begin tx_protocol <= PT_ARP; tx_ready <= true; end
    else if (icmp_tx_request) begin tx_protocol <= PT_ICMP; tx_ready <= true; end
    else if (dhcp_tx_request) begin tx_protocol <= PT_DHCP; tx_ready <= true; end
    else if (udp_tx_request)  begin tx_protocol <= PT_UDP; tx_ready <= true; end;
    end



//-----------------------------------------------------------------------------
//                               receive
//-----------------------------------------------------------------------------
rmii_recv rmii_recv_inst (
  //out
  .active(rgmii_rx_active),
  .data(rx_data),

   //in
  .reset(rx_reset),
  
  .clock(rx_clock),  
  .PHY_RX(PHY_RX),     
  .PHY_CRS(PHY_CRS),
  .PHY_CLK50(PHY_CLK50)
  );  

mac_recv mac_recv_inst(
  //in
  .rx_enable(mac_rx_enable),
  //out
  .active(mac_rx_active),
  .is_arp(rx_is_arp),
  .remote_mac(remote_mac), 
  .clock(rx_clock), 
  .data(rx_data),  
  .local_mac(local_mac),    
  .broadcast(broadcast)
  );  
  
  
ip_recv ip_recv_inst(
  // in
  .local_ip(local_ip),
  //out
  .active(ip_rx_active),
  .is_icmp(rx_is_icmp), 
  .remote_ip(remote_ip),

  .clock(rx_clock), 
  .rx_enable(ip_rx_enable),
  .broadcast(broadcast),
  .data(rx_data),

  .to_ip(to_ip)
  );    
  
udp_recv udp_recv_inst(
	//in
	.clock(rx_clock),
	.rx_enable(udp_rx_enable),
	.data(rx_data),
	.to_ip(to_ip),
   .local_ip(local_ip),
   .broadcast(broadcast),
	.remote_mac(remote_mac),
   .remote_ip(remote_ip),

	//out
	.active(udp_rx_active),
	.dhcp_active(dhcp_rx_active),
	.to_port(to_port),
	.udp_destination_ip(udp_destination_ip),   
   .udp_destination_mac(udp_destination_mac),
	.udp_destination_port(udp_destination_port)
	);
  
//-----------------------------------------------------------------------------
//                           receive/reply
//-----------------------------------------------------------------------------
arp arp_inst(
  //in
  .rx_enable(arp_rx_enable), 
  .tx_enable(arp_tx_enable),   
  //out
  .tx_active(arp_tx_active),
  .tx_data(arp_tx_data),
  .destination_mac(arp_destination_mac),
  .reset(tx_reset),  
  .rx_clock(rx_clock),  
  .rx_data(rx_data),  
  .tx_clock(tx_clock),  
  .local_mac(local_mac), 
  .local_ip(local_ip),
  .tx_request(arp_tx_request), 
  .remote_mac(remote_mac_sync)
);  

icmp icmp_inst (
  //in
  .rx_enable(icmp_rx_enable), 
  .tx_enable(icmp_tx_enable),  
  //out
  .tx_request(icmp_tx_request),
  .tx_active(icmp_tx_active),
  .tx_data(icmp_data),  
  .destination_mac(icmp_destination_mac),  
  .destination_ip(icmp_destination_ip),
  .length(icmp_length),
  .dst_unreachable(dst_unreachable),

  .remote_mac(remote_mac_sync),
  .remote_ip(remote_ip_sync),
  .reset(tx_reset), 
  .rx_clock(rx_clock),  
  .rx_data(rx_data),
  .tx_clock(tx_clock)  
);  

wire dhcp_tx_request;
reg dhcp_enable;
wire [7:0]  dhcp_tx_data;
wire [15:0] dhcp_tx_length;
wire [47:0] dhcp_destination_mac;
wire [31:0] dhcp_destination_ip;
wire [15:0] dhcp_destination_port;
wire [31:0] ip_accept;					// DHCP provided IP address
wire [31:0] lease;						// time in seconds that DHCP supplied IP address is valid
wire [31:0] server_ip;					// IP address of the DHCP that provided the IP address 
wire erase;
wire EPCS_FIFO_enable;
wire [47:0]remote_mac;
wire [31:0]remote_ip;
wire [15:0]remote_port;


dhcp dhcp_inst(
  //rx in
  .rx_clock(rx_clock),
  .rx_data(rx_data),
  .rx_enable(dhcp_enable),
  .dhcp_rx_active(dhcp_rx_active),
  //rx out 
  .lease(lease),
  .server_ip(server_ip),
  
  //tx in
  .reset(tx_reset),
  .rebind(dhcp_rebind),
  .tx_clock(tx_clock),
  .udp_tx_enable(udp_tx_enable),
  .tx_enable(dhcp_tx_enable),
  .udp_tx_active(udp_tx_active), 
  .remote_mac(remote_mac_sync),				// MAC address of DHCP server
  .remote_ip(remote_ip_sync),				// IP address of DHCP server 
  .dhcp_seconds_timer(dhcp_seconds_timer),

  // tx_out
  .dhcp_tx_request(dhcp_tx_request), 
  .tx_data(dhcp_tx_data),
  .length(dhcp_tx_length),
  .ip_accept(ip_accept),				// IP address from DHCP server
  
  //constants
  .local_mac(local_mac),
  .dhcp_destination_mac(dhcp_destination_mac),
  .dhcp_destination_ip(dhcp_destination_ip),
  .dhcp_destination_port(dhcp_destination_port),  

  // result
  .dhcp_success(dhcp_success0),
  .dhcp_failed(dhcp_failed),
  .dhcp_is_renewal(dhcp_is_renewal)
  
  );

//-----------------------------------------------------------------------------
//                                rx to tx clock domain transfers
//-----------------------------------------------------------------------------
wire [47:0] remote_mac_sync;
wire [31:0] remote_ip_sync;
wire [15:0] udp_destination_port;
wire [15:0] udp_destination_port_sync;
wire [47:0] udp_destination_mac;
wire [47:0] udp_destination_mac_sync;
wire [31:0] udp_destination_ip;
wire [31:0] udp_destination_ip_sync;

cdc_sync #(48)cdc_sync_inst1 (.siga(remote_mac), .rstb(0), .clkb(tx_clock), .sigb(remote_mac_sync)); 
cdc_sync #(32)cdc_sync_inst2 (.siga(remote_ip), .rstb(0), .clkb(tx_clock), .sigb(remote_ip_sync)); 
cdc_sync #(32) cdc_sync_inst7 (.siga(udp_destination_ip), .rstb(0), .clkb(tx_clock), .sigb(udp_destination_ip_sync)); 
cdc_sync #(48) cdc_sync_inst8 (.siga(udp_destination_mac), .rstb(0), .clkb(tx_clock), .sigb(udp_destination_mac_sync)); 
cdc_sync #(16) cdc_sync_inst9 (.siga(udp_destination_port), .rstb(0), .clkb(tx_clock), .sigb(udp_destination_port_sync)); 

  
//-----------------------------------------------------------------------------
//                               send
//-----------------------------------------------------------------------------
udp_send udp_send_inst (
  //in
  .reset(tx_reset),
  .clock(tx_clock),
  .tx_enable(udp_tx_enable),
  .data_in(dhcp_udp_tx_data),
  .length_in(dhcp_udp_tx_length),
  .local_port(local_port),
  .destination_port(dhcp_udp_destination_port),
  //out
  .active(udp_tx_active),
  .data_out(udp_data),
  .length_out(udp_length),
  .port_ID(port_ID)
  );

  
ip_send ip_send_inst (
  //in
  .data_in(ip_tx_data_in),
  .tx_enable(ip_tx_enable),
  .is_icmp(tx_is_icmp),
  .length(ip_tx_length),
  .destination_ip(destination_ip),
  //out
  .data_out(ip_tx_data),
  .active(ip_tx_active),

  .clock(tx_clock),
  .reset(tx_reset),
  .local_ip(local_ip)
  );  
  
mac_send mac_send_inst (
  //in
  .data_in(mac_tx_data_in),
  .tx_enable(mac_tx_enable),  
  .destination_mac(destination_mac),
  //out
  .data_out(mac_tx_data),
  .active(mac_tx_active),  

  .clock(tx_clock), 
  .local_mac(local_mac),
  .reset(tx_reset)
  );  
  
rmii_send rmii_send_inst (
  //in
  .data(rgmii_tx_data_in),  
  .tx_enable(rgmii_tx_enable),   
   //out
  .active(rgmii_tx_active),      
  .PHY_TX(PHY_TX),
  .PHY_TX_EN(PHY_TX_EN),              
  
  .PHY_CLK50(PHY_CLK50),   
  .clock(tx_clock) 
  );  
  

  
  
  
  
//-----------------------------------------------------------------------------
//                              debug output
//-----------------------------------------------------------------------------

assign speed_1Gbit = 1'b0;
assign network_status = {phy_connected, phy_duplex, 1'b1, udp_rx_active, udp_rx_enable, rgmii_rx_active, rgmii_tx_active, mac_rx_active};



endmodule

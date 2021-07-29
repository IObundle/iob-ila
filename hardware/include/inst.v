//instantiate core in system

   //
   // ILA
   //

/* EXAMPLE FOR WHEN I WAS DEBUGGING ETH
wire [31:0] s0,s1,s2,s3,s4,s5,s6,s7;

assign s0 = 32'h0 | eth.eth_dma.eth_dma_r.dma_addr;
assign s1 = 32'h0 | {16'h0 | eth.eth_dma.eth_dma_r.dma_end_index,16'h0 | eth.eth_dma.eth_dma_r.dma_start_index};
assign s2 = 32'h0 | eth.eth_dma.eth_dma_r.in_data;
assign s3 = 32'h0 | {eth.eth_dma.eth_dma_r.dma_read_strobe_start,
                     eth.eth_dma.eth_dma_r.in_wstrb,
                     eth.eth_dma.eth_dma_r.in_wstrb_start,
                     eth.eth_dma.eth_dma_r.read_wstrb,
                     eth.eth_dma.eth_dma_r.state};
assign s4 = 32'h0 |  eth.m_axi_rdata;
assign s5 = 32'h0 |  eth.m_axi_araddr;
assign s6 = 32'h0 |  {eth.dma_ready,eth.m_axi_rlast, eth.m_axi_arvalid,eth.m_axi_arready,eth.m_axi_rvalid,eth.m_axi_rready};
assign s7 = 32'h0 |  {eth.addr};

assign s0 = 32'h0 | eth.eth_dma.eth_dma_r.dma_addr;
assign s1 = 32'h0 | {16'h0 | eth.eth_dma.eth_dma_r.dma_end_index,16'h0 | eth.eth_dma.eth_dma_r.dma_start_index};
assign s2 = 32'h0 | eth.eth_dma.eth_dma_r.in_data;
assign s3 = 32'h0 | {eth.eth_dma.eth_dma_r.dma_read_strobe_start,
                     eth.eth_dma.eth_dma_r.in_wstrb,
                     eth.eth_dma.eth_dma_r.in_wstrb_start,
                     eth.eth_dma.eth_dma_r.read_wstrb,
                     eth.eth_dma.eth_dma_r.state};
assign s4 = 32'h0 |  eth.m_axi_rdata;
assign s5 = 32'h0 |  eth.m_axi_araddr;
assign s6 = 32'h0 |  {eth.dma_ready,eth.m_axi_rlast, eth.m_axi_arvalid,eth.m_axi_arready,eth.m_axi_rvalid,eth.m_axi_rready};
assign s7 = 32'h0 |  {eth.addr};

// Eth simple interface
//wire [31:0] s0 = 32'h0 | slaves_req[`wdata(`ETHERNET)];
//wire [31:0] s1 = 32'h0 | slaves_resp[`rdata(`ETHERNET)];
//wire [31:0] s2 = 32'h0 | {4'h0 | slaves_resp[`ready(`ETHERNET)],4'h0 | slaves_req[`valid(`ETHERNET)],4'h0 | slaves_req[`wstrb(`ETHERNET)],16'h0 | slaves_req[`address(`ETHERNET, `ETH_ADDR_W+2)-2]};
//wire [31:0] s3 = 32'h0 | {4'h0 | m_axi_rlast[1*1+:1],4'h0 | m_axi_arsize[1*3+:3],8'h0 | m_axi_arlen[1*8+:8]};
//wire [31:0] s4 = 32'h0 | m_axi_rdata[1*`MIG_BUS_W+:`MIG_BUS_W];
//wire [31:0] s5 = 32'h0 | {{ETH_PHY_RESETN,PLL_LOCKED},1'b0, 1'b0,4'h0 | eth.eth_dma.eth_dma_r.state,m_axi_rready[1*1+:1],m_axi_rvalid[1*1+:1],m_axi_arready[1*1+:1],m_axi_arvalid[1*1+:1]};
//assign s6 = 32'h0 | {15'b0, eth.dma_ready, eth.tx_clk_pll_locked[1], eth.rx_wr_addr_cpu[1], eth.phy_clk_detected_sync[1], eth.phy_dv_detected_sync[1], eth.rx_data_rcvd[1], eth.tx_ready[1]};
//assign s7 = 32'h0 | eth.tx_wr_data;

wire [31:0] s10 = 32'h0 | eth.eth_dma.eth_dma_r.m_axi_araddr;
wire [31:0] s11 = 32'h0 | eth.eth_dma.eth_dma_r.m_axi_arlen;
wire [31:0] s12 = 32'h0 | eth.eth_dma.eth_dma_r.m_axi_rdata;
wire [31:0] s13 = 32'h0 | eth.eth_dma.eth_dma_r.dma_len;
wire [31:0] s14 = 32'h0 | {4'h0 | eth.eth_dma.eth_dma_r.in_wr,8'h0 | eth.eth_dma.eth_dma_r.state, 16'h0 | eth.eth_dma.eth_dma_w.transfers};
wire [31:0] s15 = 32'h0 | eth.eth_dma.eth_dma_r.in_data;
wire [31:0] s16 = 32'h0 | eth.eth_dma.eth_dma_r.in_addr;
wire [31:0] s17 = 32'h0 | {4'h0 | eth.eth_dma.eth_dma_w.m_axi_bready,4'h0 | eth.eth_dma.eth_dma_w.m_axi_bvalid,4'h0 | eth.eth_dma.eth_dma_r.m_axi_rlast, 4'h0 | eth.eth_dma.eth_dma_r.m_axi_rready,4'h0 | eth.eth_dma.eth_dma_r.m_axi_rvalid,4'h0 | eth.eth_dma.eth_dma_r.m_axi_arready,4'h0 | eth.eth_dma.eth_dma_r.m_axi_arvalid};

// br,bv,l     wr,wv,awr,awv

wire [255:0] ila_signal1 = 256'h0; //| {128'h0,ila_system};
wire [255:0] ila_signal2 = 256'h0 | {s17,s16,s15,s14,s13,s12,s11,s10};

wire [7:0] ila_triggers = {!eth.dma_ready,1'b0,m_axi_awvalid[1*1+:1],m_axi_arvalid[1*1+:1],4'h0 | ila_trigger};

   iob_ila #(
      .SIGNAL_W(512),
      .BUFFER_W(13),
      .TRIGGER_W(8)
      )
     ila
     (
      //CPU interface
      .clk       (clk),
      .rst       (reset),
      .valid(slaves_req[`valid(`ILA)]),
      .address(slaves_req[`address(`ILA,`ILA_ADDR_W+2)-2]),
      .wdata(slaves_req[`wdata(`ILA)-(`DATA_W-`ILA_WDATA_W)]),
      .wstrb(slaves_req[`wstrb(`ILA)]),
      .rdata(slaves_resp[`rdata(`ILA)]),
      .ready(slaves_resp[`ready(`ILA)]),

      .signal({ila_signal2,ila_signal1}),
      .trigger(ila_triggers),
      .sampling_clk(clk)
      );

*/

   iob_ila #(
      .SIGNAL_W(32),
      .BUFFER_W(13),
      .TRIGGER_W(8)
      )
     ila
     (
      //CPU interface
      .clk       (clk),
      .rst       (reset),
      .valid(slaves_req[`valid(`ILA)]),
      .address(slaves_req[`address(`ILA,`ILA_ADDR_W+2)-2]),
      .wdata(slaves_req[`wdata(`ILA)-(`DATA_W-`ILA_WDATA_W)]),
      .wstrb(slaves_req[`wstrb(`ILA)]),
      .rdata(slaves_resp[`rdata(`ILA)]),
      .ready(slaves_resp[`ready(`ILA)]),

      .signal(32'h0),
      .trigger(8'h0),
      .sampling_clk(clk)
      );

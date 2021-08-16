//instantiate core in system

   //
   // ILA
   //

reg rx_counter_1,rx_counter_2;
always @(posedge clk,posedge reset)
begin
   if(reset) begin
      rx_counter_1 <= 0;
      rx_counter_2 <= 0;
   end else begin
      rx_counter_1 <= RX_DV;
      rx_counter_2 <= rx_counter_1;
   end
end

`define DMA eth.dma

wire [31:0] s0 = eth.rd_data_out;
wire [31:0] s1 = eth.tx_data;
wire [31:0] s2 = eth.m_axi_wdata;
wire [31:0] s3 = eth.m_axi_rdata;
wire [31:0] s4 = {8'h0 | `DMA.state,4'h0 | {eth.m_axi_rlast,eth.m_axi_wlast},8'h0 | eth.m_axi_awlen,4'h0 | {eth.m_axi_wvalid,eth.m_axi_wready,eth.m_axi_rvalid,eth.m_axi_rready},4'h0 | eth.m_axi_wstrb};
wire [31:0] s5 = `DMA.data_out;
wire [31:0] s6 = `DMA.rdata;
wire [31:0] s7 = {2'h0 | `DMA.addr[1:0],1'h0 | `DMA.n_ready,1'h0 | `DMA.ready_out,1'h0 | `DMA.align_valid_out};

wire [31:0] s10 = {15'b0, eth.dma_ready, eth.tx_clk_pll_locked[1], eth.rx_wr_addr_cpu[1], eth.phy_clk_detected_sync[1], eth.phy_dv_detected_sync[1], eth.rx_data_rcvd[1], eth.tx_ready[1]}; 
wire [31:0] s11 = {rx_counter_2,eth.rx_wr,eth.rcv_ack}; 
wire [31:0] s12 = 32'h0; 
wire [31:0] s13 = 32'h0;
wire [31:0] s14 = 32'h0; 
wire [31:0] s15 = 32'h0; 
wire [31:0] s16 = 32'h0; 
wire [31:0] s17 = 32'h0; 

wire [255:0] ila_signal1 = 256'h0 | {s7,s6,s5,s4,s3,s2,s1,s0};
wire [255:0] ila_signal2 = 256'h0 | {s17,s16,s15,s14,s13,s12,s11,s10};

wire [7:0] ila_triggers = {4'h0,!eth.dma_ready,1'b0,m_axi_awvalid[1*1+:1],m_axi_arvalid[1*1+:1]};

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
      .wdata(slaves_req[`wdata(`ILA)]),
      .wstrb(slaves_req[`wstrb(`ILA)]),
      .rdata(slaves_resp[`rdata(`ILA)]),
      .ready(slaves_resp[`ready(`ILA)]),

      .signal({ila_signal2,ila_signal1}),
      .trigger(ila_triggers),
      .sampling_clk(clk)
      );

`undef DMA

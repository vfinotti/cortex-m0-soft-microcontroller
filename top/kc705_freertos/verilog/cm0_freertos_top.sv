///////////////////////////////////////////////////////////////////////////////
// Vitor Finotti
//
// <project-url>
///////////////////////////////////////////////////////////////////////////////
//
// unit name:     ARM Cortex M-0 implementation on FPGA
//
// description:
//
//
//
///////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019 Vitor Finotti
///////////////////////////////////////////////////////////////////////////////
// MIT
///////////////////////////////////////////////////////////////////////////////
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
///////////////////////////////////////////////////////////////////////////////


module cm0_freertos_top (
  output led0,
  output led1,
  output led2,
  output led3,
  output led4,
  output led5,
  output led6,
  output led7,
  input  push_button0_i,
  input  sys_clk_p_i,
  input  sys_clk_n_i);

   //////////////////////////////////////////////////////////////////
   //
   // Constants
   //

   localparam c_masters_num = 2;
   localparam c_slaves_num  = 10;
   localparam c_haddr_width = 32;
   localparam c_hdata_width = 32;



   //////////////////////////////////////////////////////////////////
   //
   // Variables
   //

   // Common signals
   logic                           clk_10mhz;
   logic                           clk_100mhz;
   logic                           clk_200mhz;
   logic                           rst_n;
   logic                           rst;
   logic                           led_value;


   // Master Ports; AHB masters connect to these
   //  thus these are actually AHB Slave Interfaces
   logic [              2:0] mst_priority  [c_masters_num];
   logic                     mst_hsel      [c_masters_num];
   logic [c_haddr_width-1:0] mst_haddr     [c_masters_num];
   logic [c_hdata_width-1:0] mst_hwdata    [c_masters_num];
   logic [c_hdata_width-1:0] mst_hrdata    [c_masters_num];
   logic                     mst_hwrite    [c_masters_num];
   logic [              2:0] mst_hsize     [c_masters_num];
   logic [              2:0] mst_hburst    [c_masters_num];
   logic [              3:0] mst_hprot     [c_masters_num];
   logic [              1:0] mst_htrans    [c_masters_num];
   logic                     mst_hmastlock [c_masters_num];
   logic                     mst_hreadyout [c_masters_num];
   logic                     mst_hready    [c_masters_num];
   logic                     mst_hresp     [c_masters_num];
   // Slave Ports; AHB Slaves connect to these
   //  thus these are actually AHB Master Interfaces
   logic [c_haddr_width-1:0] slv_addr_mask [c_slaves_num];
   logic [c_haddr_width-1:0] slv_addr_base [c_slaves_num];
   logic                     slv_hsel      [c_slaves_num];
   logic [c_haddr_width-1:0] slv_haddr     [c_slaves_num];
   logic [c_hdata_width-1:0] slv_hwdata    [c_slaves_num];
   logic [c_hdata_width-1:0] slv_hrdata    [c_slaves_num];
   logic                     slv_hwrite    [c_slaves_num];
   logic [              2:0] slv_hsize     [c_slaves_num];
   logic [              2:0] slv_hburst    [c_slaves_num];
   logic [              3:0] slv_hprot     [c_slaves_num];
   logic [              1:0] slv_htrans    [c_slaves_num];
   logic                     slv_hmastlock [c_slaves_num];
   logic                     slv_hreadyout [c_slaves_num]; // hreadyout to slave-decoder; generates hready to all connected slaves
   logic                     slv_hready    [c_slaves_num]; // combinatorial hready from all connected slaves
   logic                     slv_hresp     [c_slaves_num];


   // Other signals
   logic [           31 : 0] irq_vector;


   //////////////////////////////////////////////////////////////////
   //
   // Module Body
   //

   assign mst_priority  [0]  = "111";
   assign mst_priority  [1]  = "001";
   assign slv_addr_mask [0]  = 32'hE000_0000;
   assign slv_addr_base [0]  = 32'h0000_0000;
   assign slv_addr_mask [1]  = 32'hE000_0000;
   assign slv_addr_base [1]  = 32'h2000_0000;
   assign slv_addr_mask [2]  = 32'hFFFF_FFE0;
   assign slv_addr_base [2]  = 32'h4000_0000;
   assign slv_addr_mask [3]  = 32'hFFFF_FFE0;
   assign slv_addr_base [3]  = 32'h4000_0100;
   assign slv_addr_mask [4]  = 32'hFFFF_FFE0;
   assign slv_addr_base [4]  = 32'h4000_0200;
   assign slv_addr_mask [5]  = 32'hFFFF_FFE0;
   assign slv_addr_base [5]  = 32'h4000_0300;
   assign slv_addr_mask [6]  = 32'hFFFF_FFC0;
   assign slv_addr_base [6]  = 32'h4000_0400;
   assign slv_addr_mask [7]  = 32'hFFFF_F000;
   assign slv_addr_base [7]  = 32'h4000_1000;
   assign slv_addr_mask [8]  = 32'hFFFF_F000;
   assign slv_addr_base [8]  = 32'h4000_2000;
   assign slv_addr_mask [9]  = 32'hFFFF_F000;
   assign slv_addr_base [9]  = 32'h5000_0000; // for a limitation on the DMA, no
                                              // other core should start with
                                              // addr "5' (check "rf_addr" on
                                              // page 31 of its datasheet

   assign led3 = led_value;
   assign led4 = rst_n;
   assign led5 = 1'b1;
   assign led6 = 1'b0;
   assign led7 = 1'b1;
   assign rst = !rst_n;
   assign push_button0_n = !push_button0_i;

   assign irq_vector [31:2] = {30{1'b0}};


   IBUFDS #(
     .DIFF_TERM    ( "FALSE"     ),       // Differential Termination
     .IBUF_LOW_PWR ( "TRUE"      ),       // Low power="TRUE", Highest perforrmance="FALSE"
     .IOSTANDARD   ( "DEFAULT"   ) )      // Specify the input I/O standard
   cmp_ibufds_clk_gen (
     .O            ( clk_200mhz  ),       // Buffer output
     .I            ( sys_clk_p_i ),       // Diff_p buffer input (connect directly to top-level port)
     .IB           ( sys_clk_n_i ) );     // Diff_n buffer input (connect directly to top-level port)


   detection_fsm inst_detector (
     .clk_i      ( clk_10mhz      ),
     .rst_i      ( rst            ),
     .data_i     ( mst_hrdata [0] ),
     .detected_o ( led_value      ) );


   gc_single_reset_gen  #(
     .g_out_reg_depth   ( 5              ),    // delay for 5 clk cycles
     .g_rst_in_num      ( 1              ) )   // just 1 input
   gc_single_reset_gen (
     .clk_i             ( clk_10mhz      ),
     .rst_signals_n_a_i ( push_button0_n ),
     .rst_n_o           ( rst_n          ) );


   sys_pll #(
     .g_clkin_period   ( 5.000      ),          // 200 MHz
     .g_divclk_divide  ( 1          ),
     .g_clkbout_mult_f ( 5          ),
     .g_clk0_divide_f  ( 100        ),          // 10 MHz
     .g_clk1_divide    ( 10         ),          // 100 MHz
     .g_clk2_divide    ( 100        ) )         // 10 MHz
   sys_pll (
     .rst_i            ( 1'b0       ),
     .clk_i            ( clk_200mhz ),
     .clk0_o           ( clk_10mhz  ),
     .clk1_o           ( clk_100mhz ),
     .clk2_o           (            ),
     .locked_o         ( led0       ) );

   ahb3lite_sram1rw #(
     .MEM_DEPTH         ( 8192             ),   // Memory depth
     .HADDR_SIZE        ( 32               ),
     .HDATA_SIZE        ( 32               ),
     .TECHNOLOGY        ( "GENERIC"        ),
     .REGISTERED_OUTPUT ( "NO"             ),
     .INIT_FILE         ( "../../../modules/memory/memory_freertos_dma_sim.mem" ) )
   rom (
     .HRESETn           ( rst_n            ),
     .HCLK              ( clk_10mhz        ),
     .HSEL              ( slv_hsel      [0]),
     .HADDR             ( slv_haddr     [0]),
     .HWDATA            ( slv_hwdata    [0]),
     .HRDATA            ( slv_hrdata    [0]),
     .HWRITE            ( slv_hwrite    [0]),
     .HSIZE             ( slv_hsize     [0]),
     .HBURST            ( slv_hburst    [0]),
     .HPROT             ( slv_hprot     [0]),
     .HTRANS            ( slv_htrans    [0]),
     .HREADYOUT         ( slv_hreadyout [0]),
     .HREADY            ( slv_hready    [0]),
     .HRESP             ( slv_hresp     [0]) );

   // assign slv_hready [0] = rst_n;


   ahb3lite_sram1rw #(
     .MEM_SIZE          ( 0                 ),   // Memory in Bytes
     .MEM_DEPTH         ( 8192              ),   // Memory depth
     .HADDR_SIZE        ( 32                ),
     .HDATA_SIZE        ( 32                ),
     .TECHNOLOGY        ( "GENERIC"         ),
     .REGISTERED_OUTPUT ( "NO"              ) )
   ram (
     .HRESETn           ( rst_n             ),
     .HCLK              ( clk_10mhz         ),
     .HSEL              ( slv_hsel      [1] ),
     .HADDR             ( slv_haddr     [1] ),
     .HWDATA            ( slv_hwdata    [1] ),
     .HRDATA            ( slv_hrdata    [1] ),
     .HWRITE            ( slv_hwrite    [1] ),
     .HSIZE             ( slv_hsize     [1] ),
     .HBURST            ( slv_hburst    [1] ),
     .HPROT             ( slv_hprot     [1] ),
     .HTRANS            ( slv_htrans    [1] ),
     .HREADYOUT         ( slv_hreadyout [1] ),
     .HREADY            ( slv_hready    [1] ),
     .HRESP             ( slv_hresp     [1] ) );

   ahb3lite_cordic #(
     .g_iterations ( 32               ),
     .g_haddr_size ( c_haddr_width    ),
     .g_hdata_size ( c_hdata_width    ) )
   cordic0 (
     .hreset_n_i   ( rst_n            ),
     .hclk_i       ( clk_10mhz        ),
     .hsel_i       ( slv_hsel      [2]),
     .haddr_i      ( slv_haddr     [2]),
     .hwdata_i     ( slv_hwdata    [2]),
     .hrdata_o     ( slv_hrdata    [2]),
     .hwrite_i     ( slv_hwrite    [2]),
     .hsize_i      ( slv_hsize     [2]),
     .hburst_i     ( slv_hburst    [2]),
     .hprot_i      ( slv_hprot     [2]),
     .htrans_i     ( slv_htrans    [2]),
     .hreadyout_o  ( slv_hreadyout [2]),
     .hready_i     ( slv_hreadyout [2]),
     .hresp_o      ( slv_hresp     [2]) );

   ahb3lite_cordic #(
     .g_iterations ( 32               ),
     .g_haddr_size ( c_haddr_width    ),
     .g_hdata_size ( c_hdata_width    ) )
   cordic1 (
     .hreset_n_i   ( rst_n            ),
     .hclk_i       ( clk_10mhz        ),
     .hsel_i       ( slv_hsel      [3]),
     .haddr_i      ( slv_haddr     [3]),
     .hwdata_i     ( slv_hwdata    [3]),
     .hrdata_o     ( slv_hrdata    [3]),
     .hwrite_i     ( slv_hwrite    [3]),
     .hsize_i      ( slv_hsize     [3]),
     .hburst_i     ( slv_hburst    [3]),
     .hprot_i      ( slv_hprot     [3]),
     .htrans_i     ( slv_htrans    [3]),
     .hreadyout_o  ( slv_hreadyout [3]),
     .hready_i     ( slv_hreadyout [3]),
     .hresp_o      ( slv_hresp     [3]) );

   ahb3lite_cordic #(
     .g_iterations ( 32               ),
     .g_haddr_size ( c_haddr_width    ),
     .g_hdata_size ( c_hdata_width    ) )
   cordic2 (
     .hreset_n_i   ( rst_n            ),
     .hclk_i       ( clk_10mhz        ),
     .hsel_i       ( slv_hsel      [4]),
     .haddr_i      ( slv_haddr     [4]),
     .hwdata_i     ( slv_hwdata    [4]),
     .hrdata_o     ( slv_hrdata    [4]),
     .hwrite_i     ( slv_hwrite    [4]),
     .hsize_i      ( slv_hsize     [4]),
     .hburst_i     ( slv_hburst    [4]),
     .hprot_i      ( slv_hprot     [4]),
     .htrans_i     ( slv_htrans    [4]),
     .hreadyout_o  ( slv_hreadyout [4]),
     .hready_i     ( slv_hreadyout [4]),
     .hresp_o      ( slv_hresp     [4]) );

   ahb3lite_cordic #(
     .g_iterations ( 32               ),
     .g_haddr_size ( c_haddr_width    ),
     .g_hdata_size ( c_hdata_width    ) )
   cordic3 (
     .hreset_n_i   ( rst_n            ),
     .hclk_i       ( clk_10mhz        ),
     .hsel_i       ( slv_hsel      [5]),
     .haddr_i      ( slv_haddr     [5]),
     .hwdata_i     ( slv_hwdata    [5]),
     .hrdata_o     ( slv_hrdata    [5]),
     .hwrite_i     ( slv_hwrite    [5]),
     .hsize_i      ( slv_hsize     [5]),
     .hburst_i     ( slv_hburst    [5]),
     .hprot_i      ( slv_hprot     [5]),
     .htrans_i     ( slv_htrans    [5]),
     .hreadyout_o  ( slv_hreadyout [5]),
     .hready_i     ( slv_hreadyout [5]),
     .hresp_o      ( slv_hresp     [5]) );

   ahb3lite_timer #(
     //AHB Parameters
     .HADDR_SIZE ( c_haddr_width    ),
     .HDATA_SIZE ( c_hdata_width    ),
     //Timer Parameters
     .TIMERS     ( 1                ) )  //Number of timers
   timer0 (
     .HRESETn    ( rst_n            ),
     .HCLK       ( clk_10mhz        ),
     //AHB Slave Interfaces (receive data from AHB Masters)
     //AHB Masters connect to these ports
     .HSEL       ( slv_hsel      [6]),
     .HADDR      ( slv_haddr     [6]),
     .HWDATA     ( slv_hwdata    [6]),
     .HRDATA     ( slv_hrdata    [6]),
     .HWRITE     ( slv_hwrite    [6]),
     .HSIZE      ( slv_hsize     [6]),
     .HBURST     ( slv_hburst    [6]),
     .HPROT      ( slv_hprot     [6]),
     .HTRANS     ( slv_htrans    [6]),
     .HREADYOUT  ( slv_hreadyout [6]),
     .HREADY     ( slv_hreadyout [6]),
     .HRESP      ( slv_hresp     [6]),
     .tint       ( irq_vector    [0]) );  //Timer Interrupt

   ahb3lite_sram1rw #(
     .MEM_SIZE          ( 0                 ),   // Memory in Bytes
     .MEM_DEPTH         ( 512               ),   // Memory depth
     .HADDR_SIZE        ( c_haddr_width     ),
     .HDATA_SIZE        ( c_hdata_width     ),
     .TECHNOLOGY        ( "GENERIC"         ),
     .REGISTERED_OUTPUT ( "NO"             ),
     .INIT_FILE         ( "../../../modules/memory/memory_dummy.mem" ) )
   generic_memory_0 (
     .HRESETn           ( rst_n             ),
     .HCLK              ( clk_10mhz         ),
     .HSEL              ( slv_hsel      [7] ),
     .HADDR             ( slv_haddr     [7] ),
     .HWDATA            ( slv_hwdata    [7] ),
     .HRDATA            ( slv_hrdata    [7] ),
     .HWRITE            ( slv_hwrite    [7] ),
     .HSIZE             ( slv_hsize     [7] ),
     .HBURST            ( slv_hburst    [7] ),
     .HPROT             ( slv_hprot     [7] ),
     .HTRANS            ( slv_htrans    [7] ),
     .HREADYOUT         ( slv_hreadyout [7] ),
     .HREADY            ( slv_hready    [7] ),
     .HRESP             ( slv_hresp     [7] ) );

   ahb3lite_sram1rw #(
     .MEM_SIZE          ( 0                 ),   // Memory in Bytes
     .MEM_DEPTH         ( 512               ),   // Memory depth
     .HADDR_SIZE        ( c_haddr_width     ),
     .HDATA_SIZE        ( c_hdata_width     ),
     .TECHNOLOGY        ( "GENERIC"         ),
     .REGISTERED_OUTPUT ( "NO"              ) )
   generic_memory_1 (
     .HRESETn           ( rst_n             ),
     .HCLK              ( clk_10mhz         ),
     .HSEL              ( slv_hsel      [8] ),
     .HADDR             ( slv_haddr     [8] ),
     .HWDATA            ( slv_hwdata    [8] ),
     .HRDATA            ( slv_hrdata    [8] ),
     .HWRITE            ( slv_hwrite    [8] ),
     .HSIZE             ( slv_hsize     [8] ),
     .HBURST            ( slv_hburst    [8] ),
     .HPROT             ( slv_hprot     [8] ),
     .HTRANS            ( slv_htrans    [8] ),
     .HREADYOUT         ( slv_hreadyout [8] ),
     .HREADY            ( slv_hready    [8] ),
     .HRESP             ( slv_hresp     [8] ) );


   ahb3lite_dma #(
     // chXX_conf = { CBUF, ED, ARS, EN }
     .rf_addr   ( 4'h5                  ), // bits are compared with 31:28 of addr to access inner registers
     .pri_sel   ( 2'h0                  ),
     .ch_count  ( 1                     ),
     .ch0_conf  ( 4'h1                  ),
     .ch1_conf  ( 4'h0                  ),
     .ch2_conf  ( 4'h0                  ),
     .ch3_conf  ( 4'h0                  ),
     .ch4_conf  ( 4'h0                  ),
     .ch5_conf  ( 4'h0                  ),
     .ch6_conf  ( 4'h0                  ),
     .ch7_conf  ( 4'h0                  ),
     .ch8_conf  ( 4'h0                  ),
     .ch9_conf  ( 4'h0                  ),
     .ch10_conf ( 4'h0                  ),
     .ch11_conf ( 4'h0                  ),
     .ch12_conf ( 4'h0                  ),
     .ch13_conf ( 4'h0                  ),
     .ch14_conf ( 4'h0                  ),
     .ch15_conf ( 4'h0                  ),
     .ch16_conf ( 4'h0                  ),
     .ch17_conf ( 4'h0                  ),
     .ch18_conf ( 4'h0                  ),
     .ch19_conf ( 4'h0                  ),
     .ch20_conf ( 4'h0                  ),
     .ch21_conf ( 4'h0                  ),
     .ch22_conf ( 4'h0                  ),
     .ch23_conf ( 4'h0                  ),
     .ch24_conf ( 4'h0                  ),
     .ch25_conf ( 4'h0                  ),
     .ch26_conf ( 4'h0                  ),
     .ch27_conf ( 4'h0                  ),
     .ch28_conf ( 4'h0                  ),
     .ch29_conf ( 4'h0                  ),
     .ch30_conf ( 4'h0                  ) )
   dma0 (
     // Common signals
     .clk_i        ( clk_10mhz          ),
     .rst_n_i      ( rst_n              ),
     // --------------------------------------
     // AHB3-Lite INTERFACE 0
     // Slave Interface
     .s0HSEL       ( slv_hsel      [9]  ),
     .s0HADDR      ( slv_haddr     [9]  ),
     .s0HWDATA     ( slv_hwdata    [9]  ),
     .s0HRDATA     ( slv_hrdata    [9]  ),
     .s0HWRITE     ( slv_hwrite    [9]  ),
     .s0HSIZE      ( slv_hsize     [9]  ),
     .s0HBURST     ( slv_hburst    [9]  ),
     .s0HPROT      ( slv_hprot     [9]  ),
     .s0HTRANS     ( slv_htrans    [9]  ),
     .s0HREADYOUT  ( slv_hreadyout [9]  ),
     .s0HREADY     ( slv_hready    [9]  ),
     .s0HRESP      ( slv_hresp     [9]  ),
     // Master Interface
     .m0HSEL       ( mst_hsel      [1]  ),
     .m0HADDR      ( mst_haddr     [1]  ),
     .m0HWDATA     ( mst_hwdata    [1]  ),
     .m0HRDATA     ( mst_hrdata    [1]  ),
     .m0HWRITE     ( mst_hwrite    [1]  ),
     .m0HSIZE      ( mst_hsize     [1]  ),
     .m0HBURST     ( mst_hburst    [1]  ),
     .m0HPROT      ( mst_hprot     [1]  ),
     .m0HTRANS     ( mst_htrans    [1]  ),
     .m0HREADYOUT  ( mst_hready    [1]  ),
     .m0HREADY     ( mst_hreadyout [1]  ),
     .m0HRESP      ( mst_hresp     [1]  ),
     // --------------------------------------
     // Misc Signal,
     .dma_req_i    ( 1'b0               ),
     .dma_nd_i     ( 1'b0               ),
     .dma_ack_o    ( dma_ack_o          ),
     .dma_rest_i   ( 1'b0               ),
     .irqa_o       ( irq_vector[1]      ),
     .irqb_o       ( irqb_o             ) );


  ahb3lite_interconnect #(
    .HADDR_SIZE    ( c_haddr_width ),
    .HDATA_SIZE    ( 32            ),
    .MASTERS       ( c_masters_num ),   //number of AHB Masters
    .SLAVES        ( c_slaves_num  )    //number of AHB slaves
    )
  interconnection (
    // Common signals
    .HRESETn       ( rst_n         ),
    .HCLK          ( clk_10mhz     ),
    // Master Ports
    .mst_priority  ( mst_priority  ),
    .mst_HSEL      ( mst_hsel      ),
    .mst_HADDR     ( mst_haddr     ),
    .mst_HWDATA    ( mst_hwdata    ),
    .mst_HRDATA    ( mst_hrdata    ),
    .mst_HWRITE    ( mst_hwrite    ),
    .mst_HSIZE     ( mst_hsize     ),
    .mst_HBURST    ( mst_hburst    ),
    .mst_HPROT     ( mst_hprot     ),
    .mst_HTRANS    ( mst_htrans    ),
    .mst_HMASTLOCK ( mst_hmastlock ),
    .mst_HREADYOUT ( mst_hreadyout ),
    .mst_HREADY    ( mst_hready    ),
    .mst_HRESP     ( mst_hresp     ),
    // Slave Ports
    .slv_addr_mask ( slv_addr_mask ),
    .slv_addr_base ( slv_addr_base ),
    .slv_HSEL      ( slv_hsel      ),
    .slv_HADDR     ( slv_haddr     ),
    .slv_HWDATA    ( slv_hwdata    ),
    .slv_HRDATA    ( slv_hrdata    ),
    .slv_HWRITE    ( slv_hwrite    ),
    .slv_HSIZE     ( slv_hsize     ),
    .slv_HBURST    ( slv_hburst    ),
    .slv_HPROT     ( slv_hprot     ),
    .slv_HTRANS    ( slv_htrans    ),
    .slv_HMASTLOCK ( slv_hmastlock ),
    .slv_HREADYOUT ( slv_hready    ), // HREADYOUT to slave-decoder; generates HREADY to all connected slaves
    .slv_HREADY    ( slv_hreadyout ), // combinatorial HREADY from all connected slaves
    .slv_HRESP     ( slv_hresp     )
    );


   cortex_m0_wrapper cortex_m0 (
     // clock and resets
     .hclk_i                ( clk_10mhz         ),      // clock
     .hreset_n_i            ( rst_n             ),      // asynchronous reset
     // ahb-lite master port
     .haddr_o               ( mst_haddr     [0] ),      // ahb transaction address
     .hburst_o              ( mst_hburst    [0] ),      // ahb burst: tied to single
     .hmastlock_o           (                   ),      // ahb locked transfer (always zero)
     .hprot_o               ( mst_hprot     [0] ),      // ahb protection: priv; data or inst
     .hsize_o               ( mst_hsize     [0] ),      // ahb size: byte, half-word or word
     .htrans_o              ( mst_htrans    [0] ),      // ahb transfer: non-sequential only
     .hwdata_o              ( mst_hwdata    [0] ),      // ahb write-data
     .hwrite_o              ( mst_hwrite    [0] ),      // ahb write control
     .hrdata_i              ( mst_hrdata    [0] ),      // ahb read-data
     .hready_i              ( mst_hreadyout [0] ),      // mst_hready_0,               // ahb stall signal
     .hresp_i               ( 1'b0              ),      // mst_hresp_0,                // ahb error response
     // miscellaneous
     .nmi_i                 ( 1'b0              ),      // non-maskable interrupt input
     .irq_i                 ( irq_vector        ),      // interrupt request inputs
     .txev_o                (                   ),      // event output (sev executed)
     .rxev_i                ( 1'b0              ),      // event input
     .lockup_o              ( led2              ),      // core is locked-up
     .sysresetreq_o         (                   ),      // system reset request
     // power management
     .sleeping_o            ( led1              ) );    // core and nvic sleeping

   assign mst_hready [0] = 1'b1; // Cortex M0 has no hreadyout
   assign mst_hsel   [0] = 1'b1; // Cortex M0 has no hsel

endmodule // cm0_freertos_top

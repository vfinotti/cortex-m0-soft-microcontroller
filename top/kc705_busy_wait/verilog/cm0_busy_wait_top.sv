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


module cm0_busy_wait_top (
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

   localparam c_masters_num = 1;
   localparam c_slaves_num  = 1;
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



   //////////////////////////////////////////////////////////////////
   //
   // Module Body
   //

   assign mst_priority [0] = "111";
   assign mst_hsel [0] = 1'b1;
   assign slv_addr_mask [0] = 32'hE000_0000;
   assign slv_addr_base [0] = 32'h0000_0000;
   assign slv_addr_mask [1] = 32'hE000_0000;
   assign slv_addr_base [1] = 32'h2000_0000;

   assign led3 = led_value;
   assign led4 = rst_n;
   assign led5 = 1'b1;
   assign led6 = 1'b0;
   assign led7 = 1'b1;
   assign rst = !rst_n;
   assign push_button0_n = !push_button0_i;



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
   .MEM_DEPTH         ( 512              ),   // Memory depth
   .HADDR_SIZE        ( 32               ),
   .HDATA_SIZE        ( 32               ),
   .TECHNOLOGY        ( "GENERIC"        ),
   .REGISTERED_OUTPUT ( "NO"             ),
   .INIT_FILE         ( "/home/vfinotti/clones/cortex-m0-soft-microcontroller/modules/memory/memory_1M_syn.mem" ) )
 rom (
  .HRESETn            ( rst_n            ),
  .HCLK               ( clk_10mhz        ),
  .HSEL               ( slv_hsel      [0]),
  .HADDR              ( slv_haddr     [0]),
  .HWDATA             ( slv_hwdata    [0]),
  .HRDATA             ( slv_hrdata    [0]),
  .HWRITE             ( slv_hwrite    [0]),
  .HSIZE              ( slv_hsize     [0]),
  .HBURST             ( slv_hburst    [0]),
  .HPROT              ( slv_hprot     [0]),
  .HTRANS             ( slv_htrans    [0]),
  .HREADYOUT          ( slv_hreadyout [0]),
  .HREADY             ( slv_hready    [0]),
  .HRESP              ( slv_hresp     [0]) );

   // assign slv_hready [0] = rst_n;


 // ahb3lite_sram1rw #(
 //   .MEM_SIZE          ( 0                 ),   // Memory in Bytes
 //   .MEM_DEPTH         ( 512               ),   // Memory depth
 //   .HADDR_SIZE        ( 32                ),
 //   .HDATA_SIZE        ( 32                ),
 //   .TECHNOLOGY        ( "GENERIC"         ),
 //   .REGISTERED_OUTPUT ( "NO"              ) )
 // ram (
 //  .HRESETn            ( rst_n             ),
 //  .HCLK               ( clk_10mhz         ),
 //  .HSEL               ( slv_hsel      [1] ),
 //  .HADDR              ( slv_haddr     [1] ),
 //  .HWDATA             ( slv_hwdata    [1] ),
 //  .HRDATA             ( slv_hrdata    [1] ),
 //  .HWRITE             ( slv_hwrite    [1] ),
 //  .HSIZE              ( slv_hsize     [1] ),
 //  .HBURST             ( slv_hburst    [1] ),
 //  .HPROT              ( slv_hprot     [1] ),
 //  .HTRANS             ( slv_htrans    [1] ),
 //  .HREADYOUT          ( slv_hreadyout [1] ),
 //  .HREADY             ( slv_hready    [1] ),
 //  .HRESP              ( slv_hresp     [1] ) );


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
    .mst_HREADY    ( mst_hreadyout ),
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


  // ahb3lite_interconnect_wrapper #(
  //   .g_haddr_size    ( c_haddr_width ),
  //   .g_hdata_size    ( 32            ),
  //   .g_masters_num   ( c_masters_num ),             // number of AHB Masters
  //   .g_slaves_num    ( c_slaves_num  ) )            // number of AHB Slaves
  // interconnect (
  //   // Common signals
  //   .hreset_n_i      ( rst_n         ),
  //   .hclk_i          ( clk_10mhz     ),
  //   // Master Ports
  //   .mst_priority_i  ( mst_priority  ),           // highest priority, even if it's the only master
  //   .mst_hsel_i      ( mst_hsel      ),
  //   .mst_haddr_i     ( mst_haddr     ),
  //   .mst_hwdata_i    ( mst_hwdata    ),
  //   .mst_hrdata_o    ( mst_hrdata    ),
  //   .mst_hwrite_i    ( mst_hwrite    ),
  //   .mst_hsize_i     ( mst_hsize     ),
  //   .mst_hburst_i    ( mst_hburst    ),
  //   .mst_hprot_i     ( mst_hprot     ),
  //   .mst_htrans_i    ( mst_htrans    ),
  //   .mst_hmastlock_i ( mst_hmastlock ),
  //   .mst_hreadyout_o ( mst_hreadyout ),
  //   .mst_hready_i    ( mst_hready    ),
  //   .mst_hresp_o     ( mst_hresp     ),
  //   // Slave Ports
  //   .slv_addr_mask_i ( slv_addr_mask ),           // up to addr 0x1FFF_FFFF
  //   .slv_addr_base_i ( slv_addr_base ),
  //   .slv_hsel_o      ( slv_hsel      ),
  //   .slv_haddr_o     ( slv_haddr     ),
  //   .slv_hwdata_o    ( slv_hwdata    ),
  //   .slv_hrdata_i    ( slv_hrdata    ),
  //   .slv_hwrite_o    ( slv_hwrite    ),
  //   .slv_hsize_o     ( slv_hsize     ),
  //   .slv_hburst_o    ( slv_hburst    ),
  //   .slv_hprot_o     ( slv_hprot     ),
  //   .slv_htrans_o    ( slv_htrans    ),
  //   .slv_hmastlock_o ( slv_hmastlock ),
  //   .slv_hreadyout_o ( slv_hreadyout ),           // HREADYOUT to slave-decoder; generates HREADY to all connected slaves
  //   .slv_hready_i    ( slv_hready    ),           // combinatorial HREADY from all connected slaves
  //   .slv_hresp_i     ( slv_hresp     ));


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
     .hready_i              ( 1'b1              ),      // mst_hready_0,               // ahb stall signal
     .hresp_i               ( 1'b0              ),      // mst_hresp_0,                // ahb error response
     // miscellaneous
     .nmi_i                 ( 1'b0              ),      // non-maskable interrupt input
     .irq_i                 ( {32{1'b0}}        ),      // interrupt request inputs
     .txev_o                (                   ),      // event output (sev executed)
     .rxev_i                ( 1'b0              ),      // event input
     .lockup_o              ( led2              ),      // core is locked-up
     .sysresetreq_o         (                   ),      // system reset request
     // power management
     .sleeping_o            ( led1              ) );    // core and nvic sleeping

   // assign mst_hready [0] = 1'b1; // Cortex M0 has no hreadyout

endmodule // cm0_softmc_top

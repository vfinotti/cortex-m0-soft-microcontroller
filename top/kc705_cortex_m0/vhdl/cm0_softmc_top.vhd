-------------------------------------------------------------------------------
-- Vitor Finotti
--
-- <project-url>
-------------------------------------------------------------------------------
--
-- unit name:     ARM Cortex M-0 implementation on FPGA
--
-- description:
--
--
--
-------------------------------------------------------------------------------
-- Copyright (c) 2018 Vitor Finotti
-------------------------------------------------------------------------------
-- MIT
-------------------------------------------------------------------------------
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
-------------------------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;

use work.ahb3lite_vhdl_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity cm0_softmc_top is
  port (
    led0        : out std_logic;        -- dcm
    led1        : out std_logic;        -- sleep
    led2        : out std_logic;        -- lock
    led3        : out std_logic;        -- detector
    led4        : out std_logic;        -- reset
    led5        : out std_logic;
    led6        : out std_logic;
    led7        : out std_logic;
    sys_clk_p_i : in  std_logic;
    sys_clk_n_i : in  std_logic);
end cm0_softmc_top;

architecture behavioral of cm0_softmc_top is

  constant c_masters_num : natural := 1;
  constant c_slaves_num  : natural := 2;

  signal rst_n      : std_logic;
  signal dummy      : std_logic_vector(2 downto 0);
  signal hrdata     : std_logic_vector(31 downto 0);
  signal hwdata     : std_logic_vector(31 downto 0);
  signal haddr      : std_logic_vector(c_haddr_width-1 downto 0);
  signal hburst     : std_logic_vector(2 downto 0);
  signal hprot      : std_logic_vector(3 downto 0);
  signal hsize      : std_logic_vector(2 downto 0);
  signal htrans     : std_logic_vector(1 downto 0);
  signal hwrite     : std_logic_vector(0 downto 0);
  signal clk_200mhz : std_logic;
  signal none       : std_logic_vector(1 downto 0);
  signal led_value  : std_logic;
  signal rst        : std_logic;
  signal clk_10mhz  : std_logic;

  -- Master 0 signals (cortex-m0)
  signal mst_priority_0  : std_logic_vector(2 downto 0) := "111";
  signal mst_hsel_0      : std_logic := '1';
  signal mst_haddr_0     : std_logic_vector(c_haddr_width-1 downto 0);
  signal mst_hwdata_0    : std_logic_vector(31 downto 0);
  signal mst_hrdata_0    : std_logic_vector(31 downto 0);
  signal mst_hwrite_0    : std_logic;
  signal mst_hsize_0     : std_logic_vector(2 downto 0);
  signal mst_hburst_0    : std_logic_vector(2 downto 0);
  signal mst_hprot_0     : std_logic_vector(3 downto 0);
  signal mst_htrans_0    : std_logic_vector(1 downto 0);
  signal mst_hmastlock_0 : std_logic;
  signal mst_hreadyout_0 : std_logic;
  signal mst_hready_0    : std_logic;
  signal mst_hresp_0     : std_logic;

  -- Slave 0 signals (ROM)
  signal slv_addr_mask_0 : std_logic_vector(31 downto 0) := x"E000_0000";
  signal slv_addr_base_0 : std_logic_vector(31 downto 0) := x"0000_0000";
  signal slv_hsel_0      : std_logic;
  signal slv_haddr_0     : std_logic_vector(c_haddr_width-1 downto 0);
  signal slv_hwdata_0    : std_logic_vector(31 downto 0);
  signal slv_hrdata_0    : std_logic_vector(31 downto 0);
  signal slv_hwrite_0    : std_logic;
  signal slv_hsize_0     : std_logic_vector(2 downto 0);
  signal slv_hburst_0    : std_logic_vector(2 downto 0);
  signal slv_hprot_0     : std_logic_vector(3 downto 0);
  signal slv_htrans_0    : std_logic_vector(1 downto 0);
  signal slv_hmastlock_0 : std_logic;
  signal slv_hreadyout_0 : std_logic;
  signal slv_hready_0    : std_logic;
  signal slv_hresp_0     : std_logic;

  -- Slave 1 signals (RAM)
  signal slv_addr_mask_1 : std_logic_vector(31 downto 0) := x"E000_0000";
  signal slv_addr_base_1 : std_logic_vector(31 downto 0) := x"2000_0000";
  signal slv_hsel_1      : std_logic;
  signal slv_haddr_1     : std_logic_vector(c_haddr_width-1 downto 0);
  signal slv_hwdata_1    : std_logic_vector(31 downto 0);
  signal slv_hrdata_1    : std_logic_vector(31 downto 0);
  signal slv_hwrite_1    : std_logic;
  signal slv_hsize_1     : std_logic_vector(2 downto 0);
  signal slv_hburst_1    : std_logic_vector(2 downto 0);
  signal slv_hprot_1     : std_logic_vector(3 downto 0);
  signal slv_htrans_1    : std_logic_vector(1 downto 0);
  signal slv_hmastlock_1 : std_logic;
  signal slv_hreadyout_1 : std_logic;
  signal slv_hready_1    : std_logic;
  signal slv_hresp_1     : std_logic;





  signal mst_priority  : t_mst_priority(c_masters_num-1 downto 0);
  signal mst_hsel      : t_mst_hsel(c_masters_num-1 downto 0);
  signal mst_haddr     : t_mst_haddr(c_masters_num-1 downto 0);
  signal mst_hwdata    : t_mst_hwdata(c_masters_num-1 downto 0);
  signal mst_hrdata    : t_mst_hrdata(c_masters_num-1 downto 0);
  signal mst_hwrite    : t_mst_hwrite(c_masters_num-1 downto 0);
  signal mst_hsize     : t_mst_hsize(c_masters_num-1 downto 0);
  signal mst_hburst    : t_mst_hburst(c_masters_num-1 downto 0);
  signal mst_hprot     : t_mst_hprot(c_masters_num-1 downto 0);
  signal mst_htrans    : t_mst_htrans(c_masters_num-1 downto 0);
  signal mst_hmastlock : t_mst_hmastlock(c_masters_num-1 downto 0);
  signal mst_hreadyout : t_mst_hreadyout(c_masters_num-1 downto 0);
  signal mst_hready    : t_mst_hready(c_masters_num-1 downto 0);
  signal mst_hresp     : t_mst_hresp(c_masters_num-1 downto 0);

  signal slv_addr_mask : t_slv_addr_mask(c_slaves_num-1 downto 0);
  signal slv_addr_base : t_slv_addr_base(c_slaves_num-1 downto 0);
  signal slv_hsel      : t_slv_hsel(c_slaves_num-1 downto 0);
  signal slv_haddr     : t_slv_haddr(c_slaves_num-1 downto 0);
  signal slv_hwdata    : t_slv_hwdata(c_slaves_num-1 downto 0);
  signal slv_hrdata    : t_slv_hrdata(c_slaves_num-1 downto 0);
  signal slv_hwrite    : t_slv_hwrite(c_slaves_num-1 downto 0);
  signal slv_hsize     : t_slv_hsize(c_slaves_num-1 downto 0);
  signal slv_hburst    : t_slv_hburst(c_slaves_num-1 downto 0);
  signal slv_hprot     : t_slv_hprot(c_slaves_num-1 downto 0);
  signal slv_htrans    : t_slv_htrans(c_slaves_num-1 downto 0);
  signal slv_hmastlock : t_slv_hmastlock(c_slaves_num-1 downto 0);
  signal slv_hreadyout : t_slv_hreadyout(c_slaves_num-1 downto 0);
  signal slv_hready    : t_slv_hready(c_slaves_num-1 downto 0);
  signal slv_hresp     : t_slv_hresp(c_slaves_num-1 downto 0);


  -- signal mst_bus_in  : t_ahb3lite_mst_bus_in(c_masters_num-1 downto 0);
  -- signal mst_bus_out : t_ahb3lite_mst_bus_out(c_masters_num-1 downto 0);
  -- signal slv_bus_in  : t_ahb3lite_slv_bus_in(c_slaves_num-1 downto 0);
  -- signal slv_bus_out : t_ahb3lite_slv_bus_out(c_slaves_num-1 downto 0);


  component detectorbus is
    port (
      clock    : in  std_logic;
      databus  : in  std_logic_vector (31 downto 0);
      detector : out std_logic);
  end component;

  component sys_pll is
    generic (
      g_clkin_period   : real;
      g_divclk_divide  : integer;
      g_clkbout_mult_f : integer;
      g_ref_jitter     : real;
      g_clk0_divide_f  : integer;
      g_clk1_divide    : integer;
      g_clk2_divide    : integer);
    port (
      rst_i    : in  std_logic := '0';
      clk_i    : in  std_logic := '0';
      clk0_o   : out std_logic;
      clk1_o   : out std_logic;
      clk2_o   : out std_logic;
      locked_o : out std_logic);
  end component sys_pll;



begin

  led3      <= led_value;
  led4      <= rst_n;
  led5      <= '1';
  led6      <= '0';
  led7      <= '1';
  rst       <= not rst_n;

  mst_priority(0)  <= "111";
  mst_hsel(0)      <= '1';
  slv_addr_mask(0) <= x"E000_0000";
  slv_addr_base(0) <= x"0000_0000";


  cpm_ibufgds_clk_gen : IBUFGDS
    generic map (
      DIFF_TERM    => false,            -- Differential Termination
      IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD   => "DIFF_SSTL15"
      )
    port map (
      O  => clk_200mhz,                 -- Clock buffer output
      I  => sys_clk_p_i,  -- Diff_p clock buffer input (connect directly to top-level port)
      IB => sys_clk_n_i  -- Diff_n clock buffer input (connect directly to top-level port)
      );


  inst_detector : entity work.detectorbus
    port map (
      clock    => clk_10mhz,
      databus  => mst_hrdata_0,
      detector => led_value);


  gc_single_reset_gen_1 : entity work.gc_single_reset_gen
    generic map (
      g_out_reg_depth => 5,             -- delay for 5 clk cycles
      g_rst_in_num    => 1)             -- just 1 input
    port map (
      clk_i             => clk_10mhz,
      rst_signals_n_a_i => "1",
      rst_n_o           => rst_n);


  sys_pll_1 : entity work.sys_pll
    generic map (
      g_clkin_period   => 5.000,        -- 200 MHz
      g_divclk_divide  => 1,
      g_clkbout_mult_f => 5,
      g_clk0_divide_f  => 100,          -- 10 MHz
      g_clk1_divide    => 100,          -- 10 MHz
      g_clk2_divide    => 100)          -- 10 MHz
    port map (
      rst_i    => '0',
      clk_i    => clk_200mhz,
      clk0_o   => clk_10mhz,
      clk1_o   => open,
      clk2_o   => open,
      locked_o => led0);


  rom : entity work.ahb3lite_sram1rw_wrapper
    generic map (
      g_mem_size          => 0,           -- Memory in Bytes
      g_mem_depth         => 512,         -- Memory depth
      g_haddr_size        => 32,
      g_hdata_size        => 32,
      g_technology        => "GENERIC",
      g_registered_output => "NO",
      g_init_file         => "/home/vfinotti/clones/cortex-m0-soft-microcontroller/modules/memory/vhdl/memory.mem")
    port map (
      hreset_n_i  => rst_n,
      hclk_i      => clk_10mhz,
      hsel_i      => slv_hsel(0),
      haddr_i     => slv_haddr(0),
      hwdata_i    => slv_hwdata(0),
      hrdata_o    => slv_hrdata(0),
      hwrite_i    => slv_hwrite(0),
      hsize_i     => slv_hsize(0),
      hburst_i    => slv_hburst(0),
      hprot_i     => slv_hprot(0),
      htrans_i    => slv_htrans(0),
      hreadyout_o => slv_hreadyout(0),
      hready_i    => slv_hready(0),
      hresp_o     => slv_hresp(0));

  -- rom : entity work.ahb3lite_sram1rw
  --   generic map (
  --     MEM_SIZE          => 0,           -- Memory in Bytes
  --     MEM_DEPTH         => 512,         -- Memory depth
  --     HADDR_SIZE        => 32,
  --     HDATA_SIZE        => 32,
  --     TECHNOLOGY        => "GENERIC",
  --     REGISTERED_OUTPUT => "NO",
  --     INIT_FILE         => "/home/vfinotti/clones/cortex-m0-soft-microcontroller/modules/memory/vhdl/memory.mem"
  --     )
  --   port map (
  --     HRESETn   => rst_n,
  --     HCLK      => clk_10mhz,
  --     --AHB Slave Interfaces (receive data from AHB Masters)
  --     --AHB Masters connect to these ports
  --     HSEL      => slv_hsel_0,
  --     HADDR     => slv_haddr_0,
  --     HWDATA    => slv_hwdata_0,
  --     HRDATA    => slv_hrdata_0,
  --     HWRITE    => slv_hwrite_0,
  --     HSIZE     => slv_hsize_0,
  --     HBURST    => slv_hburst_0,
  --     HPROT     => slv_hprot_0,
  --     HTRANS    => slv_htrans_0,
  --     HREADYOUT => slv_hreadyout_0,
  --     HREADY    => slv_hready_0,
  --     HRESP     => slv_hresp_0);

  slv_hready(0) <= rst_n;



  -- ram : entity work.ahb3lite_sram1rw
  --   generic map (
  --     MEM_SIZE          => 0,           -- Memory in Bytes
  --     MEM_DEPTH         => 512,         -- Memory depth
  --     HADDR_SIZE        => 9,
  --     HDATA_SIZE        => 32,
  --     TECHNOLOGY        => "GENERIC",
  --     REGISTERED_OUTPUT => "NO"
  --     -- INIT_FILE         => ""
  --     )
  --   port map (
  --     HRESETn   => rst_n,
  --     HCLK      => clk_10mhz,
  --     --AHB Slave Interfaces (receive data from AHB Masters)
  --     --AHB Masters connect to these ports
  --     HSEL      => slv_hsel_1,
  --     HADDR     => slv_haddr_1(8 downto 0),
  --     HWDATA    => slv_hwdata_1,
  --     HRDATA    => slv_hrdata_1,
  --     HWRITE    => slv_hwrite_1,
  --     HSIZE     => slv_hsize_1,
  --     HBURST    => slv_hburst_1,
  --     HPROT     => slv_hprot_1,
  --     HTRANS    => slv_htrans_1,
  --     HREADYOUT => slv_hreadyout_1,
  --     HREADY    => slv_hready_1,
  --     HRESP     => slv_hresp_1);

  ram : entity work.ahb3lite_sram1rw_wrapper
    generic map (
      g_mem_size          => 0,           -- Memory in Bytes
      g_mem_depth         => 512,         -- Memory depth
      g_haddr_size        => 32,
      g_hdata_size        => 32,
      g_technology        => "GENERIC",
      g_registered_output => "NO")
    port map (
      hreset_n_i  => rst_n,
      hclk_i      => clk_10mhz,
      hsel_i      => slv_hsel_1,
      haddr_i     => slv_haddr_1,
      hwdata_i    => slv_hwdata_1,
      hrdata_o    => slv_hrdata_1,
      hwrite_i    => slv_hwrite_1,
      hsize_i     => slv_hsize_1,
      hburst_i    => slv_hburst_1,
      hprot_i     => slv_hprot_1,
      htrans_i    => slv_htrans_1,
      hreadyout_o => slv_hreadyout_1,
      hready_i    => slv_hready_1,
      hresp_o     => slv_hresp_1);


  -- interconnect : entity work.ahb3lite_interconnect_wrapper
  --   generic map (
  --     g_haddr_size  => c_haddr_width,
  --     g_hdata_size  => 32,
  --     g_masters_num => 1,               -- number of AHB Masters
  --     g_slaves_num  => 1                -- number of AHB Slaves
  --     )
  --   port map (
  --     -- Common signals
  --     hreset_n_i      => rst_n,
  --     hclk_i          => clk_10mhz,
  --     -- Master Ports; AHB masters connect to these
  --     -- thus these are actually AHB Slave Interfaces
  --     mst_priority_i  => mst_priority_0,  -- highest priority, even if it's the only master
  --     mst_hsel_i      => mst_hsel_0,
  --     mst_haddr_i     => mst_haddr_0,
  --     mst_hwdata_i    => mst_hwdata_0,
  --     mst_hrdata_o    => mst_hrdata_0,
  --     mst_hwrite_i    => mst_hwrite_0,
  --     mst_hsize_i     => mst_hsize_0,
  --     mst_hburst_i    => mst_hburst_0,
  --     mst_hprot_i     => mst_hprot_0,
  --     mst_htrans_i    => mst_htrans_0,
  --     mst_hmastlock_i => mst_hmastlock_0,
  --     mst_hreadyout_o => mst_hreadyout_0,
  --     mst_hready_i    => mst_hready_0,
  --     mst_hresp_o     => mst_hresp_0,
  --     -- Slave Ports; AHB Slaves connect to these
  --     --  thus these are actually AHB Master Interfaces
  --     slv_addr_mask_i => slv_addr_mask_0,  -- up to addr 0x1FFF_FFFF
  --     slv_addr_base_i => slv_addr_base_0,
  --     slv_hsel_o      => slv_hsel_0,
  --     slv_haddr_o     => slv_haddr_0,
  --     slv_hwdata_o    => slv_hwdata_0,
  --     slv_hrdata_i    => slv_hrdata_0,
  --     slv_hwrite_o    => slv_hwrite_0,
  --     slv_hsize_o     => slv_hsize_0,
  --     slv_hburst_o    => slv_hburst_0,
  --     slv_hprot_o     => slv_hprot_0,
  --     slv_htrans_o    => slv_htrans_0,
  --     slv_hmastlock_o => slv_hmastlock_0,
  --     slv_hreadyout_o => slv_hreadyout_0,  -- HREADYOUT to slave-decoder; generates HREADY to all connected slaves
  --     slv_hready_i    => slv_hready_0,  -- combinatorial HREADY from all connected slaves
  --     slv_hresp_i      =>  slv_hresp_0);


  interconnect : entity work.ahb3lite_interconnect_wrapper
    generic map (
      g_haddr_size  => c_haddr_width,
      g_hdata_size  => 32,
      g_masters_num => c_masters_num,              -- number of AHB Masters
      g_slaves_num  => c_slaves_num                -- number of AHB Slaves
      )
    port map (
      -- Common signals
      hreset_n_i      => rst_n,
      hclk_i          => clk_10mhz,
      -- Master Ports; AHB masters connect to these
      -- thus these are actually AHB Slave Interfaces
      mst_priority_i  => mst_priority,  -- highest priority, even if it's the only master
      mst_hsel_i      => mst_hsel,
      mst_haddr_i     => mst_haddr,
      mst_hwdata_i    => mst_hwdata,
      mst_hrdata_o    => mst_hrdata,
      mst_hwrite_i    => mst_hwrite,
      mst_hsize_i     => mst_hsize,
      mst_hburst_i    => mst_hburst,
      mst_hprot_i     => mst_hprot,
      mst_htrans_i    => mst_htrans,
      mst_hmastlock_i => mst_hmastlock,
      mst_hreadyout_o => mst_hreadyout,
      mst_hready_i    => mst_hready,
      mst_hresp_o     => mst_hresp,
      -- Slave Ports; AHB Slaves connect to these
      --  thus these are actually AHB Master Interfaces
      slv_addr_mask_i => slv_addr_mask,  -- up to addr 0x1FFF_FFFF
      slv_addr_base_i => slv_addr_base,
      slv_hsel_o      => slv_hsel,
      slv_haddr_o     => slv_haddr,
      slv_hwdata_o    => slv_hwdata,
      slv_hrdata_i    => slv_hrdata,
      slv_hwrite_o    => slv_hwrite,
      slv_hsize_o     => slv_hsize,
      slv_hburst_o    => slv_hburst,
      slv_hprot_o     => slv_hprot,
      slv_htrans_o    => slv_htrans,
      slv_hmastlock_o => slv_hmastlock,
      slv_hreadyout_o => slv_hreadyout,  -- HREADYOUT to slave-decoder; generates HREADY to all connected slaves
      slv_hready_i    => slv_hready,  -- combinatorial HREADY from all connected slaves
      slv_hresp_i     => slv_hresp);

  -- ahb3lite_interconnect_wrapper_1: entity work.ahb3lite_interconnect_wrapper
  --   generic map (
  --     g_haddr_size  => g_haddr_size,
  --     g_hdata_size  => g_hdata_size,
  --     g_masters_num => g_masters_num,
  --     g_slaves_num  => g_slaves_num)
  --   port map (
  --     hreset_n_i => hreset_n_i,
  --     hclk_i     => hclk_i,
  --     mst_bus_i  => mst_bus_i,
  --     mst_bus_o  => mst_bus_o,
  --     slv_bus_i  => slv_bus_i,
  --     slv_bus_o  => slv_bus_o);


  cortex_m0_1 : entity work.cortex_m0_wrapper
    port map (
      -- clock and resets ------------------
      hclk_i                => clk_10mhz,            -- clock
      hreset_n_i            => rst_n,                -- asynchronous reset
      -- ahb-lite master port --------------
      haddr_o               => mst_haddr(0),                -- ahb transaction address
      hburst_o              => mst_hburst(0)(2 downto 0),   -- ahb burst: tied to single
      hmastlock_o           => dummy(0),                   -- ahb locked transfer (always zero)
      hprot_o               => mst_hprot(0)(3 downto 0),    -- ahb protection: priv; data or inst
      hsize_o               => mst_hsize(0)(2 downto 0),    -- ahb size: byte, half-word or word
      htrans_o              => mst_htrans(0)(1 downto 0),   -- ahb transfer: non-sequential only
      hwdata_o              => mst_hwdata(0)(31 downto 0),  -- ahb write-data
      hwrite_o              => mst_hwrite(0),               -- ahb write control
      hrdata_i              => mst_hrdata(0)(31 downto 0),  -- ahb read-data
      hready_i              => '1', -- mst_hready_0,               -- ahb stall signal
      hresp_i               => '0', -- mst_hresp_0,                -- ahb error response
      -- miscellaneous ---------------------
      nmi_i                 => '0',                  -- non-maskable interrupt input
      irq_i                 => (others => '0'),      -- interrupt request inputs
      txev_o                => dummy(1),             -- event output (sev executed)
      rxev_i                => '0',                  -- event input
      lockup_o              => led2,                 -- core is locked-up
      sysresetreq_o         => dummy(2),             -- system reset request
      -- power management ------------------
      sleeping_o            => led1);                -- core and nvic sleeping


end behavioral;

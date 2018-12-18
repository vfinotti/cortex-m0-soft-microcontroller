-- Copyright (c) 2011, Pedro Ignacio Martos <pmartos@fi.uba.ar / pimartos@gmail.com> & Fabricio Baglivo <baglivofabricio@gmail.com>
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without modification, are permitted provided that
-- the following conditions are met:
--
--     * Redistributions of source code must retain the above copyright notice, this list of conditions and the
--       following disclaimer.
--     * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
--       the following disclaimer in the documentation and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
-- INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
-- SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
-- WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
-- USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

library ieee;
use ieee.std_logic_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use ieee.numeric_std.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
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

  component rom_memory_blinking_led
    port (
      clka      : in  std_logic;
      rsta      : in  std_logic;
      ena       : in  std_logic;
      wea       : in  std_logic_vector(0 downto 0);
      addra     : in  std_logic_vector(8 downto 0);
      dina      : in  std_logic_vector(31 downto 0);
      douta     : out std_logic_vector(31 downto 0);
      rsta_busy : out std_logic);
  end component;

  component detectorbus is
    port (
      clock    : in  std_logic;
      databus  : in  std_logic_vector (31 downto 0);
      detector : out std_logic);
  end component;


  -- component systemclock
  --   port(
  --     clkin_in        : in  std_logic;
  --     clkfx_out       : out std_logic;
  --     clkin_ibufg_out : out std_logic;
  --     clk0_out        : out std_logic;
  --     locked_out      : out std_logic);
  -- end component;

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



  signal rst_n      : std_logic;
  signal dummy      : std_logic_vector(2 downto 0);
  signal hrdata     : std_logic_vector(31 downto 0);
  signal hwdata     : std_logic_vector(31 downto 0);
  signal haddr      : std_logic_vector(31 downto 0);
  signal hburst     : std_logic_vector(2 downto 0);
  signal hprot      : std_logic_vector(3 downto 0);
  signal hsize      : std_logic_vector(2 downto 0);
  signal htrans     : std_logic_vector(1 downto 0);
  signal hwrite     : std_logic_vector(0 downto 0);
  signal clk_200mhz : std_logic;
  signal none       : std_logic_vector(1 downto 0);
  signal led_value  : std_logic;
  signal reset_rom  : std_logic;
  signal clk_10mhz  : std_logic;


begin

  led3      <= led_value;
  led4      <= rst_n;
  led5      <= '1';
  led6      <= '0';
  led7      <= '1';
  reset_rom <= not rst_n;

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

  inst_detector : detectorbus
    port map (
      clock    => clk_10mhz,
      databus  => hrdata,
      detector => led_value);

  -- inst_syncreset : syncreset
  --   port map(
  --     clock      => clk_10mhz,
  --     resetpulse => syncresetpulse);

  gc_single_reset_gen_1 : entity work.gc_single_reset_gen
    generic map (
      g_out_reg_depth => 5,             -- delay for 5 clk cycles
      g_rst_in_num    => 1)             -- just 1 input
    port map (
      clk_i             => clk_10mhz,
      rst_signals_n_a_i => "1",
      rst_n_o           => rst_n);

  -- inst_systemclock : systemclock
  --   port map(
  --     clkin_in        => clock_in,
  --     clkfx_out       => clock,
  --     clkin_ibufg_out => none(0),
  --     clk0_out        => none(1),
  --     locked_out      => led0);

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

  -- inst_memory : rom_memory_blinking_led
  --   port map (
  --     clka      => clk_10mhz,
  --     rsta      => reset_rom,
  --     ena       => htrans(1),
  --     wea       => hwrite(0 downto 0),
  --     addra     => haddr(10 downto 2),
  --     dina      => hwdata(31 downto 0),
  --     douta     => hrdata(31 downto 0),
  --     rsta_busy => open);

  generic_spram_1: entity work.generic_spram
  rom: entity work.generic_spram
    generic map (
      g_data_width               => 32,
      g_size                     => 512,
      -- Path should be relative to memory_loader_pkc.vhd directory
      g_init_file                => "./../../../../modules/memory/vhdl/memory.mem")
--      g_init_file                => "./../../../../modules/memory/vhdl/BlinkingLed.mem")
    port map (
      rst_n_i => rst_n,
      clk_i   => clk_10mhz,
      bwe_i   => (others => '0'),
      we_i    => '0',
      -- a_i     => sramaddr(8 downto 0),
      -- d_i     => sramwdata(31 downto 0),
      -- q_o     => sramrdata(31 downto 0));
      a_i     => haddr(10 downto 2),
      d_i     => hwdata(31 downto 0),
      q_o     => hrdata(31 downto 0));

  cortex_m0_1 : entity work.cortex_m0_wrapper
    port map (
      -- clock and resets ------------------
      hclk_i                => clk_10mhz,            -- clock
      hreset_n_i            => rst_n,                -- asynchronous reset
      -- ahb-lite master port --------------
      haddr_o(10 downto 0)  => haddr(10 downto 0),   -- ahb transaction address
      haddr_o(31 downto 11) => haddr(31 downto 11),  -- ahb transaction address
      hburst_o              => hburst(2 downto 0),   -- ahb burst: tied to single
      hmastlock_o           => dummy(0),             -- ahb locked transfer (always zero)
      hprot_o               => hprot(3 downto 0),    -- ahb protection: priv; data or inst
      hsize_o               => hsize(2 downto 0),    -- ahb size: byte, half-word or word
      htrans_o              => htrans(1 downto 0),   -- ahb transfer: non-sequential only
      hwdata_o              => hwdata(31 downto 0),  -- ahb write-data
      hwrite_o              => hwrite(0),            -- ahb write control
      hrdata_i              => hrdata(31 downto 0),  -- ahb read-data
      hready_i              => '1', --hready,               -- ahb stall signal
      hresp_i               => '0', --hresp,                -- ahb error response
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

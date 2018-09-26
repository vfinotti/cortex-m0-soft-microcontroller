--  MMCM_BASE  : In order to incorporate this function into the design,
--    VHDL     : the following instance declaration needs to be placed
--  instance   : in the body of the design code.  The instance name
-- declaration : (MMCM_BASE_inst) and/or the port declarations after the
--    code     : "=>" declaration maybe changed to properly reference and
--             : connect this function to the design.  All inputs and outputs
--             : must be connected.

--   Library   : In addition to adding the instance declaration, a use
-- declaration : statement for the UNISIM.vcomponents library needs to be
--     for     : added before the entity declaration.  This library
--   Xilinx    : contains the component declarations for all Xilinx
-- primitives  : primitives and points to the models that will be used
--             : for simulation.

--  Copy the following two statements and paste them before the
--  Entity declaration,  unless they already exist.

library UNISIM;
use UNISIM.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;

entity sys_pll is
generic(
  -- 200 MHz input clock
  g_clkin_period                            : real := 5.000;
  g_divclk_divide                           : integer := 1;
  g_clkbout_mult_f                          : integer := 5;

  -- Reference jitter
  g_ref_jitter                              : real := 0.010;

  -- 100 MHz output clock
  g_clk0_divide_f                           : integer := 10;
  -- 200 MHz output clock
  g_clk1_divide                             : integer := 5;
  g_clk2_divide                             : integer := 6
);
port(
  rst_i                                     : in std_logic := '0';
  clk_i                                     : in std_logic := '0';
  clk0_o                                    : out std_logic;
  clk1_o                                    : out std_logic;
  clk2_o                                    : out std_logic;
  locked_o                                  : out std_logic
);
end sys_pll;

architecture syn of sys_pll is

  signal s_mmcm_fbin                        : std_logic;
  signal s_mmcm_fbout                       : std_logic;

  signal s_clk0                             : std_logic;
  signal s_clk1                             : std_logic;
  signal s_clk2                             : std_logic;
begin

  -- Clock PLL
  cmp_sys_pll : PLLE2_ADV
   generic map (
      BANDWIDTH                             => "OPTIMIZED",  -- OPTIMIZED, HIGH, LOW
      CLKFBOUT_MULT                         => g_clkbout_mult_f,        -- Multiply value for all CLKOUT, (2-64)
      CLKFBOUT_PHASE                        => 0.0,     -- Phase offset in degrees of CLKFB, (-360.000-360.000).
      -- CLKIN_PERIOD: Input clock period in nS to ps resolution (i.e. 33.333 is 30 MHz).
      CLKIN1_PERIOD                         => g_clkin_period,
      CLKIN2_PERIOD                         => g_clkin_period,
      -- CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for CLKOUT (1-128)
      CLKOUT0_DIVIDE                        => g_clk0_divide_f,
      CLKOUT1_DIVIDE                        => g_clk1_divide,
      CLKOUT2_DIVIDE                        => g_clk2_divide,
      CLKOUT3_DIVIDE                        => 1,
      CLKOUT4_DIVIDE                        => 1,
      CLKOUT5_DIVIDE                        => 1,
      -- CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for CLKOUT outputs (0.001-0.999).
      CLKOUT0_DUTY_CYCLE                    => 0.5,
      CLKOUT1_DUTY_CYCLE                    => 0.5,
      CLKOUT2_DUTY_CYCLE                    => 0.5,
      CLKOUT3_DUTY_CYCLE                    => 0.5,
      CLKOUT4_DUTY_CYCLE                    => 0.5,
      CLKOUT5_DUTY_CYCLE                    => 0.5,
      -- CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for CLKOUT outputs (-360.000-360.000).
      CLKOUT0_PHASE                         => 0.0,
      CLKOUT1_PHASE                         => 0.0,
      CLKOUT2_PHASE                         => 0.0,
      CLKOUT3_PHASE                         => 0.0,
      CLKOUT4_PHASE                         => 0.0,
      CLKOUT5_PHASE                         => 0.0,
      COMPENSATION                          => "ZHOLD",   -- ZHOLD, BUF_IN, EXTERNAL, INTERNAL
      DIVCLK_DIVIDE                         => g_divclk_divide,        -- Master division value (1-56)
      -- REF_JITTER: Reference input jitter in UI (0.000-0.999).
      REF_JITTER1                           => g_ref_jitter,
      REF_JITTER2                           => g_ref_jitter,
      STARTUP_WAIT                          => "FALSE"    -- Delay DONE until PLL Locks, ("TRUE"/"FALSE")
   )
   port map (
      -- Clock Outputs: 1-bit (each) output: User configurable clock outputs
      CLKOUT0                               => s_clk0,            -- 1-bit output: CLKOUT0
      CLKOUT1                               => s_clk1,            -- 1-bit output: CLKOUT1
      CLKOUT2                               => s_clk2,            -- 1-bit output: CLKOUT2
      CLKOUT3                               => open,              -- 1-bit output: CLKOUT3
      CLKOUT4                               => open,              -- 1-bit output: CLKOUT4
      CLKOUT5                               => open,              -- 1-bit output: CLKOUT5
      -- DRP Ports: 16-bit (each) output: Dynamic reconfiguration ports
      DO                                    => open,              -- 16-bit output: DRP data
      DRDY                                  => open,              -- 1-bit output: DRP ready
      -- Feedback Clocks: 1-bit (each) output: Clock feedback ports
      CLKFBOUT                              => s_mmcm_fbout,      -- 1-bit output: Feedback clock
      LOCKED                                => locked_o,          -- 1-bit output: LOCK
      -- Clock Inputs: 1-bit (each) input: Clock inputs
      CLKIN1                                => clk_i,             -- 1-bit input: Primary clock
      CLKIN2                                => '0',               -- 1-bit input: Secondary clock
      -- Control Ports: 1-bit (each) input: PLL control ports
      CLKINSEL                              => '1',               -- 1-bit input: Clock select, High=CLKIN1 Low=CLKIN2
      PWRDWN                                => '0',               -- 1-bit input: Power-down
      RST                                   => rst_i,             -- 1-bit input: Reset
      -- DRP Ports: 7-bit (each) input: Dynamic reconfiguration ports
      DADDR                                 => (others => '0'),   -- 7-bit input: DRP address
      DCLK                                  => '0',               -- 1-bit input: DRP clock
      DEN                                   => '0',               -- 1-bit input: DRP enable
      DI                                    => (others => '0'),   -- 16-bit input: DRP data
      DWE                                   => '0',               -- 1-bit input: DRP write enable
      -- Feedback Clocks: 1-bit (each) input: Clock feedback ports
      CLKFBIN                               => s_mmcm_fbin        -- 1-bit input: Feedback clock
   );

    -- Global clock buffers for "cmp_mmcm" instance
    cmp_clkf_bufg : BUFG
    port map(
        O                                   => s_mmcm_fbin,
        I                                   => s_mmcm_fbout
    );

    cmp_clkout0_buf : BUFG
    port map(
        O                                   => clk0_o,
        I                                   => s_clk0
    );

    cmp_clkout1_buf : BUFG
    port map(
        O                                   => clk1_o,
        I                                   => s_clk1
    );

    cmp_clkout2_buf : BUFG
    port map(
        O                                   => clk2_o,
        I                                   => s_clk2
    );

end syn;

-------------------------------------------------------------------------------
-- Vitor Finotti
--
-- https://github.com/vfinotti/cortex-m0-soft-microcontroller
-------------------------------------------------------------------------------
--
-- unit name:     Pattern Detector
--
-- description:
--
--   Detects if a specific pattern is seen on the data input. If so,
--   permanently asserts an output, only resetting it if the block is reset.
--
-------------------------------------------------------------------------------
-- Copyright (c) 2018 Vitor Finotti
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pattern_detector is

  generic (
    g_pattern : std_logic_vector(31 downto 0));  -- pattern to be detected
  port (
    clk_i      : in  std_logic;
    rst_i      : in  std_logic;
    data_i     : in  std_logic_vector(31 downto 0);
    detected_o : out std_logic);

end entity pattern_detector;

architecture rtl of pattern_detector is

begin  -- architecture rtl

  -- purpose: asserting port detected_o as '1' if pattern is detected
  -- type   : sequential
  -- inputs : clk_i, rst_i, data_i
  -- outputs: detected_o
  detection : process (clk_i) is
  begin  -- process detection
    if rising_edge(clk_i) then          -- rising clock edge
      if rst_i = '1' then               -- synchronous reset (active high)
        detected_o <= '0';
      else
        if data_i = g_pattern then
          detected_o <= '1';
        end if;
      end if;
    end if;
  end process detection;


end architecture rtl;

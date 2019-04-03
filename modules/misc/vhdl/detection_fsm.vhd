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
--   permanently asserts an output, only resetting it if the block is reset. As
--   a mesure to avoid toggling when not intended (this happpens because the
--   pattern appears more than once due to the pipelined nature of the
--   microcontroller), the next toggle must wait at least 10 clock cycles after
--   the previous.
--
-------------------------------------------------------------------------------
-- Copyright (c) 2018 Vitor Finotti
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity detection_fsm is

  generic (
    g_min_cycles_to_toggle : integer := 100);
  port (
    clk_i      : in  std_logic;
    rst_i      : in  std_logic;
    data_i     : in  std_logic_vector(31 downto 0);
    detected_o : out std_logic);

end entity detection_fsm;

architecture rtl of detection_fsm is

  type state_t is (state_on, state_off);

  signal present_state : state_t := state_off;

begin  -- architecture rtl

  -- purpose: asserting port detected_o as '1' if pattern is detected
  -- type   : sequential
  -- inputs : clk_i, rst_i, data_i
  -- outputs: detected_o

  detection : process (clk_i)
    variable cycles_after_toggle : integer range 0 to g_min_cycles_to_toggle;
  begin
    if rising_edge(clk_i) then          -- rising clock edge
      if rst_i = '1' then               -- synchronous reset (active high)
        present_state <= state_off;
        cycles_after_toggle := 0;
      else
        if cycles_after_toggle < g_min_cycles_to_toggle then
          cycles_after_toggle := cycles_after_toggle + 1;
        end if;

        case present_state is

          when state_off =>
            if data_i = x"f0f0f0f0" and cycles_after_toggle = g_min_cycles_to_toggle then
              present_state <= state_on;
              cycles_after_toggle := 0;
              detected_o    <= '1';
            else
              present_state <= state_off;
              detected_o    <= '0';
            end if;

          when state_on =>
            if data_i = x"f0f0f0f0" and cycles_after_toggle = g_min_cycles_to_toggle then
              present_state <= state_off;
              cycles_after_toggle := 0;
              detected_o    <= '0';
            else
              present_state <= state_on;
              detected_o    <= '1';
            end if;

          when others =>
            detected_o    <= '0';
            cycles_after_toggle := 0;
            present_state <= state_off;
        end case;
      end if;
    end if;
  end process detection;


end architecture rtl;

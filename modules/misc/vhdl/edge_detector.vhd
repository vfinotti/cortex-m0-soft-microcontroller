-------------------------------------------------------------------------------
-- Vitor Finotti
--
-- <project-url>
-------------------------------------------------------------------------------
--
-- unit name:     Rising or falling edge detector
--
-- description:
--
--
--
-------------------------------------------------------------------------------
-- Copyright (c) 2019 Vitor Finotti
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
use ieee.numeric_std.all;

entity edge_detector is

  generic (
    g_edge_type : string := "rising");  -- rising or falling

  port (
    clk_i           : in  std_logic;
    rst_i           : in  std_logic;
    signal_i        : in  std_logic;
    edge_detected_o : out std_logic);

end entity edge_detector;

architecture rtl of edge_detector is

  signal detection_stages : std_logic_vector(1 downto 0) := "00";
  signal edge_pattern     : std_logic_vector(1 downto 0);


begin  -- architecture rtl

  -- setting edge pattern to rising "01" or falling "10"
  edge_pattern <=      "01" when g_edge_type = "rising"
                  else "10" when g_edge_type = "falling"
                  else "00";

  pulse_detection : process (clk_i, rst_i) is
  begin
    if rst_i = '1' then
      detection_stages <= "00";
      edge_detected_o  <= '0';
    elsif rising_edge(clk_i) then
      if detection_stages = edge_pattern then
        edge_detected_o <= '1';
      else
        edge_detected_o <= '0';
      end if;
      detection_stages(0) <= signal_i;
      detection_stages(1) <= detection_stages(0);
    end if;
  end process pulse_detection;

end architecture rtl;

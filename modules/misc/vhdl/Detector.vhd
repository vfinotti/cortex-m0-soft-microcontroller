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

entity detectorbus is
  port (clock    : in  std_logic;
        databus  : in  std_logic_vector (31 downto 0);
        detector : out std_logic);
end detectorbus;

architecture behavioral of detectorbus is

  signal trigger  : std_logic;
  signal outputff : std_logic;
  signal inputff  : std_logic;
  signal rst_ff   : std_logic;

begin

  process (clock, databus)
  begin
    if (falling_edge(clock)) then
      if (databus(31 downto 0) = "10101010101010100101010101010101") then
        trigger <= '1';
        rst_ff  <= '0';
      else
        trigger <= '0';
      end if;
      if (databus(31 downto 0) = "11110000111100001111000011110000") then
        rst_ff  <= '1';
        trigger <= '0';
      end if;
    end if;
  end process;

  instff : fdce
    generic map (
      init => '0')      -- Initial value of register ('0' or '1')
    port map (
      q   => outputff,                  -- Data output
      c   => clock,                     -- Clock input
      ce  => '1',                       -- Clock enable input
      clr => rst_ff,                    -- Asynchronous clear input
      d   => inputff);                  -- Data input

  inputff  <= trigger or outputff;
  detector <= outputff;

end behavioral;

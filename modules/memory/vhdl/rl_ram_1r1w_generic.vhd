-------------------------------------------------------------------------------
-- Vitor Finotti
--
-- <project-url>
-------------------------------------------------------------------------------
--
-- unit name:     RAM memory with file initialization
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
use std.textio.all;

entity rl_ram_1r1w_generic is

  generic (
    ABITS     : natural := 10;
    DBITS     : natural := 32;
    INIT_FILE : string  := "");
  port (
    clk_i   : in  std_logic;
    rst_ni  : in  std_logic;
    waddr_i : in  std_logic_vector(ABITS-1 downto 0);
    din_i   : in  std_logic_vector(DBITS-1 downto 0);
    we_i    : in  std_logic;
    be_i    : in  std_logic_vector((DBITS+7)/8-1 downto 0);
    raddr_i : in  std_logic_vector(DBITS-1 downto 0);
    dout_o  : out std_logic_vector(DBITS-1 downto 0));

end entity rl_ram_1r1w_generic;

architecture rtl of rl_ram_1r1w_generic is

  type RamType is array (0 to (2**ABITS-1)) of bit_vector(DBITS-1 downto 0);

  -- Function that loads RAM values from file
  impure function InitRamFromFile (RamFileName : in string) return RamType is
    file RamFile         : text is in RamFileName;
    variable RamFileLine : line;
    variable RAM         : RamType;
  begin
    for I in RamType'range loop
      readline(RamFile, RamFileLine);
      read(RamFileLine, RAM(I));
    end loop;
    return RAM;
  end function;

  -- Function to evaluate if there is a init file mentioned and use
  -- InitRamFromFile if so
  impure function InitRam (RamFileName : in string) return RamType is
    variable RAM         : RamType;
  begin
    if RamFileName /= "" then
      RAM := InitRamFromFile(RamFileName);
    else
      RAM := (others => (others => '0'));
    end if;
    return RAM;
  end function;

  signal RAM       : RamType := InitRam(INIT_FILE);


begin  -- architecture rtl

  -- purpose: Write and read data to RAM
  -- type   : sequential
  -- inputs : clk_i, rst_ni
  -- outputs:
  ram_process : process (clk_i) is
  begin  -- process ram_process
    if rising_edge(clk_i) then
      if we_i = '1' then
        RAM(to_integer(unsigned(waddr_i))) <= to_bitvector(din_i);
      end if;
    end if;
  end process ram_process;

  dout_o <= to_stdlogicvector(RAM(to_integer(unsigned(waddr_i))));


end architecture rtl;

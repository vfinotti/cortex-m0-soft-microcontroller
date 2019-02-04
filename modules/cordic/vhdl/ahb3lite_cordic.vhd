-------------------------------------------------------------------------------
-- Vitor Finotti
--
-- <project-url>
-------------------------------------------------------------------------------
--
-- unit name:     AHB3-Lite Cordic wrapper
--
-- description:
--
--   Implement a ahb3-lite compatible wrapper for the "vhdl-extra" library
--   cordic module. Implementation based on the example on
--   https://www.southampton.ac.uk/~bim/notes/cad/reference/ARMSoC/P3/AMBA-AHB-Lite.pdf
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

entity ahb3lite_cordic is

  generic (
    g_iterations         : positive   := 32;   -- Number of iterarions for CORDIC algorithm
    g_reset_active_level : std_ulogic := '1';  -- Asynch. reset control level
    g_haddr_size         : positive   := 32;   -- Width of operands
    g_hdata_size         : positive   := 32);

  port (
    hclk_i      : in  std_logic;
    hreset_n_i  : in  std_logic;
    hsel_i      : in  std_logic;
    haddr_i     : in  std_logic_vector(g_haddr_size-1 downto 0);
    hwdata_i    : in  std_logic_vector(g_hdata_size-1 downto 0);
    hrdata_o    : out std_logic_vector(g_hdata_size-1 downto 0);
    hwrite_i    : in  std_logic;
    hsize_i     : in  std_logic_vector(2 downto 0);
    hburst_i    : in  std_logic_vector(2 downto 0);
    hprot_i     : in  std_logic_vector(3 downto 0);
    htrans_i    : in  std_logic_vector(1 downto 0);
    hreadyout_o : out std_logic;
    hready_i    : in  std_logic;
    hresp_o     : out std_logic);

  -- port (
  --   clk_i          : in  std_ulogic;
  --   rst_i          : in  std_ulogic;
  --   data_valid_i   : in  std_ulogic;
  --   busy_o         : out std_ulogic;
  --   result_valid_o : out std_ulogic;    -- rotation or vector mode selection
  --   mode_i         : in  cordic_mode;
  --   x_i            : in  signed(g_size-1 downto 0);
  --   y_i            : in  signed(g_size-1 downto 0);
  --   z_i            : in  signed(g_size-1 downto 0);
  --   x_result_o     : out signed(g_size-1 downto 0);
  --   y_result_o     : out signed(g_size-1 downto 0);
  --   z_result_o     : out signed(g_size-1 downto 0));

end entity ahb3lite_cordic;

architecture rtl of ahb3lite_cordic is

  signal rst                 : std_ulogic;

  -- Address phase sampling registers
  signal r_hsel   : std_ulogic;
  signal r_haddr  : std_logic_vector (g_haddr_size-1 downto 0);
  signal r_htrans : std_ulogic_vector(1 downto 0);
  signal r_hwrite : std_ulogic;
  signal r_hsize  : std_ulogic_vector(2 downto 0);

  -- Data and control registers
  signal x, y, z                      : signed(g_hdata_size-1 downto 0);  -- 1 sign bit + 1 integer bit + g_hdata_size-2 fraction bits
  signal x_result, y_result, z_result : signed(g_hdata_size-1 downto 0);
  signal control_start                : std_logic_vector(g_hdata_size-1 downto 0);
  signal control_done                 : std_logic_vector(g_hdata_size-1 downto 0);
  -- type t_control_regs is array (7 downto 0) of std_logic_vector(g_hdata_size-1 downto 0);
  -- addr 0 : x input
  -- addr 1 : y input
  -- addr 2 : z input
  -- addr 3 : control register "start"
  -- addr 4 : x result
  -- addr 5 : y result
  -- addr 6 : z result
  -- addr 7 : control register "done"
  -- signal control_regs : t_control_regs;

  signal result_valid : std_ulogic;
  signal budy         : std_ulogic;



begin  -- architecture rtl

  rst <= not(hreset_n_i);

  -- Address phase sampling
  address_phase : process (hclk_i, hreset_n_i) is
  begin
    if hreset_n_i = '0' then
      r_hsel   <= '0';
      r_haddr  <= (others => '0');
      r_htrans <= (others => '0');
      r_hwrite <= '0';
      r_hsize  <= (others => '0');
    elsif rising_edge(hclk_i) then
      if (hready_i) then
        r_hsel   <= hsel;
        r_haddr  <= haddr;
        r_htrans <= htrans;
        r_hwrite <= hwrite;
        r_hsize  <= hsize;
      end if;
    end if;
  end process address_phase;


  -- Data phase data transfer
  data_phase : process (hclk_i, hreset_n_i) is
    variable addr : integer (7 downto 0);
  begin
    -- only last 3 bits are used for addressing
    addr := to_integer(hwaddr_i(2 downto 0));
    if hreset_n_i = '0' then
      x           <= (others => '0');
      y           <= (others => '0');
      z           <= (others => '0');
      x_result    <= (others => '0');
      y_result    <= (others => '0');
      z_result    <= (others => '0');
      control_in  <= (others => '0');
      control_out <= (others => '0');
      -- control_regs <= (others => (others => '0'));
    elsif rising_edge(hclk_i) then
      if (r_hsel and r_hwrite) then
        case addr is
          when 0 =>
            x <= hwdata_i;
          when 1 =>
            y <= hwdata_i;
          when 2 =>
            x <= hwdata_i;
          when 3 =>
            control_in <= hwdata_i;
          when others => null;
        end case;
        -- control_regs(addr) <= hwdata_i;
      end if;
    end if;
  end process data_phase;


  -- Tranfer response
  hreadyout_o <= '1';

  -- Read data
  -- purpose: output the register equivalent to the address on hwaddr
  -- type   : combinational
  -- inputs : all
  -- outputs:
  process (all) is
    -- only last 3 bits are used for addressing
    addr := to_integer(hwaddr_i(2 downto 0));
  begin  -- process
    case addr is
      when 0 =>
        hrdata_o <= x;
      when 1 =>
        hrdata_o <= y;
      when 2 =>
        hrdata_o <= x;
      when 3 =>
        hrdata_o <= control_in;
      when 4 =>
        hrdata_o <= x_result;
      when 5 =>
        hrdata_o <= y_result;
      when 6 =>
        hrdata_o <= x_result;
      when 7 =>
        hrdata_o <= control_out;
      when others => null;
    end case;
  end process;


-- Sequential implementation
  cs: cordic_sequential
    generic map (
      SIZE       => g_hdata_size,
      ITERATIONS => g_iterations
      )
    port map (
      Clock => hclk_i,
      Reset => rst,
      Data_valid   => control_start(0),
      Busy         => busy,
      Result_valid => result_valid,
      Mode         => cordic_rotate,
      X => x,
      Y => y,
      Z => z,
      X_result => x_result,
      Y_result => y_result,
      Z_result => z_result);

  control_done(0) <= result_valid and not busy;


end architecture rtl;

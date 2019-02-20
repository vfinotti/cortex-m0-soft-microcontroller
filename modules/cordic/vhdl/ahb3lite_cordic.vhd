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

library work;
use work.cordic.all;

entity ahb3lite_cordic is

  generic (
    g_iterations         : positive   := 32;   -- Number of iterarions for CORDIC algorithm
    g_reset_active_level : std_ulogic := '1';  -- Asynch. reset control level
    g_haddr_size         : positive   := 32;   -- Width of operands
    g_hdata_size         : positive   := 32;
    g_mode               : string     := "rotation");

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

  signal rst                          : std_ulogic;

  -- Address phase sampling registers
  signal r_hsel                       : std_logic                                  := '0';
  signal r_haddr                      : std_logic_vector (g_haddr_size-1 downto 0) := (others => '0');
  signal r_htrans                     : std_logic_vector(1 downto 0)               := (others => '0');
  signal r_hwrite                     : std_logic                                  := '0';
  signal r_hsize                      : std_logic_vector(2 downto 0)               := (others => '0');

  -- Data and control registers
  signal x, y, z                      : signed(g_hdata_size-1 downto 0)            := (others => '0');  -- 1 sign bit + 1 integer bit + g_hdata_size-2 fraction bits
  signal x_result, y_result, z_result : signed(g_hdata_size-1 downto 0)            := (others => '0');
  signal control_start                : std_logic_vector(g_hdata_size-1 downto 0)  := (others => '0');
  signal control_done                 : std_logic_vector(g_hdata_size-1 downto 0)  := (others => '0');
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
  signal cordic_mode_selection        : cordic_mode;

  signal result_valid                 : std_ulogic                                 := '0';
  signal busy                         : std_ulogic                                 := '0';
  signal data_valid                   : std_ulogic                                 := '0';
  signal detection_stages : std_logic_vector(1 downto 0);



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
      if (hready_i = '1') then
        r_hsel   <= hsel_i;
        r_haddr  <= haddr_i;
        r_htrans <= htrans_i;
        r_hwrite <= hwrite_i;
        r_hsize  <= hsize_i;
      end if;
    end if;
  end process address_phase;


  -- Data phase data transfer
  data_phase : process (hclk_i, hreset_n_i) is
    variable addr : integer range 0 to 28; -- offset in memory, considering
                                           -- each reg have 4 bytes
  begin
    -- only last 5 bits are used for addressing
    addr := to_integer(unsigned(r_haddr(4 downto 0)));
    if hreset_n_i = '0' then
      x             <= (others => '0');
      y             <= (others => '0');
      z             <= (others => '0');
      control_start <= (others => '0');
    -- control_regs <= (others => (others => '0'));
    elsif rising_edge(hclk_i) then
      if ((r_hsel and r_hwrite) = '1') then
        case addr is
          when 0 =>
            x <= signed(hwdata_i);
          when 4 =>
            y <= signed(hwdata_i);
          when 8 =>
            z <= signed(hwdata_i);
          when 12 =>
            control_start <= hwdata_i;
          when others => null;
        end case;
      -- control_regs(addr) <= hwdata_i;
      end if;
    end if;
  end process data_phase;


  -- Tranfer response
  hreadyout_o <= '1';
  hresp_o     <= '0';


  -- Read data
  -- purpose: output the register equivalent to the address on haddr
  -- type   : combinational
  -- inputs : all
  -- outputs:
  process (haddr_i) is
    variable addr : integer range 0 to 28; -- offset in memory, considering
                                           -- each reg have 4 bytes
  begin  -- process
    -- only last 5 bits are used for addressing
    addr := to_integer(unsigned(r_haddr(4 downto 0)));
    case addr is
      when 0 =>
        hrdata_o <= std_logic_vector(x);
      when 4 =>
        hrdata_o <= std_logic_vector(y);
      when 8 =>
        hrdata_o <= std_logic_vector(z);
      when 12 =>
        hrdata_o <= std_logic_vector(control_start);
      when 16 =>
        hrdata_o <= std_logic_vector(x_result);
      when 20 =>
        hrdata_o <= std_logic_vector(y_result);
      when 24 =>
        hrdata_o <= std_logic_vector(z_result);
      when 28 =>
        hrdata_o <= std_logic_vector(control_done);
      when others => null;
    end case;
  end process;

  edge_detector_1: entity work.edge_detector
    generic map (
      g_edge_type => "rising")
    port map (
      clk_i           => hclk_i,
      rst_i           => rst,
      signal_i        => control_start(0),
      edge_detected_o => data_valid);


  -- Necessary due to the custom type signal "cordic_mode" created for
  -- setting cordic_sequential core.
  cordic_mode_selection <= cordic_rotate when g_mode = "rotation" else
                           cordic_vector when g_mode = "vectoring" else
                           cordic_rotate;


-- Sequential implementation
  cs: entity work.cordic_sequential
    generic map (
      SIZE       => g_hdata_size,
      ITERATIONS => g_iterations
      )
    port map (
      Clock => hclk_i,
      Reset => rst,
      Data_valid   => data_valid,
      Busy         => busy,
      Result_valid => result_valid,
      Mode         => cordic_mode_selection,
      X => x,
      Y => y,
      Z => z,
      X_result => x_result,
      Y_result => y_result,
      Z_result => z_result);

  control_done(0) <= result_valid and not busy;


end architecture rtl;

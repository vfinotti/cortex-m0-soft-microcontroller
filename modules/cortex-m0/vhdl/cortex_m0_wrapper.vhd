-------------------------------------------------------------------------------
-- Vitor Finotti
--
-- https://github.com/vfinotti/cortex-m0-soft-microcontroller
-------------------------------------------------------------------------------
--
-- unit name:     Cortex-M0 VHDL Wrapper
--
-- description:
--
--   This module was created to wrap the CORTEXM0INTEGRATION module, designed
--   in Verilog, on a VHDL wrapper in order to preserve VHDL users' sanity
--   while using this code on mixed language projects. This was needed due to
--   many particularities of the Verilog language, like case sensitivity [1] or
--   the need to use qualified expressions [2].
--
--   Please, have in mind that the Cortex-M0 files are available on ARM website
--   through the DesignStart programme [3].
--
--   [1] https://stackoverflow.com/questions/38169074/case-sensitivity-while-using-verilog-module-in-vhdl
--   [2] https://www.xilinx.com/support/answers/57549.html
--   [3] https://www.arm.com/resources/designstart
--
-------------------------------------------------------------------------------
-- Copyright (c) 2018 Vitor Finotti
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

entity cortex_m0_wrapper is
  port (
    -- CLOCK AND RESETS ------------------
    hclk_i        : in  std_logic;                       -- Clock
    hreset_n_i    : in  std_logic;                       -- Asynchronous reset
    -- AHB-LITE MASTER PORT --------------
    haddr_o       : out std_logic_vector (31 downto 0);  -- AHB transaction address
    hburst_o      : out std_logic_vector (2 downto 0);   -- AHB burst: tied to single
    hmastlock_o   : out std_logic;                       -- AHB locked transfer (always zero)
    hprot_o       : out std_logic_vector (3 downto 0);   -- AHB protection: priv; data or inst
    hsize_o       : out std_logic_vector (2 downto 0);   -- AHB size: byte, half-word or word
    htrans_o      : out std_logic_vector (1 downto 0);   -- AHB transfer: non-sequential only
    hwdata_o      : out std_logic_vector (31 downto 0);  -- AHB write-data
    hwrite_o      : out std_logic;                       -- AHB write control
    hrdata_i      : in  std_logic_vector (31 downto 0);  -- AHB read-data
    hready_i      : in  std_logic;                       -- AHB stall signal
    hresp_i       : in  std_logic;                       -- ahb error response
    -- MISCELLANEOUS ---------------------
    nmi_i         : in  std_logic;                       -- Non-maskable interrupt input
    irq_i         : in  std_logic_vector (31 downto 0);  -- Interrupt request inputs
    txev_o        : out std_logic;                       -- Event output (SEV executed)
    rxev_i        : in  std_logic;                       -- Event input
    lockup_o      : out std_logic;                       -- Core is locked-up
    sysresetreq_o : out std_logic;                       -- System reset request
    -- POWER MANAGEMENT ------------------
    sleeping_o    : out std_logic);                      -- Core and NVIC sleeping
end entity cortex_m0_wrapper;

architecture rtl of cortex_m0_wrapper is

  -- component CORTEXM0INTEGRATION
  --   port(
  --     -- CLOCK AND RESETS ------------------
  --     --input  wire        HCLK,                         -- Clock
  --     --input  wire        HRESETn,                      -- Asynchronous reset
  --     HCLK        : in  std_logic;                       -- Clock
  --     HRESETn     : in  std_logic;                       -- Asynchronous reset
  --     -- AHB-LITE MASTER PORT --------------
  --     --output wire [31:0] HADDR,                        -- AHB transaction address
  --     --output wire [ 2:0] HBURST,                       -- AHB burst: tied to single
  --     --output wire        HMASTLOCK,                    -- AHB locked transfer (always zero)
  --     --output wire [ 3:0] HPROT,                        -- AHB protection: priv; data or inst
  --     --output wire [ 2:0] HSIZE,                        -- AHB size: byte, half-word or word
  --     --output wire [ 1:0] HTRANS,                       -- AHB transfer: non-sequential only
  --     --output wire [31:0] HWDATA,                       -- AHB write-data
  --     --output wire        HWRITE,                       -- AHB write control
  --     --input  wire [31:0] HRDATA,                       -- AHB read-data
  --     --input  wire        HREADY,                       -- AHB stall signal
  --     --input  wire        HRESP,                        -- AHB error response
  --     HADDR       : out std_logic_vector (31 downto 0);  -- AHB transaction address
  --     HBURST      : out std_logic_vector (2 downto 0);   -- AHB burst: tied to single
  --     HMASTLOCK   : out std_logic;                       -- AHB locked transfer (always zero)
  --     HPROT       : out std_logic_vector (3 downto 0);   -- AHB protection: priv; data or inst
  --     HSIZE       : out std_logic_vector (2 downto 0);   -- AHB size: byte, half-word or word
  --     HTRANS      : out std_logic_vector (1 downto 0);   -- AHB transfer: non-sequential only
  --     HWDATA      : out std_logic_vector (31 downto 0);  -- AHB write-data
  --     HWRITE      : out std_logic;                       -- AHB write control
  --     HRDATA      : in  std_logic_vector (31 downto 0);  -- AHB read-data
  --     HREADY      : in  std_logic;                       -- AHB stall signal
  --     HRESP       : in  std_logic;                       -- AHB error response
  --     -- MISCELLANEOUS ---------------------
  --     --input  wire        NMI,                          -- Non-maskable interrupt input
  --     --input  wire [15:0] IRQ,                          -- Interrupt request inputs
  --     --output wire        TXEV,                         -- Event output (SEV executed)
  --     --input  wire        RXEV,                         -- Event input
  --     --output wire        LOCKUP,                       -- Core is locked-up
  --     --output wire        SYSRESETREQ,                  -- System reset request
  --     NMI         : in  std_logic;                       -- Non-maskable interrupt input
  --     IRQ         : in  std_logic_vector (31 downto 0);  -- Interrupt request inputs
  --     TXEV        : out std_logic;                       -- Event output (SEV executed)
  --     RXEV        : in  std_logic;                       -- Event input
  --     LOCKUP      : out std_logic;                       -- Core is locked-up
  --     SYSRESETREQ : out std_logic;                       -- System reset request
  --     -- POWER MANAGEMENT ------------------
  --     --output wire        SLEEPING                      -- Core and NVIC sleeping
  --     SLEEPING    : out std_logic                        -- Core and NVIC sleeping
  --     );
  -- end component;

  signal FCLK          : std_logic                      := '0';
  signal SCLK          : std_logic                      := '0';
  signal HCLK          : std_logic                      := '0';
  signal DCLK          : std_logic                      := '0';
  signal PORESETn      : std_logic                      := '1';
  signal DBGRESETn     : std_logic                      := '1';
  signal HRESETn       : std_logic                      := '0';
  signal SWCLKTCK      : std_logic                      := '0';
  signal nTRST         : std_logic                      := '1';
  signal HADDR         : std_logic_vector (31 downto 0) := (others => '0');
  signal HBURST        : std_logic_vector (2 downto 0)  := (others => '0');
  signal HMASTLOCK     : std_logic                      := '0';
  signal HPROT         : std_logic_vector (3 downto 0)  := (others => '0');
  signal HSIZE         : std_logic_vector (2 downto 0)  := (others => '0');
  signal HTRANS        : std_logic_vector (1 downto 0)  := (others => '0');
  signal HWDATA        : std_logic_vector (31 downto 0) := (others => '0');
  signal HWRITE        : std_logic                      := '0';
  signal HRDATA        : std_logic_vector (31 downto 0) := (others => '0');
  signal HREADY        : std_logic                      := '0';
  signal HRESP         : std_logic                      := '0';
  signal HMASTER       : std_logic                      := '0';
  signal CODENSEQ      : std_logic                      := '0';
  signal CODEHINTDE    : std_logic_vector (2 downto 0)  := (others => '0');
  signal SPECHTRANS    : std_logic                      := '0';
  signal SWDITMS       : std_logic                      := '0';
  signal TDI           : std_logic                      := '0';
  signal SWDO          : std_logic                      := '0';
  signal SWDOEN        : std_logic                      := '0';
  signal TDO           : std_logic                      := '0';
  signal nTDOEN        : std_logic                      := '0';
  signal DBGRESTART    : std_logic                      := '0';
  signal DBGRESTARTED  : std_logic                      := '0';
  signal EDBGRQ        : std_logic                      := '0';
  signal HALTED        : std_logic                      := '0';
  signal NMI           : std_logic                      := '0';
  signal IRQ           : std_logic_vector (31 downto 0) := (others => '0');
  signal TXEV          : std_logic                      := '0';
  signal RXEV          : std_logic                      := '0';
  signal LOCKUP        : std_logic                      := '0';
  signal SYSRESETREQ   : std_logic                      := '0';
  signal STCALIB       : std_logic_vector (25 downto 0) := (others => '0');
  signal STCLKEN       : std_logic                      := '0';
  signal IRQLATENCY    : std_logic_vector (7 downto 0)  := (others => '0');
  signal ECOREVNUM     : std_logic_vector (27 downto 0) := (others => '0');
  signal GATEHCLK      : std_logic                      := '0';
  signal SLEEPING      : std_logic                      := '0';
  signal SLEEPDEEP     : std_logic                      := '0';
  signal WAKEUP        : std_logic                      := '0';
  signal WICSENSE      : std_logic_vector(33 downto 0)  := (others => '0');
  signal SLEEPHOLDREQn : std_logic                      := '1';
  signal SLEEPHOLDACKn : std_logic                      := '0';
  signal WICENREQ      : std_logic                      := '0';
  signal WICENACK      : std_logic                      := '0';
  signal CDBGPWRUPREQ  : std_logic                      := '0';
  signal CDBGPWRUPACK  : std_logic                      := '0';
  signal SE            : std_logic                      := '0';
  signal RSTBYPASS     : std_logic                      := '0';

  component CORTEXM0INTEGRATION
    port(
      -- CLOCK AND RESETS ------------------
      -- input  wire        FCLK,
      -- input  wire        SCLK,
      -- input  wire        HCLK,                        -- Clock
      -- input  wire        DCLK,                        -- Asynchronous reset
      -- input  wire        PORESETn,
      -- input  wire        DBGRESETn,
      -- input  wire        HRESETn,
      -- input  wire        SWCLKTCK,
      -- input  wire        nTRST,
      FCLK        : in  std_logic;                       -- Free running clock
      SCLK        : in  std_logic;                       -- System clock
      HCLK        : in  std_logic;                       -- AHB clock(from PMU)
      DCLK        : in  std_logic;                       -- Debug system clock (from PMU)
      PORESETn    : in  std_logic;                       -- Power on reset
      DBGRESETn   : in  std_logic;                       -- Debug reset
      HRESETn     : in  std_logic;                       -- AHB and System reset
      SWCLKTCK    : in  std_logic;                       --
      nTRST       : in  std_logic;                       --
      -- AHB-LITE MASTER PORT --------------
      -- output wire [31:0] HADDR,                       -- AHB transaction address
      -- output wire [ 2:0] HBURST,                      -- AHB burst: tied to single
      -- output wire        HMASTLOCK,                   -- AHB locked transfer (always zero)
      -- output wire [ 3:0] HPROT,                       -- AHB protection: priv; data or inst
      -- output wire [ 2:0] HSIZE,                       -- AHB size: byte, half-word or word
      -- output wire [ 1:0] HTRANS,                      -- AHB transfer: non-sequential only
      -- output wire [31:0] HWDATA,                      -- AHB write-data
      -- output wire        HWRITE,                      -- AHB write control
      -- input  wire [31:0] HRDATA,                      -- AHB read-data
      -- input  wire        HREADY,                      -- AHB stall signal
      -- input  wire        HRESP,                       -- AHB error response
      -- output wire        HMASTER,
      HADDR       : out std_logic_vector (31 downto 0);  -- AHB transaction address
      HBURST      : out std_logic_vector (2 downto 0);   -- AHB burst: tied to single
      HMASTLOCK   : out std_logic;                       -- AHB locked transfer (always zero)
      HPROT       : out std_logic_vector (3 downto 0);   -- AHB protection: priv; data or inst
      HSIZE       : out std_logic_vector (2 downto 0);   -- AHB size: byte, half-word or word
      HTRANS      : out std_logic_vector (1 downto 0);   -- AHB transfer: non-sequential only
      HWDATA      : out std_logic_vector (31 downto 0);  -- AHB write-data
      HWRITE      : out std_logic;                       -- AHB write control
      HRDATA      : in  std_logic_vector (31 downto 0);  -- AHB read-data
      HREADY      : in  std_logic;                       -- AHB stall signal
      HRESP       : in  std_logic;                       -- AHB error response
      HMASTER     : out std_logic;
      -- CODE SEQUENTIALITY AND SPECULATION
      -- output wire        CODENSEQ,
      -- output wire [ 2:0] CODEHINTDE,
      -- output wire        SPECHTRANS,
      CODENSEQ     : out std_logic;
      CODEHINTDE   : out std_logic_vector (2 downto 0);
      SPECHTRANS   : out std_logic;
      -- DEBUG -----------------------------
      -- input  wire        SWDITMS,
      -- input  wire        TDI,
      -- output wire        SWDO,
      -- output wire        SWDOEN,
      -- output wire        TDO,
      -- output wire        nTDOEN,
      -- input  wire        DBGRESTART,
      -- output wire        DBGRESTARTED,
      -- input  wire        EDBGRQ,
      -- output wire        HALTED,
      SWDITMS      : in  std_logic;
      TDI          : in  std_logic;
      SWDO         : out std_logic;
      SWDOEN       : out std_logic;
      TDO          : out std_logic;
      nTDOEN       : out std_logic;
      DBGRESTART   : in  std_logic;
      DBGRESTARTED : out std_logic;
      EDBGRQ       : in  std_logic;
      HALTED       : out std_logic;
      -- MISCELLANEOUS ---------------------
      -- input  wire        NMI,                         -- Non-maskable interrupt input
      -- input  wire [31:0] IRQ,                         -- Interrupt request inputs
      -- output wire        TXEV,                        -- Event output (SEV executed)
      -- input  wire        RXEV,                        -- Event input
      -- output wire        LOCKUP,                      -- Core is locked-up
      -- output wire        SYSRESETREQ,                 -- System reset request
      -- input  wire [25 : 0] STCALIB,
      -- input  wire        STCLKEN,
      -- input  wire [ 7:0] IRQLATENCY,
      -- input  wire [27:0] ECOREVNUM,    // [27:20] to DAP, [19:0] to core
      NMI         : in  std_logic;      -- Non-maskable interrupt input
      IRQ         : in  std_logic_vector (31 downto 0);  -- Interrupt request inputs
      TXEV        : out std_logic;      -- Event output (SEV executed)
      RXEV        : in  std_logic;      -- Event input
      LOCKUP      : out std_logic;      -- Core is locked-up
      SYSRESETREQ : out std_logic;      -- System reset request
      STCALIB     : in  std_logic_vector (25 downto 0);
      STCLKEN     : in  std_logic;
      IRQLATENCY  : in  std_logic_vector (7 downto 0);
      ECOREVNUM   : in  std_logic_vector (27 downto 0);  -- [27 : 20] to DAP,  [19 : 0] to core
      -- POWER MANAGEMENT ------------------
      -- output wire        GATEHCLK,
      -- output wire        SLEEPING                     -- Core and NVIC sleeping
      -- output wire        SLEEPDEEP,
      -- output wire        WAKEUP,
      -- output wire [33:0] WICSENSE,
      -- input  wire        SLEEPHOLDREQn,
      -- output wire        SLEEPHOLDACKn,
      -- input  wire        WICENREQ,
      -- output wire        WICENACK,
      -- output wire        CDBGPWRUPREQ,
      -- input  wire        CDBGPWRUPACK,
      GATEHCLK      : out std_logic;
      SLEEPING      : out std_logic;    -- Core and NVIC sleeping
      SLEEPDEEP     : out std_logic;
      WAKEUP        : out std_logic;
      WICSENSE      : out std_logic_vector(33 downto 0);
      SLEEPHOLDREQn : in  std_logic;
      SLEEPHOLDACKn : out std_logic;
      WICENREQ      : in  std_logic;
      WICENACK      : out std_logic;
      CDBGPWRUPREQ  : out std_logic;
      CDBGPWRUPACK  : in  std_logic;
      -- SCAN IO ---------------------------
      -- input  wire        SE,
      -- input  wire        RSTBYPASS,
      SE            : in  std_logic;
      RSTBYPASS     : in  std_logic);
  end component;

begin  -- architecture rtl


  -- Processor : CORTEXM0INTEGRATION
  --   port map (
  --   -- CLOCK AND RESETS ------------------
  --   HCLK        => hclk_i,                                  -- Clock
  --   HRESETn     => hreset_n_i,                              -- Asynchronous reset
  --   -- AHB-LITE MASTER PORT --------------
  --   HADDR       => haddr_o,                                 -- AHB transaction address
  --   HBURST      => hburst_o,                                -- AHB burst: tied to single
  --   HMASTLOCK   => hmastlock_o,                             -- AHB locked transfer (always zero)
  --   HPROT       => hprot_o,                                 -- AHB protection: priv; data or inst
  --   HSIZE       => hsize_o,                                 -- AHB size: byte, half-word or word
  --   HTRANS      => htrans_o,                                -- AHB transfer: non-sequential only
  --   HWDATA      => hwdata_o,                                -- AHB write-data
  --   HWRITE      => hwrite_o,                                -- AHB write control
  --   HRDATA      => hrdata_i,                                -- AHB read-data
  --   HREADY      => hready_i,                                -- AHB stall signal
  --   HRESP       => hresp_i,                                 -- AHB error response
  --   -- MISCELLANEOUS ---------------------
  --   NMI         => nmi_i,                                   -- Non-maskable interrupt input
  --   IRQ         => irq_i,                                   -- Interrupt request inputs
  --   TXEV        => txev_o,                                  -- Event output (SEV executed)
  --   RXEV        => rxev_i,                                  -- Event input
  --   LOCKUP      => lockup_o,                                -- Core is locked-up
  --   SYSRESETREQ => sysresetreq_o,                           -- System reset request
  --   -- POWER MANAGEMENT ------------------
  --   SLEEPING    => sleeping_o);                             -- Core and NVIC sleeping

  Processor : CORTEXM0INTEGRATION
    port map (
      -- CLOCK AND RESETS ------------------
      FCLK          => FCLK,
      SCLK          => SCLK,
      HCLK          => HCLK,
      DCLK          => DCLK,
      PORESETn      => PORESETn,
      DBGRESETn     => DBGRESETn,
      HRESETn       => HRESETn,
      SWCLKTCK      => SWCLKTCK,
      nTRST         => nTRST,
      -- AHB-LITE MASTER PORT --------------
      HADDR         => HADDR,
      HBURST        => HBURST,
      HMASTLOCK     => HMASTLOCK,
      HPROT         => HPROT,
      HSIZE         => HSIZE,
      HTRANS        => HTRANS,
      HWDATA        => HWDATA,
      HWRITE        => HWRITE,
      HRDATA        => HRDATA,
      HREADY        => HREADY,
      HRESP         => HRESP,
      HMASTER       => HMASTER,
      -- CODE SEQUENTIALITY AND SPECULATION
      CODENSEQ      => CODENSEQ,
      CODEHINTDE    => CODEHINTDE,
      SPECHTRANS    => SPECHTRANS,
      -- DEBUG -----------------------------
      SWDITMS       => SWDITMS,
      TDI           => TDI,
      SWDO          => SWDO,
      SWDOEN        => SWDOEN,
      TDO           => TDO,
      nTDOEN        => nTDOEN,
      DBGRESTART    => DBGRESTART,
      DBGRESTARTED  => DBGRESTARTED,
      EDBGRQ        => EDBGRQ,
      HALTED        => HALTED,
      -- MISCELLANEOUS ---------------------
      NMI           => NMI,
      IRQ           => IRQ,
      TXEV          => TXEV,
      RXEV          => RXEV,
      LOCKUP        => LOCKUP,
      SYSRESETREQ   => SYSRESETREQ,
      STCALIB       => STCALIB,
      STCLKEN       => STCLKEN,
      IRQLATENCY    => IRQLATENCY,
      ECOREVNUM     => ECOREVNUM,
      -- POWER MANAGEMENT ------------------
      GATEHCLK      => GATEHCLK,
      SLEEPING      => SLEEPING,
      SLEEPDEEP     => SLEEPDEEP,
      WAKEUP        => WAKEUP,
      WICSENSE      => WICSENSE,
      SLEEPHOLDREQn => SLEEPHOLDREQn,
      SLEEPHOLDACKn => SLEEPHOLDACKn,
      WICENREQ      => WICENREQ,
      WICENACK      => WICENACK,
      CDBGPWRUPREQ  => CDBGPWRUPREQ,
      CDBGPWRUPACK  => CDBGPWRUPACK,
      -- SCAN IO ---------------------------
      SE            => SE,
      RSTBYPASS     => RSTBYPASS);

  FCLK          <= hclk_i;
  SCLK          <= hclk_i;
  HCLK          <= hclk_i;
  DCLK          <= hclk_i;
  SWCLKTCK      <= hclk_i;
  PORESETn      <= hreset_n_i;
  DBGRESETn     <= hreset_n_i;
  HRESETn       <= hreset_n_i;
  nTRST         <= hreset_n_i;

  haddr_o       <= HADDR;
  hburst_o      <= HBURST;
  hmastlock_o   <= HMASTLOCK;
  hprot_o       <= HPROT;
  hsize_o       <= HSIZE;
  htrans_o      <= HTRANS;
  hwdata_o      <= HWDATA;
  hwrite_o      <= HWRITE;
  HRDATA        <= hrdata_i;
  HREADY        <= hready_i;
  HRESP         <= hresp_i;

  NMI           <= nmi_i;
  IRQ           <= irq_i;
  txev_o        <= TXEV;
  RXEV          <= rxev_i;
  lockup_o      <= LOCKUP;
  sysresetreq_o <= SYSRESETREQ;

  sleeping_o    <= SLEEPING;


end architecture rtl;

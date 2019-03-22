// Obtained from https://www.valpont.com/ahb-to-wishbone-and-wishbone-to-ahb-bridges-in-verilog/pst/

module m_wb2ahb(
  ////ahb
    HCLK,
    HRESETn,

    mHSEL,
    mHSIZE,
    mHRDATA,
    mHRESP,
    mHREADY,
    mHREADYOUT,
    mHWRITE,
    mHBURST,
    mHADDR,
    mHTRANS,
    mHWDATA,
    mHPROT,

  ////to wishbone
    from_m_wb_adr_o,
    from_m_wb_sel_o,
    from_m_wb_we_o,
    from_m_wb_dat_o,
    from_m_wb_cyc_o,
    from_m_wb_stb_o,
    to_m_wb_ack_i,
    to_m_wb_err_i,
    to_m_wb_dat_i,

    from_m_wb_cti_o,
    from_m_wb_bte_o

);
input          HCLK;
input	       HRESETn;

input  [31:0]  mHRDATA;
input          mHRESP;
input          mHREADY;
output         mHSEL;
output [2:0]   mHSIZE;
output         mHWRITE;
output [2:0]   mHBURST;
output [31:0]  mHADDR;
output [1:0]   mHTRANS;
output [31:0]  mHWDATA;
output         mHREADYOUT;
output  [3:0]  mHPROT;

input  [31:0]  from_m_wb_adr_o;
input  [3:0]   from_m_wb_sel_o;
input          from_m_wb_we_o;
input  [31:0]  from_m_wb_dat_o;
input          from_m_wb_cyc_o;
input          from_m_wb_stb_o;
output         to_m_wb_ack_i;
output         to_m_wb_err_i;
output [31:0]  to_m_wb_dat_i;

input  [2:0]   from_m_wb_cti_o;
input  [1:0]   from_m_wb_bte_o;

//////////////////////////////////
parameter [1:0] IDLE   = 2'b00,
                BUSY   = 2'b01,
                NONSEQ = 2'b10,
                SEQ    = 2'b11;
//////////////////////////////////
reg             ackmask;
reg             ctrlstart;
wire            isburst;
//////////////////////////////////
assign isburst       = (from_m_wb_cti_o == 3'b000) ? 1'b0 : 1'b1;
assign to_m_wb_dat_i = mHRDATA ;
assign to_m_wb_ack_i = ackmask & mHREADY & from_m_wb_stb_o;
assign mHADDR        = (~isburst || (ctrlstart && !ackmask) || !ctrlstart) ? from_m_wb_adr_o
                        : from_m_wb_adr_o + 3'b100;
assign mHWDATA       = from_m_wb_dat_o;
assign mHSIZE        = 3'b010;                                //word
assign mHBURST       = (ctrlstart && (from_m_wb_cti_o == 3'b010)) ? 3'b011 : 3'b000;

assign mHWRITE       = from_m_wb_we_o;
assign mHTRANS       = (ctrlstart && !ackmask)
                       ? NONSEQ
                       : ( (from_m_wb_cti_o == 3'b010 && ctrlstart) ? SEQ : IDLE );
assign to_m_wb_err_i = mHRESP;
assign mHSEL         = from_m_wb_cyc_o;
assign mHREADYOUT    = 1'b1;

always @(posedge HCLK or negedge HRESETn)
begin
  if(!HRESETn)
    ctrlstart <= 1'b0;
  else if(mHREADY && !ctrlstart)
    ctrlstart <= 1'b1;
  else if(ctrlstart)
    ctrlstart <= 1'b1;
  else
    ctrlstart <= 1'b0;
end

always @(posedge HCLK or negedge HRESETn)
begin
  if(!HRESETn)
      ackmask <= 1'b0;
  else if(!from_m_wb_stb_o)
      ackmask <= 1'b0;
  else if(!ctrlstart && !ackmask)
      ackmask <= 1'b0;
  else if(ctrlstart && !to_m_wb_ack_i && mHREADY)
      ackmask <= 1'b1;
  else if(to_m_wb_ack_i && !isburst)
      ackmask <= 1'b0;
  else if(from_m_wb_cti_o == 3'b111 && mHREADY)
      ackmask <= 1'b0;
  else
      ackmask <= 1'b1;
end

endmodule

// Obtained from https://www.valpont.com/ahb-to-wishbone-and-wishbone-to-ahb-bridges-in-verilog/pst/

module s_ahb2wb(
  //ahb
    HCLK,
    HRESETn,

    sHADDR,
    sHWDATA,
    sHWRITE,
    sHREADY,
    sHSIZE,
    sHBURST,
    sHSEL,
    sHTRANS,
    sHRDATA,
    sHRESP,
    sHREADYIN,

  //to wishbone
    to_wb_dat_i,
    to_wb_adr_i,
    to_wb_sel_i,
    to_wb_we_i,
    to_wb_cyc_i,
    to_wb_stb_i,
    from_wb_dat_o,
    from_wb_ack_o,
    from_wb_err_o

);

input           HCLK;
input	        HRESETn;
input   [13:0]  sHADDR;
input   [31:0]  sHWDATA;
input           sHWRITE;
input   [2:0]   sHSIZE;
input   [2:0]   sHBURST;
input           sHSEL;
input   [1:0]   sHTRANS;
input           sHREADYIN;
output          sHREADY;
output  [31:0]  sHRDATA;
output  [1:0]   sHRESP;

output  [31:0]  to_wb_dat_i;
output  [11:2]  to_wb_adr_i;
output  [3 :0]  to_wb_sel_i;
output          to_wb_we_i;
output          to_wb_cyc_i;
output          to_wb_stb_i;
input   [31:0]  from_wb_dat_o;
input           from_wb_ack_o;
input           from_wb_err_o;

/////////////////////////////////////////////////////
reg [1:0]   NextsHRESP;
reg [1:0]   isHRESP;

reg         Nextto_wb_cyc_i;
reg         ito_wb_cyc_i;

reg         Nextto_wb_stb_i;
reg         ito_wb_stb_i;

reg [3:0]   Nextto_wb_sel_i;
reg [3:0]   ito_wb_sel_i;

reg [13:0]  Nextto_wb_adr_i;
reg [13:0]  ito_wb_adr_i;

reg         Nextto_wb_we_i;
reg         ito_wb_we_i;
reg         adr_valid;
/////////////////////////////////////////////////////
assign to_wb_adr_i   = ito_wb_adr_i[11:2];
assign to_wb_we_i    = ito_wb_we_i;
assign to_wb_dat_i   = sHWDATA;
assign to_wb_sel_i   = ito_wb_sel_i;
assign sHRDATA       = from_wb_dat_o;
assign sHREADY       = (to_wb_stb_i)   ? from_wb_ack_o : 1'b1;
assign sHRESP        = (from_wb_err_o) ? 2'b01         : isHRESP;
assign to_wb_cyc_i   = ito_wb_cyc_i;
assign to_wb_stb_i   = ito_wb_stb_i;

always @(sHSEL or sHADDR)
  if(!sHSEL)
    adr_valid = 1'b0;
  else if(sHADDR <= 13'h50 || (sHADDR <=13'h800 && sHADDR >= 13'h400))
    adr_valid = 1'b1;
  else
    adr_valid = 1'b0;

always @(*)
begin
  NextsHRESP      = isHRESP;
  Nextto_wb_cyc_i = ito_wb_cyc_i;
  Nextto_wb_stb_i = ito_wb_stb_i;
  Nextto_wb_adr_i = ito_wb_adr_i;
  Nextto_wb_we_i  = ito_wb_we_i;
  Nextto_wb_sel_i = ito_wb_sel_i;

  if(sHSEL)
    begin
      if(sHREADYIN)
        begin
          if(sHSIZE != 3'b010 || !adr_valid)
            begin
              Nextto_wb_we_i  = 1'b0;
              Nextto_wb_cyc_i = 1'b0;
              Nextto_wb_stb_i = 1'b0;
              Nextto_wb_adr_i = 14'b0;
              Nextto_wb_sel_i = 4'b0;
              if(sHTRANS == 2'b00)
                NextsHRESP    = 2'b00;
              else
                NextsHRESP    = 2'b01;
            end
          else
            begin
              case(sHTRANS)
                2'b00:
                  begin
                    NextsHRESP      = 2'b00;
                    Nextto_wb_cyc_i = 1'b0;
                    Nextto_wb_stb_i = 1'b0;
                    Nextto_wb_adr_i = 14'b0;
                    Nextto_wb_sel_i = 4'b0;
                  end
                2'b01:
                  begin
                    Nextto_wb_cyc_i = 1'b1;
                    Nextto_wb_stb_i = 1'b0;
                  end
                2'b10,2'b11:
                  begin
                    NextsHRESP      = 2'b00;
                    Nextto_wb_cyc_i = 1'b1;
                    Nextto_wb_stb_i = 1'b1;
                    Nextto_wb_adr_i = sHADDR;
                    Nextto_wb_we_i  = sHWRITE;
                    Nextto_wb_sel_i = 4'b1111;
                  end
              endcase
            end
        end
      else
        begin

        end
    end
  else
    begin
      NextsHRESP      = 2'b00;
      Nextto_wb_we_i  = 1'b0;
      Nextto_wb_cyc_i = 1'b0;
      Nextto_wb_stb_i = 1'b0;
      Nextto_wb_adr_i = 14'b0;
      Nextto_wb_sel_i = 3'b0;
    end

end

always @(posedge HCLK or negedge HRESETn)
begin
  if(!HRESETn)
    begin
      isHRESP      <= 2'b00;
      ito_wb_cyc_i <= 1'b0;
      ito_wb_stb_i <= 1'b0;
      ito_wb_adr_i <= 12'b0;
      ito_wb_we_i  <= 1'b0;
      ito_wb_sel_i <= 4'b0;
    end
  else
    begin
      isHRESP      <= NextsHRESP;
      ito_wb_cyc_i <= Nextto_wb_cyc_i;
      ito_wb_stb_i <= Nextto_wb_stb_i;
      ito_wb_adr_i <= Nextto_wb_adr_i;
      ito_wb_we_i  <= Nextto_wb_we_i;
      ito_wb_sel_i <= Nextto_wb_sel_i;
    end
end

endmodule

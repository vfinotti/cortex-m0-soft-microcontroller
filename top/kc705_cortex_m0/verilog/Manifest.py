files = [
    "cm0_softmc_top.sv",
    "../cm0_softmc_top.xdc",
    "../../../ip_cores/roa_logic/ahb3lite_interconnect/rtl/verilog/ahb3lite_interconnect_master_port.sv",
    "../../../ip_cores/roa_logic/ahb3lite_interconnect/rtl/verilog/ahb3lite_interconnect_slave_port.sv",
    "../../../ip_cores/roa_logic/ahb3lite_interconnect/rtl/verilog/ahb3lite_interconnect.sv",
    "../../../ip_cores/roa_logic/ahb3lite_pkg/rtl/verilog/ahb3lite_pkg.sv",
    "../../../ip_cores/roa_logic/ahb3lite_memory/rtl/verilog/ahb3lite_sram1rw.sv",
    "../../../ip_cores/roa_logic/memory/rtl/verilog/rl_ram_1r1w.sv",
    "../../../ip_cores/roa_logic/memory/rtl/verilog/rl_ram_1r1w_generic.sv",
]

modules = {
  "local" : [ "../../../modules/cortex-m0/vhdl",
              "../../../modules/clk/vhdl",
              "../../../modules/memory/vhdl",
              "../../../modules/ahb3lite/vhdl",
              "../../../ip_cores/general-cores",
              "../../../modules/misc/vhdl"],

}
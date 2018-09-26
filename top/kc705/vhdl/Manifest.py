files = [
    "cm0_softmc_top.vhd",
    "../cm0_softmc_top.xdc",
]

modules = {
  "local" : [ "../../../modules/cortex-m0/vhdl",
              "../../../modules/clk/vhdl",
              "../../../modules/memory/vhdl",
              "../../../ip_cores/general-cores/modules/common",
              "../../../ip_cores/general-cores/modules/genrams",
              "../../../ip_cores/general-cores/modules/wishbone",
              "../../../modules/misc/vhdl"],
}

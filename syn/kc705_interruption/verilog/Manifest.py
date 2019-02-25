target = "xilinx"
action = "synthesis"

syn_device = "xc7k325t"
syn_grade = "-2"
syn_package = "ffg900"
syn_top = "cm0_interruption_top"
syn_project = "cm0_interruption_top"
syn_tool = "vivado"

modules = {
  "local" : [ "../../../top/kc705_interruption/verilog" ],
}


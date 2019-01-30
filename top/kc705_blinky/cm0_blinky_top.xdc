#sysclk
set_property PACKAGE_PIN AD11 [get_ports sys_clk_n_i]
set_property IOSTANDARD LVDS  [get_ports sys_clk_n_i]
set_property PACKAGE_PIN AD12 [get_ports sys_clk_p_i]
set_property IOSTANDARD LVDS  [get_ports sys_clk_p_i]

create_clock -period 5.000 -name  sys_clk_p_i [get_ports  sys_clk_p_i]
set_clock_groups -asynchronous -group  sys_clk_p_i

# GPIO LEDs
set_property PACKAGE_PIN AB8     [get_ports {led0}]
set_property IOSTANDARD LVCMOS15 [get_ports {led0}]
set_property PACKAGE_PIN AA8     [get_ports {led1}]
set_property IOSTANDARD LVCMOS15 [get_ports {led1}]
set_property PACKAGE_PIN AC9     [get_ports {led2}]
set_property IOSTANDARD LVCMOS15 [get_ports {led2}]
set_property PACKAGE_PIN AB9     [get_ports {led3}]
set_property IOSTANDARD LVCMOS15 [get_ports {led3}]
set_property PACKAGE_PIN AE26    [get_ports {led4}]
set_property IOSTANDARD LVCMOS25 [get_ports {led4}]
set_property PACKAGE_PIN G19     [get_ports {led5}]
set_property IOSTANDARD LVCMOS25 [get_ports {led5}]
set_property PACKAGE_PIN E18     [get_ports {led6}]
set_property IOSTANDARD LVCMOS25 [get_ports {led6}]
set_property PACKAGE_PIN F16     [get_ports {led7}]
set_property IOSTANDARD LVCMOS25 [get_ports {led7}]

# GPIO DIP SW
## SW0
#set_property PACKAGE_PIN Y29       [get_ports {switches_i[0]}]
#set_property IOSTANDARD LVCMOS25   [get_ports {switches_i[0]}]
## SW1
#set_property PACKAGE_PIN W29       [get_ports {switches_i[1]}]
#set_property IOSTANDARD LVCMOS25   [get_ports {switches_i[1]}]
## SW2
#set_property PACKAGE_PIN AA28      [get_ports {switches_i[2]}]
#set_property IOSTANDARD LVCMOS25   [get_ports {switches_i[2]}]
## SW3
#set_property PACKAGE_PIN Y28      [get_ports {switches_i[3]}]
#set_property IOSTANDARD LVCMOS25  [get_ports {switches_i[3]}]

# GPIO PUSHBUTTON SW
## east
set_property PACKAGE_PIN AG5      [get_ports {push_button0_i}]
set_property IOSTANDARD LVCMOS15  [get_ports {push_button0_i}]
## center
#set_property PACKAGE_PIN G12      [get_ports {push_buttons_i[1]}]
#set_property IOSTANDARD LVCMOS25  [get_ports {push_buttons_i[1]}]
## west
#set_property PACKAGE_PIN AC6      [get_ports {push_buttons_i[2]}]
#set_property IOSTANDARD LVCMOS15  [get_ports {push_buttons_i[2]}]
## north
#set_property PACKAGE_PIN AA12    [get_ports {push_buttons_i[3]}]
#set_property IOSTANDARD LVCMOS15 [get_ports {push_buttons_i[3]}]
## south
#set_property PACKAGE_PIN AB12    [get_ports {push_buttons_i[4]}]
#set_property IOSTANDARD LVCMOS15 [get_ports {push_buttons_i[4]}]

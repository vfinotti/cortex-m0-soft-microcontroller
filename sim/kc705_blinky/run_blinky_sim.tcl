restart
add_force {/cm0_softmc_top/clk_200mhz} -radix hex {0 0ns} {1 2500ps} -repeat_every 5000ps
add_force {/cm0_softmc_top/push_button0_i} -radix hex {1 0ns} {0 10000000ps} -repeat_every 1000000000ps
run 400us

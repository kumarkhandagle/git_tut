############################
# Switches for a[1:0]
############################
set_property PACKAGE_PIN G15 [get_ports {a[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {a[0]}]

set_property PACKAGE_PIN P15 [get_ports {a[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {a[1]}]

############################
# Switches for b[1:0]
############################
set_property PACKAGE_PIN W13 [get_ports {b[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {b[0]}]

set_property PACKAGE_PIN T16 [get_ports {b[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {b[1]}]

############################
# Push Button for cin
############################
set_property PACKAGE_PIN M14 [get_ports cin]
set_property IOSTANDARD LVCMOS33 [get_ports cin]

############################
# LEDs for sum[2:0]
############################
set_property PACKAGE_PIN M15 [get_ports {sum[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sum[0]}]

set_property PACKAGE_PIN G14 [get_ports {sum[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sum[1]}]

set_property PACKAGE_PIN D18 [get_ports {sum[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sum[2]}]

############################
# LED for cout
############################
set_property PACKAGE_PIN E18 [get_ports cout]
set_property IOSTANDARD LVCMOS33 [get_ports cout]
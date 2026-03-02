###########################################################
# Clean project folder
###########################################################
if {[file exists ./builds]} {
    file delete -force ./builds
}

###########################################################
# Create project using BOARD instead of PART
###########################################################
create_project my_proj ./builds -part xc7z010clg400-1

exit 1

###########################################################
# Add RTL sources

set rtl_files [glob -nocomplain ./src/*.v]
add_files $rtl_files

###########################################################
# Add constraints
###########################################################
set xdc_files [glob -nocomplain ./constr/*.xdc]
add_files -fileset constrs_1 $xdc_files

###########################################################
# Update compile order
###########################################################
update_compile_order -fileset sources_1

###########################################################
# ---------------- SIMULATION ----------------------------
###########################################################
puts "Starting simulation..."

xvlog $rtl_files
xelab tb_adder -s tb
xsim tb -runall

puts "Simulation completed"

###########################################################
# ---------------- SYNTHESIS -----------------------------
###########################################################
puts "Starting synthesis..."

launch_runs synth_1 -jobs 4
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
puts "Synthesis status: $synth_status"

if {[string match "*ERROR*" $synth_status]} {
    puts "Synthesis failed"
    exit 1
}

###########################################################
# ---------------- IMPLEMENTATION ------------------------
###########################################################
puts "Starting implementation..."

launch_runs impl_1 -jobs 4
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
puts "Implementation status: $impl_status"

if {[string match "*ERROR*" $impl_status]} {
    puts "Implementation failed"
    exit 1
}

###########################################################
# ---------------- BITSTREAM -----------------------------
###########################################################
puts "Generating bitstream..."

launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

puts "Bitstream generated successfully"

###########################################################
# Finish
###########################################################
puts "CI BUILD SUCCESSFUL"
exit 0
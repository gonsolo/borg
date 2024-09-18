# Flash a Nitefury II with a bin file generated from Chipyard
# The following has been recorded manually by running a GUI version of Vivado
# and copying the commands from the Tcl Console.

open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
current_hw_device [get_hw_devices xc7a200t_0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xc7a200t_0] 0]
set_property PROBES.FILE {} [get_hw_devices xc7a200t_0]
set_property FULL_PROBES.FILE {} [get_hw_devices xc7a200t_0]
set_property PROGRAM.FILE {./out.bin} [get_hw_devices xc7a200t_0]
program_hw_devices [get_hw_devices xc7a200t_0]
refresh_hw_device [lindex [get_hw_devices xc7a200t_0] 0]
quit

write_cfgmem -format mcs -size 16 -interface SPIx4 -force -loadbit "up 0 ./project/project.runs/impl_1/Top_wrapper.bit" -file "./out.mcs"
write_cfgmem -format bin -size 16 -interface SPIx4 -force -loadbit "up 0 ./project/project.runs/impl_1/Top_wrapper.bit" -file "./out.bin"

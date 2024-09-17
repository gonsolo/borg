FREQUENCY = 50
STRATEGY = TIMING
RISCV = bla # Not needed, use spike-git package
FIRESIM_ENV_SOURCED = 1
FIRESIM = ./chipyard/sims/firesim
PLATFORM = rhsresearch_nitefury_ii
TARGET_PROJECT = firesim
DESIGN = FireSim
TARGET_CONFIG = BorgConfig
PLATFORM_CONFIG = BaseNitefuryConfig
QUINTUPLET = $(PLATFORM)-$(TARGET_PROJECT)-$(DESIGN)-$(TARGET_CONFIG)-$(PLATFORM_CONFIG)

# This is the SOC as System Verilog in one file
SV = $(FIRESIM)/sim/generated-src/$(PLATFORM)/$(QUINTUPLET)/$(DESIGN)-generated.sv

# The driver is a x86-64 binary that loads the linux kernel and a base image and runs the FPGA via PCI-Express.
DRIVER =$(FIRESIM)/sim/output/$(PLATFORM)/$(QUINTUPLET)/FireSim-rhsresearch_nitefury_ii

# Vivado MCS file: This is the bitstream the FPGA is programmed with
MCS = out.mcs

# The device tree
DTS = $(FIRESIM)/sim/generated-src/$(PLATFORM)/$(QUINTUPLET)/firesim.firesim.FireSim.BorgConfig.dts

all: driver

setup: #clean
	#git clone git@github.com:ucb-bar/chipyard.git
	#cd chipyard; git checkout -b 1.12.3 1.12.3
	#cd chipyard; git submodule update --init generators/bar-fetchers generators/boom generators/caliptra-aes-acc generators/constellation generators/diplomacy generators/fft-generator generators/hardfloat  generators/ibex generators/icenet generators/mempress generators/rocc-acc-utils generators/rocket-chip generators/rocket-chip-blocks generators/rocket-chip-inclusive-cache generators/shuttle generators/riscv-sodor generators/testchipip sims/firesim tools/cde 
	#cd chipyard; git submodule update --init generators/ara generators/compress-acc generators/cva6 generators/gemmini generators/nvdla generators/rerocc generators/saturn
	#cd chipyard/sims/firesim && git submodule update --init platforms/rhsresearch_nitefury_ii/NiteFury-and-LiteFury-firesim
	#cd chipyard; git submodule update --init --recursive tools/dsptools tools/fixedpoint tools/rocket-dsp-utils
	#cd chipyard; git submodule update --init --recursive tools/dsptools-chisel3 tools/fixedpoint-chisel3

driver: generate_env add_borg $(DRIVER)
$(SV) $(DRIVER):
	$(MAKE) -j $(shell nproc) -C $(FIRESIM)/sim RISCV=$(RISCV) FIRESIM_ENV_SOURCED=$(FIRESIM_ENV_SOURCED) PLATFORM=$(PLATFORM) TARGET_PROJECT=$(TARGET_PROJECT) DESIGN=$(DESIGN) TARGET_CONFIG=$(TARGET_CONFIG) PLATFORM_CONFIG=$(PLATFORM_CONFIG) replace-rtl

generate_env:
	./generate_env.sh

add_borg:
	./add_borg.sh

clean:
	rm -rf chipyard

.PHONY: add_borg all clean driver generate_env setup touch

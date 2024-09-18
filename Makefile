FREQUENCY = 50
STRATEGY = TIMING

# Install the spike-git package and add ~/lib/libfesvr.a and ~/lib/libriscv.so as links to the
# respective files in that package. RISCV can't be left empty as otherwise "make drive" will
# complain.
RISCV = ~

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

# The driver is a x86-64 binary that loads the linux kernel and a base image and runs the FPGA via
# PCI-Express.
DRIVER =$(FIRESIM)/sim/output/$(PLATFORM)/$(QUINTUPLET)/FireSim-rhsresearch_nitefury_ii

# Vivado MCS file: This is the bitstream the FPGA is programmed with
MCS = out.bin

# The device tree
DTS = $(FIRESIM)/sim/generated-src/$(PLATFORM)/$(QUINTUPLET)/firesim.firesim.FireSim.BorgConfig.dts

all: help

help:
	@echo "Targets:"
	@echo "1.     setup:          Clone all repositories and set them up."
	@echo "2.     driver:         Build the driver that's used to run the simulation."
	@echo "3.     mcs:            Build the bin file that's used to flash the FPGA."
	@echo "4.     program_device: Flash the FPGA with the hex file."
	@echo "Other: clean:          Clean up everything."

# Setup ###########################################################################################

SUBMODULES = generators/bar-fetchers generators/boom generators/caliptra-aes-acc \
	     generators/constellation generators/diplomacy generators/fft-generator \
	     generators/hardfloat  generators/ibex generators/icenet generators/mempress \
	     generators/rocc-acc-utils generators/rocket-chip generators/rocket-chip-blocks \
	     generators/rocket-chip-inclusive-cache generators/shuttle generators/riscv-sodor \
	     generators/testchipip sims/firesim tools/cde generators/ara generators/compress-acc \
	     generators/cva6 generators/gemmini generators/nvdla generators/rerocc generators/saturn
SUBMODULES_RECURSIVE = tools/dsptools tools/fixedpoint tools/rocket-dsp-utils \
		       tools/dsptools-chisel3 tools/fixedpoint-chisel3
CHIPYARD_VERSION = 1.12.3

setup: clean
	git clone git@github.com:ucb-bar/chipyard.git
	cd chipyard; git checkout -b $(CHIPYARD_VERSION) $(CHIPYARD_VERSION)
	cd chipyard; git submodule update --init $(SUBMODULES)
	cd chipyard/sims/firesim && git submodule update --init \
		platforms/rhsresearch_nitefury_ii/NiteFury-and-LiteFury-firesim
	cd chipyard; git submodule update --init --recursive $(SUBMODULES_RECURSIVE)

# Build Driver #####################################################################################

driver: generate_env patch_borg patch_tracerv $(DRIVER)
$(SV) $(DRIVER):
	$(MAKE) -j $(shell nproc) -C $(FIRESIM)/sim RISCV=$(RISCV) \
		FIRESIM_ENV_SOURCED=$(FIRESIM_ENV_SOURCED) PLATFORM=$(PLATFORM) \
		TARGET_PROJECT=$(TARGET_PROJECT) DESIGN=$(DESIGN) TARGET_CONFIG=$(TARGET_CONFIG) \
		PLATFORM_CONFIG=$(PLATFORM_CONFIG) replace-rtl

generate_env:
	./generate_env.sh
patch_borg:
	patch -d chipyard -p1 < borg.patch
patch_tracerv:
	patch -d chipyard/sims/firesim -p1 < tracerv.patch

# Build MCS ########################################################################################

PROJECT_0 = $(FIRESIM)/platforms/$(PLATFORM)/NiteFury-and-LiteFury-firesim/Sample-Projects/Project-0
HDL = project.srcs/sources_1/imports/HDL
PROJECT_0_HDL = $(PROJECT_0)/cl_firesim/Nitefury-II/project/$(HDL)

mcs: $(MCS)
$(MCS): $(DRIVER)
	ln -sf $(PROJECT_0)/cl_$(QUINTUPLET)/Nitefury-II/project/project.srcs .
	cp $(PROJECT_0)/cl_firesim/common/HDL/CodeBlinker.v $(HDL)
	cp $(PROJECT_0_HDL)/firesim_wrapper.v $(HDL)
	cp $(PROJECT_0_HDL)/dna_reader.v $(HDL)
	cp $(PROJECT_0_HDL)/user_efuse.v $(HDL)

	vivado -mode batch -source top.tcl -tclargs $(FREQUENCY) $(STRATEGY)

clean_logs:
	rm -f *.jou *.log

# Flash FPGA #######################################################################################

program_device:
	vivado_lab -mode tcl -source program.tcl

####################################################################################################

clean: clean_logs
	rm -rf chipyard project project.cache
	rm -f out.mcs $(MCS) out.prm project.srcs

.PHONY: add_borg all clean clean_logs driver generate_env mcs patch_tracerv setup touch

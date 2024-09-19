FEQUENCY = 50
STRATEGY = TIMING

# Install the spike-git package and add ~/lib/libfesvr.a and ~/lib/libriscv.so as links to the
# respective files in that package. RISCV can't be left empty as otherwise "make drive" will
# complain.
RISCV = ~

FIRESIM_ENV_SOURCED = 1

CHIPYARD = ./chipyard
SIMS = $(CHIPYARD)/sims
FIRESIM = $(SIMS)/firesim
FIRESIM_STAGING = $(SIMS)/firesim-staging
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
DTS = $(FIRESIM_STAGING)/generated-src/firesim.firesim.FireSim.BorgConfig/firesim.firesim.FireSim.BorgConfig.dts

all: help

help:
	@echo "Targets:"
	@echo "#      command    		description 						needs"
	@echo "1.     setup:     		Clone all repositories and set them up. 		-"
	@echo "2.     chipyard_patch		Patch chipyard with Borg. 				setup"
	@echo "3.     driver:    		Build the driver that's used to run the simulation. 	chipyard_patch"
	@echo "4.     mcs:       		Build the bin file that's used to flash the FPGA.FPG 	chipyard_patch"
	@echo "5.     program_dev		Flash the FPGA with the hex file. 			mcs"
	@echo "6.     dma_ip_drivers_install: 	Install XDMA drivers. 					setup"
	@echo "7.     xdma: 			Load xmda drivers. 					dma_ip_drivers_install"
	@echo "Other: clean:     		Clean up everything."

# Setup ###########################################################################################

SUBMODULES = generators/bar-fetchers generators/boom generators/caliptra-aes-acc \
	     generators/constellation generators/diplomacy generators/fft-generator \
	     generators/hardfloat  generators/ibex generators/icenet generators/mempress \
	     generators/rocc-acc-utils generators/rocket-chip generators/rocket-chip-blocks \
	     generators/rocket-chip-inclusive-cache generators/shuttle generators/riscv-sodor \
	     generators/testchipip sims/firesim tools/cde generators/ara generators/compress-acc \
	     generators/cva6 generators/gemmini generators/nvdla generators/rerocc generators/saturn
SUBMODULES_RECURSIVE = tools/dsptools tools/fixedpoint tools/rocket-dsp-utils \
		       tools/dsptools-chisel3 tools/fixedpoint-chisel3 software/firemarshal
CHIPYARD_VERSION = 1.12.3

setup: chipyard_setup dma_ip_drivers_setup

chipyard_setup:
	git clone git@github.com:ucb-bar/chipyard.git
	cd $(CHIPYARD); git checkout -b $(CHIPYARD_VERSION) $(CHIPYARD_VERSION)
	cd $(CHIPYARD); git submodule update -j 8 --init $(SUBMODULES)
	cd $(CHIPYARD)/sims/firesim && git submodule update --init \
		platforms/rhsresearch_nitefury_ii/NiteFury-and-LiteFury-firesim
	cd $(CHIPYARD); git submodule update -j 8 --init --recursive $(SUBMODULES_RECURSIVE)

# Miscellaneous ####################################################################################

ls_driver:
	ls -lh $(DRIVER)

edit_dts:
	vi $(DTS)

# XDMA ############################################################################################

dma_ip_drivers_setup:
	git clone git@github.com:gonsolo/dma_ip_drivers.git
	cd dma_ip_drivers; git checkout gonsolo

dma_ip_drivers_install:
	cd dma_ip_drivers/xdma/xdma; sudo make -j20 clean install

xdma:
ifneq ($(shell lsmod|grep xdma)xxx, xxx)
	sudo rmmod xdma
endif
	sudo modprobe xdma poll_mode=1 interrupt_mode=2
	sudo chmod a+rw /dev/xdma0_*

# Build Driver #####################################################################################

chipyard_patch: generate_env patch_borg patch_tracerv
chipyard_reset:
	cd $(CHIPYARD); git clean -df; git checkout .
	cd $(FIRESIM) && git checkout .

driver: chipyard_patch $(DRIVER)
$(SV) $(DRIVER):
	$(MAKE) -j $(shell nproc) -C $(FIRESIM)/sim RISCV=$(RISCV) \
		FIRESIM_ENV_SOURCED=$(FIRESIM_ENV_SOURCED) PLATFORM=$(PLATFORM) \
		TARGET_PROJECT=$(TARGET_PROJECT) DESIGN=$(DESIGN) TARGET_CONFIG=$(TARGET_CONFIG) \
		PLATFORM_CONFIG=$(PLATFORM_CONFIG) replace-rtl

generate_env:
	./generate_env.sh
patch_borg:
	patch -d $(CHIPYARD) -p1 < borg.patch
patch_borg_reverse:
	patch -d $(CHIPYARD) -R -p1 < borg.patch
patch_tracerv:
	patch -d $(FIRESIM) -p1 < tracerv.patch
patch_tracerv_reverse:
	patch -d $(FIRESIM) -R -p1 < tracerv.patch

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

# Kernel ##########################################################################################

FIREMARSHAL = $(CHIPYARD)/software/firemarshal
IMAGES_FIRECHIP = $(FIREMARSHAL)/images/firechip
BR_BASE = $(IMAGES_FIRECHIP)/br-base
BASE_IMG = $(BR_BASE)/br-base.img
BIN_DWARF = $(BR_BASE)/br-base-bin-dwarf
BASE_BIN = $(BR_BASE)/br-base-bin
BOARDS = $(FIREMARSHAL)/boards
DRIVERS = $(BOARDS)/firechip/drivers

distro: $(BASE_BIN) $(BASE_IMG)
$(BASE_BIN) $(BASE_IMG):
	cd $(FIREMARSHAL); ./marshal -v build br-base.json
clean_distro_kernel:
	rm -f $(BASE_BIN)
clean_distro:
	cd $(BOARDS)/default/linux; make mrproper
	cd $(DRIVERS)/icenet-driver; make clean
	cd $(DRIVERS)/iceblk-driver; make clean
update_distro: clean_distro clean_distro_kernel distro
# Compile manually:
# make ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- vmlinux


####################################################################################################

clean: clean_logs
	rm -rf $(CHIPYARD) project project.cache dma_ip_drivers
	rm -f out.mcs $(MCS) out.prm project.srcs


.PHONY: add_borg all chipyard_patch chipyard_reset clean clean_logs \
	dma_ip_drivers_setup edit_dts driver generate_env ls_driver mcs patch_borg \
	patch_borg_reverse patch_tracerv patch_tracerv_reverse setup touch xdma

# 1. Type "make" to get a list of targets. Run all these until you can run a simulation.
# 2. "make qemu_simulation" to run RISC-V Debian.
#    Inside is a Mesa (github.com:gonsolo/mesa) with a borg branch and a sample Vulkan application
#    (github.com:gonsolo/VulkanHpp-Compute-Sample). Compile both and install them.
# 3. Inside RISC-V Debian check Borg via "dmesg|grep borg"
#    Check whether there is a borg device in /sys/devices/platform/soc.
#    "make run_simulation", login with root, change to src/mesa/gonsolo dir and "make test_borg". 

# Debug DRM with: "echo 0x19F | sudo tee /sys/module/drm/parameters/debug" before make test_borg in run_simulation.

FREQUENCY = 50

STRATEGY = TIMING

# Install the spike-git package and add ~/lib/libfesvr.a and ~/lib/libriscv.so as links to the
# respective files in that package. RISCV can't be left empty as otherwise "make drive" will
# complain.
RISCV = ~

FIRESIM_ENV_SOURCED = 1

CHIPYARD = ./chipyard
SIMS = $(CHIPYARD)/sims
FIRESIM = $(SIMS)/firesim
FIREMARSHAL = $(CHIPYARD)/software/firemarshal
FIRESIM_STAGING = $(SIMS)/firesim-staging
PLATFORM = rhsresearch_nitefury_ii
TARGET_PROJECT = firesim
TARGET_PROJECT_MAKEFRAG = ../../../generators/firechip/chip/src/main/makefrag/firesim
DESIGN = FireSim
TARGET_CONFIG = BorgConfig
PLATFORM_CONFIG = BaseNitefuryConfig
QUINTUPLET = $(PLATFORM)-$(TARGET_PROJECT)-$(DESIGN)-$(TARGET_CONFIG)-$(PLATFORM_CONFIG)

# This is the SOC as System Verilog in one file
SV = $(FIRESIM)/sim/generated-src/$(PLATFORM)/$(QUINTUPLET)/$(DESIGN)-generated.sv

# The driver is a x86-64 binary that loads the linux kernel and a base image and runs the FPGA via
# PCI-Express.
DRIVER =$(FIRESIM)/sim/output/$(PLATFORM)/$(QUINTUPLET)/FireSim-rhsresearch_nitefury_ii

# This is the bitstream the FPGA is programmed with
BITSTREAM = out.bin

# The device tree
DTS = $(FIRESIM_STAGING)/generated-src/firechip.chip.FireSim.$(TARGET_CONFIG)/firechip.chip.FireSim.$(TARGET_CONFIG).dts

all: check_java help

help:
	@echo "Targets:"
	@echo " #      	command    		description 						needs 		time"
	@echo " 1.     	setup:     		Clone all repositories and set them up. 		- 		8m10s"
	@echo " 2.     	apply_patches: 		Patch chipyard with Borg. 				1 		<1s"
	@echo " 3.     	driver:    		Build the driver that's used to run the simulation. 	2 		2m30s"
	@echo " 4.     	bitstream: 		Build the file that's used to flash the FPGA. 		2 		73m"
	@echo " 5.     	distro: 		Make Linux kernel and bootloader. 			1 		5m"
	@echo " 6.     	xdma_install: 		Install XDMA drivers. 					1 		<1s"
	@echo " 7.     	program_device		Flash the FPGA with the hex file. 			4 		30s"
	@echo "-------------------------------- Reboot -----------------------------------------------------------------------------"
	@echo " 8.     	xdma_load:		Load xmda drivers. 					6 		<1s"
	@echo " 9.     	connect_debian: 	Connect the Debian image via nbd. 			1 		<1s"
	@echo "10.     	run_simulation:		Run simulation. 					3 5 7 8 9 	?"
	@echo "Other: --------------------------------------------------------------------------------------------------------------"
	@echo "11.     	disconnect_debian:     	Disconnect Debian. Necessary for qemu_debian"
	@echo "12.     	qemu_debian:     	Run Debian image via qemu. Much faster than simulation"
	@echo "13.     	clean:     		Clean up everything."
	@echo "14.     	clean_driver:     	Clean up driver."
	@echo "15.     	clean_bitstream:     	Clean up bitstream project files."
	@echo "16.     	clean_distro:     	Clean up distro."
	@echo "17.     	clean_distro_kernel:    Clean up distro kernel."
	@echo "18.     	1to7: 			Run commands 1 to 7."
	@echo "19.     	rclone_sync: 		Sync Debian image to Google Drive."

# Setup ###########################################################################################

CHIPYARD_VERSION = 1.13.0

CHIPYARD_SUBMODULES = generators/ara \
		      generators/bar-fetchers \
		      generators/boom \
		      generators/caliptra-aes-acc \
		      generators/compress-acc \
		      generators/constellation \
		      generators/cva6 \
		      generators/diplomacy \
		      generators/fft-generator \
		      generators/gemmini \
		      generators/hardfloat \
		      generators/ibex \
		      generators/icenet \
		      generators/mempress \
		      generators/nvdla \
		      generators/rerocc \
		      generators/riscv-sodor \
		      generators/rocc-acc-utils \
		      generators/rocket-chip \
		      generators/rocket-chip-blocks \
		      generators/rocket-chip-inclusive-cache \
		      generators/saturn \
		      generators/shuttle \
		      generators/testchipip \
		      generators/vexiiriscv \
		      sims/firesim \
		      tools/cde \
		      tools/firrtl2 \
		      software/firemarshal

CHIPYARD_SUBMODULES_RECURSIVE = tools/dsptools \
				tools/fixedpoint \
				tools/rocket-dsp-utils

FIREMARSHAL_SUBMODULES = boards/default/firmware/opensbi \
			 boards/default/distros/br/buildroot \
			 wlutil/busybox \
			 boards/firechip/drivers/icenet-driver \
			 boards/firechip/drivers/iceblk-driver

FIRESIM_SUBMODULES = sim/cde \
		     sim/rocket-chip \
		     sim/diplomacy \
		     sim/berkeley-hardfloat \
		     platforms/rhsresearch_nitefury_ii/NiteFury-and-LiteFury-firesim

setup: chipyard_setup distro_setup dma_ip_drivers_setup debian.qcow2

check_java: CheckJava.class
	@java CheckJava
CheckJava.class: CheckJava.java
	@javac $<

BORG_DIR = ./chipyard/generators/borg/src/main/scala

# Clone Chipyard and all submodules
chipyard_setup:
	git clone git@github.com:ucb-bar/chipyard.git
	cd $(CHIPYARD); git checkout -b $(CHIPYARD_VERSION) $(CHIPYARD_VERSION)
	cd $(CHIPYARD); git submodule update -j 25 --filter=tree:0 --depth=1 --init $(CHIPYARD_SUBMODULES)
	cd $(CHIPYARD); git submodule update -j 8 --filter=tree:0 --depth=1 --init --recursive $(CHIPYARD_SUBMODULES_RECURSIVE)
	cd $(FIRESIM) && git submodule update -j 5 --filter=tree:0 --depth=1 --init $(FIRESIM_SUBMODULES)
	cd $(FIREMARSHAL) && git submodule update -j 5 --filter=tree:0 --depth=1 --init $(FIREMARSHAL_SUBMODULES)
	cd $(CHIPYARD); git submodule add git@github.com:gonsolo/borg_generator.git generators/borg

# Miscellaneous ####################################################################################

ls_driver:
	@ls -lh $(DRIVER)

ls_sv:
	@ls -lh $(SV)

ls_kernel:
	@ls -lh $(LINUX)/vmlinux

edit_dts:
	vi $(DTS)

e: edit
edit:
	cd $(CHIPYARD); vi ./generators/borg/src/main/scala/Borg.scala

# XDMA ############################################################################################

# The xdma drivers are necessary to talk to the FPGA
dma_ip_drivers_setup:
	git clone git@github.com:gonsolo/dma_ip_drivers.git
	cd dma_ip_drivers; git checkout gonsolo

xdma_install:
	cd dma_ip_drivers/xdma/xdma; sudo make -j20 clean install

xdma_load:
ifneq ($(shell lsmod|grep xdma)xxx, xxx)
	sudo rmmod xdma
endif
	sudo modprobe xdma poll_mode=1 interrupt_mode=2
	sudo chmod a+rw /dev/xdma0_*

# Build Driver #####################################################################################

# This is the driver that runs on the host, loads the custom Linux kernel and Debian image, runs the
# bitstream on the FPGA and bridges requests from the FPGA.
driver: $(DRIVER)
$(SV) $(DRIVER):
	$(MAKE) \
		-j $(shell nproc) \
		-C $(FIRESIM)/sim \
		RISCV=$(RISCV) \
		FIRESIM_ENV_SOURCED=$(FIRESIM_ENV_SOURCED) \
		PLATFORM=$(PLATFORM) \
		TARGET_PROJECT=$(TARGET_PROJECT) \
		TARGET_PROJECT_MAKEFRAG=$(TARGET_PROJECT_MAKEFRAG) \
		DESIGN=$(DESIGN) \
		TARGET_CONFIG=$(TARGET_CONFIG) \
		PLATFORM_CONFIG=$(PLATFORM_CONFIG) \
		replace-rtl

generate_env:
	./generate_env.sh

# Build Bitstream  #################################################################################

PROJECT_0 = $(FIRESIM)/platforms/$(PLATFORM)/NiteFury-and-LiteFury-firesim/Sample-Projects/Project-0
HDL = project.srcs/sources_1/imports/HDL
PROJECT_0_HDL = $(PROJECT_0)/cl_firesim/Nitefury-II/project/$(HDL)

bitstream: $(BITSTREAM)
$(BITSTREAM): $(DRIVER)
	ln -sf $(PROJECT_0)/cl_$(QUINTUPLET)/Nitefury-II/project/project.srcs .
	cp $(PROJECT_0)/cl_firesim/common/HDL/CodeBlinker.v $(HDL)
	cp $(PROJECT_0_HDL)/firesim_wrapper.v $(HDL)
	cp $(PROJECT_0_HDL)/dna_reader.v $(HDL)
	cp $(PROJECT_0_HDL)/user_efuse.v $(HDL)

	vivado -mode batch -source top.tcl -tclargs $(FREQUENCY) $(STRATEGY)

clean_driver:
	rm -f $(SV) $(DRIVER)
	rm -rf $(PROJECT_0)/cl_$(PLATFORM)-$(TARGET_PROJECT)-$(DESIGN)-$(TARGET_CONFIG)-$(PLATFORM_CONFIG)

clean_bitstream:
	rm -rf project project.cache project.srcs

# Flash FPGA #######################################################################################

# You have to have a Nitefury II FPGA installed.
program_device:
	vivado -mode tcl -source program.tcl
	@echo "Please reboot after flashing Nitefury, otherwise it won't work!"

# Kernel ##########################################################################################

IMAGES_FIRECHIP = $(FIREMARSHAL)/images/firechip
BR_BASE = $(IMAGES_FIRECHIP)/br-base
BASE_BIN_DWARF = $(BR_BASE)/br-base-bin-dwarf
BASE_BIN = $(BR_BASE)/br-base-bin
BOARDS = $(FIREMARSHAL)/boards
LINUX = $(BOARDS)/default/linux
DRIVERS = $(BOARDS)/firechip/drivers

KERNEL_VERSION = firesim-v66-v6.11.5-borg

# Use our custom Linux kernel with Borg drivers.
distro_setup:
	cd $(BOARDS)/default; \
		git clone --filter=tree:0 --depth=1 --branch $(KERNEL_VERSION) --reference ~/src/linux git@github.com:gonsolo/linux.git; \

BUSYBOX = $(FIREMARSHAL)/wlutil/busybox

# Updating external repositories with submodules and sync to local changes is cumbersome (at least
# I didn't figure it out). Just use the original repository and patch everything in.
apply_patches: generate_env
	patch -d $(CHIPYARD)    		-p1 < chipyard.patch
	patch -d $(BUSYBOX) 			-p1 < busybox.patch
	patch -d $(FIRESIM) 			-p1 < firesim.patch
	patch -d $(DRIVERS)/icenet-driver 	-p1 < icenet.patch
	patch -d $(DRIVERS)/iceblk-driver 	-p1 < iceblk.patch
	patch -d $(FIREMARSHAL) 		-p1 < firemarshal.patch

reset_patches:
	cd $(CHIPYARD); git clean -df; git checkout .
	cd $(BUSYBOX) && git checkout .
	cd $(FIRESIM) && git checkout .
	cd $(DRIVERS)/icenet-driver && git checkout
	cd $(DRIVERS)/iceblk-driver && git checkout

refresh_patch:
	cd $(CHIPYARD); git diff --ignore-submodules > ../chipyard.patch

# Compile the kernel and bootloader into one file: $(BASE_BIN)
distro: $(BASE_BIN)
$(BASE_BIN):
	cd $(FIREMARSHAL); ./marshal -v build br-base.json
clean_distro_kernel:
	rm -f $(BASE_BIN)
clean_distro:
	cd $(LINUX); make mrproper
	cd $(DRIVERS)/icenet-driver; make clean
	cd $(DRIVERS)/iceblk-driver; make clean
pull_distro:
	cd $(LINUX); git pull; git show --summary
update_distro: clean_distro clean_distro_kernel distro
ls_distro:
	ls -lh $(BASE_BIN)
# Compile manually:
# make ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- vmlinux

####################################################################################################

NBD = /dev/nbd0
NBDP = /dev/nbd0p1

# A RISC-V debian.qcow2 image can be found here:
# https://drive.google.com/file/d/1JUwW6Wid5cio9gy35v-RlWJ_pRP9BcPs/view?usp=sharing
# It's built from https://people.debian.org/~gio/dqib and comes with Mesa and a simple Vulkan
# application for testing:
# https://github.com/gonsolo/mesa/tree/gonsolo
# https://github.com/gonsolo/VulkanHpp-Compute-Sample/tree/gonsolo
# Running the image to to /root/src/mesa/gonsolo and run "make test". This should run the test
# application with the custom Mesa driver.

# QCOW2 images can be run if connected via NBD.
connect_debian:
ifeq ($(shell lsmod|grep nbd)xxx, xxx)
	sudo modprobe nbd
endif
	sudo qemu-nbd --connect=$(NBD) debian.qcow2
	sleep 0.1
	sudo chmod a+rw $(NBDP)

disconnect_debian:
	sudo qemu-nbd --disconnect $(NBD)

DRIVER_FLAGS = +permissive +macaddr0=00:12:6D:00:00:02 +niclog0=niclog0 +blkdev-log0=blkdev-log0 \
        +trace-select=1 +trace-start=0 +trace-end=-1 +trace-output-format=0 \
        +dwarf-file-name=$(BASE_BIN_DWARF) +autocounter-readrate=0 \
        +autocounter-filename-base=AUTOCOUNTERFILE +print-start=0 +print-end=-1 +linklatency0=6405 \
        +netbw0=200 +shmemportname0=default +domain=0x0000 +bus=0x08 +device=0x00 +function=0x0 \
        +bar=0x0 +pci-vendor=0x10ee +pci-device=0x903f +permissive-off +prog0=$(BASE_BIN)

# Finally: Run the simulated hardware on the FPGA
# If everything is alright there should be a Borg device:
# /sys/devices/platform/soc/4000.borg-device
run_simulation:
	$(DRIVER) $(DRIVER_FLAGS) +blkdev0=$(NBDP)

# Since running a simulation is fairly slow (5 minutes to boot prompt), better run the Debian image
# with qemu to update/compile/install Mesa.
qemu_debian:
	qemu-system-riscv64 -machine 'virt' -cpu 'rv64' -smp cores=12,threads=2 -m 16G -device virtio-blk-device,drive=hd -drive file=debian.qcow2,if=none,id=hd -device virtio-net-device,netdev=net -netdev user,id=net,hostfwd=tcp::2222-:22 -kernel /usr/share/u-boot-qemu-bin/qemu-riscv64_smode/uboot.elf -object rng-random,filename=/dev/urandom,id=rng -device virtio-rng-device,rng=rng -nographic -append "root=LABEL=rootfs console=ttyS0"
# SSH: ssh root@localhost -p 2222
# FTP: sftp -P 2222 root@localhost

# Compress and sync Debian image for storing in Google Drive
debian.qcow2.gz:
	gzip --verbose --keep --rsyncable debian.qcow2
rclone_sync: debian.qcow2.gz
	rclone sync --interactive debian.qcow2.gz remote:
# If there is no Debian image, get it from Google Drive
debian.qcow2:
	rclone copy --interactive remote:debian.qcow2.gz .
	gunzip debian.qcow2.gz

clean_logs:
	rm -f *.jou *.log

clean: clean_logs
	rm -rf $(CHIPYARD) project project.cache dma_ip_drivers
	rm -f out.mcs $(BITSTREAM) out.prm project.srcs
	rm -rf xsim.dir .Xil
	rm CheckJava.class

# All steps that can be done automatically after cloning
1to7: setup apply_patches driver bitstream distro xdma_install program_device

.PHONY: all apply_patches bitstream check_java chipyard_setup clean clean_bitstream clean_driver \
	clean_logs connect_debian disconnect_debian distro_setup dma_ip_drivers_setup edit_dts \
	driver generate_env help ls_distro ls_driver qemu_debian rclone_sync reset_patches \
	run_simulation setup

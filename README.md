# Borg Graphics

DIY graphics hardware.

Type `make help` to show a list of steps to build your own graphics hardware, including a SOC, Linux
kernel including kernel driver, user space graphics driver, FPGA simulators, and a software
simulator based on verilator.

## Sources

1. The umbrella project is found at github.com:gonsolo/borg
2. A Mesa 3D user driver is located at https://github.com/gonsolo/mesa.
3. The Kernel driver is at https://github.com/gonsolo/linux.
4. The Vulkan sample application is at https://github.com/gonsolo/VulkanHpp-Compute-Sample.

## Components:
1. Hardware: After applying chipyard.patch the hardware is located at `chipyard/generators/borg`.
2. Kernel driver: At setup time it is downloaded from github.com/gonsolo/linux.
3. Mesa driver: Must be downloaded from github.com/gonsolo/mesa and compiled within the RISC-V
   image (debian.qcow2).

The sample application also has to be downloaded and compiled in the RISC-V image (debian.qcow2).

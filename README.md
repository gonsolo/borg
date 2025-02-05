# Borg Graphics

DIY graphics hardware.

Type `make help` to show a list of steps to build your own graphics hardware, including a SOC, Linux
kernel including kernel driver, user space graphics driver, FPGA simulators, and a software
simulator based on verilator.

## Sources

1. The umbrella project including the graphics hardware is found at https://github.com/gonsolo/borg
2. A Mesa 3D user space Vulkan driver is located at https://github.com/gonsolo/mesa.
3. The Kernel driver is at https://github.com/gonsolo/linux.
4. The Vulkan sample application is at https://github.com/gonsolo/VulkanHpp-Compute-Sample.

## Components:

1. Hardware: After applying chipyard.patch the hardware is located at `chipyard/generators/borg`.
2. Kernel driver: At setup time it is downloaded from github.com/gonsolo/linux.
3. Mesa driver: Must be downloaded from github.com/gonsolo/mesa and compiled within a RISC-V
   image (there is one with Mesa and the sample application installed at
   [debian.qcow2](https://drive.google.com/file/d/14fKEoJLiGNPCvdXPLr-cDweYWolDfrjg/view?usp=drive_link)).

The sample application also has to be downloaded and compiled in the RISC-V image.

## Based on:

1. [Chipyard](https://chipyard.readthedocs.io)
2. [Linux](https://kernel.org)
3. [Mesa](https://mesa3d.org)

## Past and Future

### What works
* Running a sample Vulkan application within a RISC-V image in an FPGA Simulation non-functional without crashing.
* Reading registers in bare-metal software simulation as well as from the kernel driver in an FPGA simulation.

### Next steps
1. Run sample application correctly.
   - DMA upload of shader.
   - Run shader.
   - DMA download of result buffer.
2. Render triangle
   - Run vertex and triangle shaders.
   - DMA download of framebuffer.

Copyright 2025 Andreas Wendleder

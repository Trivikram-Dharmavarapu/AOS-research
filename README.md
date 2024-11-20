# EXT FUSE Setup and Testing

This guide provides steps to set up EXT FUSE on a Virtual Machine (VM) and test SLIM and FAT containers using Docker.

---

## Prerequisites

- Linux-based Virtual Machine (e.g., Ubuntu 22.04)
- Minimum VM specifications:
  - 2 CPUs, 4 GB RAM, 50 GB disk space
- Required tools:
  
  ```bash
  sudo apt update
  sudo apt install -y build-essential git curl clang llvm cmake \
      linux-headers-$(uname -r) libncurses5-dev libssl-dev bison flex fuse libfuse2 docker.io
  ```

## Step 1: Configure the Kernel

1. Configure the kernel:

   ```bash
   make menuconfig
   ```

   Navigate to:
   - General Setup → Enable [*] bpf() system call.
   - File Systems:
     - Enable <*> FUSE (Filesystem in Userspace) support.
     - Enable [*] Extension framework for FUSE.

   **Important**: Ensure FUSE is built into the kernel (`<*>`).

2. Build and install the kernel:

   ```bash
   make -j$(nproc)
   sudo make install -j$(nproc)
   make headers_install INSTALL_HDR_PATH=/usr/local/include
   ```

3. Reboot into the new kernel:

   ```bash
   sudo reboot
   ```

4. Verify the kernel version:

   ```bash
   uname -r
   ```

## Step 2: Build EXT FUSE

1. Clone the EXT FUSE repository:

   ```bash
   git clone https://github.com/extfuse/extfuse
   cd extfuse
   ```

2. Build EXT FUSE:

   ```bash
   export EXTFUSE_REPO_PATH=$(pwd)
   LLC=llc-3.8 CLANG=clang-3.8 make
   ```

3. Verify the build:

   ```bash
   ls $EXTFUSE_REPO_PATH/src/extfuse.o
   ```

## Step 3: Build the Modified libFUSE

1. Clone the libFUSE repository:

   ```bash
   git clone --branch ExtFUSE-1.0 https://github.com/extfuse/libfuse
   cd libfuse
   ```

2. Build libFUSE:

   ```bash
   ./makeconf.sh
   ./configure
   make -j$(nproc)
   sudo make install
   ```

## Step 4: Test EXT FUSE with StackFS

1. Clone and build StackFS:

   ```bash
   git clone https://github.com/ashishbijlani/StackFS
   cd StackFS
   make
   ```

2. Set up directories:

   ```bash
   mkdir /mnt/test-lower /mnt/test-upper /mnt/test-work /mnt/test-merged
   ```

3. Run StackFS:

   ```bash
   cp $EXTFUSE_REPO_PATH/bpf/extfuse.o /tmp/.
   sudo sh -c "LD_LIBRARY_PATH=$EXTFUSE_REPO_PATH ./StackFS_ll -o max_write=131072 -o writeback_cache -o splice_read -o splice_write -o splice_move -r /mnt/test-lower /mnt/test-merged -o allow_other"
   ```

4. Test functionality:

   ```bash
   echo "Hello, EXT FUSE!" > /mnt/test-upper/testfile.txt
   ls /mnt/test-merged
   cat /mnt/test-merged/testfile.txt
   ```

## Step 5: Contextual Integration of EXT FUSE and CNTR with SLIM/FAT Containers

### 1. EXT FUSE in the VM

EXT FUSE provides an extension framework for the FUSE (Filesystem in Userspace) interface. This is configured and tested on the VM to ensure the kernel supports it. The StackFS file system and the EXT FUSE framework ensure that the modified kernel-level FUSE driver and user-space EXT FUSE library work correctly. After verifying the EXT FUSE functionality with the StackFS file system on the VM, we move to test its interaction with containers.

### 2. CNTR with SLIM and FAT Containers

CNTR is used to attach containers, enabling shared runtime resources and debugging workflows. Using SLIM (lightweight) and FAT (debug-heavy) containers, we simulate scenarios where EXT FUSE can be tested for performance and resource-sharing capabilities. EXT FUSE’s functionality can be indirectly tested by:

- Mounting EXT FUSE-backed file systems (e.g., StackFS) in SLIM/FAT containers.
- Using CNTR to attach and share file systems across SLIM/FAT containers.
- Running tests in containers that stress EXT FUSE operations.

### How to Test EXT FUSE with CNTR and SLIM/FAT Containers

#### Setup EXT FUSE-Backed File System in the VM:

1. Ensure EXT FUSE and StackFS are configured and tested on the VM as outlined in Step 4 of the EXT FUSE setup.
2. Mount the EXT FUSE-backed StackFS file system to a directory, e.g., `/mnt/extfuse-test`.

#### Expose the EXT FUSE File System to Docker:

1. Start Docker with access to the EXT FUSE file system:

   ```bash
   sudo docker run --privileged -v /mnt/extfuse-test:/mnt/extfuse-test -d --name docker-host docker:dind
   ```

   This step ensures that containers can access the EXT FUSE-backed file system.

#### Build SLIM and FAT Containers:

1. Build the SLIM and FAT containers as described in Step 5 using Dockerfile.slim and Dockerfile.fat.

#### Test SLIM Container:

1. Run the SLIM container and mount the EXT FUSE file system:

   ```bash
   docker run -d --name slim-container -v /mnt/extfuse-test:/mnt/test slim-image
   ```

2. Inside the SLIM container, test EXT FUSE functionality:

   ```bash
   docker exec slim-container ls /mnt/test
   docker exec slim-container cat /mnt/test/testfile.txt
   ```

#### Test FAT Container:

1. Run the FAT container and mount the EXT FUSE file system:

   ```bash
   docker run -d --name fat-container -v /mnt/extfuse-test:/mnt/test fat-image
   ```

#### Attach SLIM and FAT Containers with CNTR:

1. Use CNTR to attach the SLIM and FAT containers:

   ```bash
   cntr attach slim-container fat-container
   ```

2. Verify EXT FUSE functionality in the shared runtime by performing read/write tests from both containers:

   ```bash
   docker exec slim-container echo "Updated from SLIM" >> /mnt/test/testfile.txt
   docker exec fat-container cat /mnt/test/testfile.txt
   ```

#### Run Performance and Debugging Tests:

1. Use the mounted EXT FUSE file system for Phoronix and SQLite tests as described in Step 5 of the SLIM and FAT container testing guide.

#### Containerized File System Testing:

EXT FUSE is designed to optimize and extend FUSE file systems. By mounting EXT FUSE-backed file systems in SLIM and FAT containers, you validate its real-world application in isolated and resource-constrained environments.

#### CNTR for Shared Runtime:

CNTR enables the sharing of runtime resources (e.g., EXT FUSE file systems) between containers, making it easier to test scenarios where multiple containers interact with the same file system.

#### Debugging and Performance:

FAT containers provide debugging tools, while SLIM containers focus on lightweight performance testing. This dichotomy allows you to test EXT FUSE under both production-like and development/debugging conditions.

## Step 6: End-to-End Workflow Summary

### VM Setup:

- Configure and verify EXT FUSE and StackFS functionality.
- Mount the EXT FUSE-backed file system.

### Container Setup:

- Build SLIM and FAT containers.
- Run containers with access to the EXT FUSE-backed file system.

### CNTR Testing:

- Attach SLIM and FAT containers using CNTR.
- Verify EXT FUSE functionality in shared runtime scenarios.

### Performance and Debugging:

- Run Phoronix and SQLite tests within the containers.

### Clean Up:

1. Stop and remove all containers:

   ```bash
   docker stop slim-container fat-container
   docker rm slim-container fat-container
   ```

2. Unmount EXT FUSE-backed file systems:

   ```bash
   rm -rf /mnt/test-lower /mnt/test-upper /mnt/test-work /mnt/test-merged
   ```

## References

- [EXT FUSE Documentation](https://github.com/extfuse/extfuse)
- [USENIX ATC '19 Paper](https://www.usenix.org/conference/atc19/presentation/bijlani)

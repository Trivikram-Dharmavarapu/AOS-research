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

## Step 5: Testing SLIM and FAT Containers Using Docker

### Step 1: Create Dockerfiles

**Dockerfile.slim**

```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y sqlite3 phoronix-test-suite
COPY workload.sh /workload.sh
CMD ["sqlite3"]
```

**Dockerfile.fat**

```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y gdb strace lsof net-tools vim
CMD ["bash"]
```

### Step 2: Build and Run Containers

1. Build the SLIM container:

   ```bash
   docker build -t slim-image -f Dockerfile.slim .
   ```

2. Build the FAT container:

   ```bash
   docker build -t fat-image -f Dockerfile.fat .
   ```

3. Run the SLIM container:

   ```bash
   docker run -d --name slim-container slim-image
   ```

4. Run the FAT container and attach it to the SLIM container:

   ```bash
   docker run -d --name fat-container fat-image
   cntr attach slim-container fat-container
   ```

### Step 3: Run Tests

**Phoronix Test**

1. Run the batch setup:

   ```bash
   docker exec -it slim-container phoronix-test-suite batch-setup
   ```

2. Execute the SLIM tests:

   ```bash
   ./run_slim_tests.sh
   ```

**SQLite Test**

1. Execute tests for SLIM:

   ```bash
   docker exec slim-container /usr/bin/time -v /workload.sh > ./slim_results/slim_sqlite.log 2>&1
   ```

2. Execute tests for SLIM + FAT:

   ```bash
   docker exec slim-container /usr/bin/time -v /workload.sh > ./slim_fat_results/slim_with_fat.log 2>&1
   ```

### Step 4: Clean Up

1. Stop and remove containers:

   ```bash
   docker stop slim-container fat-container
   docker rm slim-container fat-container
   ```

2. Remove test directories:

   ```bash
   rm -rf /mnt/test-lower /mnt/test-upper /mnt/test-work /mnt/test-merged
   ```

## References

- [EXT FUSE Documentation](https://github.com/extfuse/extfuse)
- [USENIX ATC '19 Paper](https://www.usenix.org/conference/atc19/presentation/bijlani)

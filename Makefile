SHELL := bash -O extglob
ASM=nasm
LD=ld

SRC_DIR=src
BUILD_DIR=build

all: executable

#
# Remove all build artifacts
#
clean: 
	rm -rf $(BUILD_DIR)

#
# Build and run the executable withj gdb
#
debug: executable
	gdb -ix gdb_init.txt $(BUILD_DIR)/aws


#
# Ensures that the build directory exists
#
build_dir: $(BUILD_DIR)
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

#
# Assemble executable
#
executable: $(BUILD_DIR)/aws
$(BUILD_DIR)/aws: build_dir $(SRC_DIR)/*.asm 
	$(ASM) -g -i$(SRC_DIR)/ $(SRC_DIR)/main.asm -f elf64 -o $(BUILD_DIR)/aws.o
	$(LD) -o $(BUILD_DIR)/aws $(BUILD_DIR)/aws.o 

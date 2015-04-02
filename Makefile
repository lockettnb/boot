#
# 2015/03/20 created
# 2015/03/25 convert script to makefile


all:	drive.bin

# assembly MBR boot code into "raw" binary 
boot.bin:	boot.S
	nasm boot.S -f bin -o boot.bin

# assembly the kernel bootstrap code into elf format
bootstrap.o:	bootstrap.S isr.S
	i686-elf-gcc -c  bootstrap.S  -o bootstrap.o

# compile the C kernel code into elf format
kernel.o:	kernel.c
	i686-elf-gcc -c kernel.c -o kernel.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra

isr.o:	isr.c
	i686-elf-gcc -c isr.c -o isr.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra

vgaconsole.o:	vgaconsole.c
	i686-elf-gcc -c vgaconsole.c -o vgaconsole.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra

# link the bootstrap and kernel code into one elf file
os.elf:	bootstrap.o kernel.o vgaconsole.o isr.o linker.ld
	i686-elf-gcc -T linker.ld -o os.elf -ffreestanding -O2 -nostdlib bootstrap.o kernel.o vgaconsole.o isr.o -lgcc

os.bin:	os.elf
	objcopy -O binary os.elf os.bin

# write the boot program to the first sector on the fake disk drive
# write the kernel program to the second sector on the fake disk drive
drive.bin: boot.bin os.bin
	dd if=/dev/zero of=drive.bin bs=512 count=16
	dd if=boot.bin of=drive.bin bs=512 conv=notrunc
	dd if=os.bin of=drive.bin bs=512 seek=1 conv=notrunc

clean:	
	rm boot.bin bootstrap.o kernel.o isr.o vgaconsole.o
	rm os.elf 
	rm os.bin drive.bin
	rm -rf drive.vdi

vbox:
	rm -rf drive.vdi
	VBoxManage convertfromraw drive.bin drive.vdi --format VDI 
	VBoxManage storageattach boot --storagectl "IDE Controller" --port 0 --device 0 --type hdd --medium none
	cd /home/john/VirtualBox\ VMs/boot
	VBoxManage closemedium disk /home/john/VirtualBox\ VMs/boot/drive.vdi
	cp /home/john/src/pc_boot/boot5/drive.vdi /home/john/VirtualBox\ VMs/boot/drive.vdi
	VBoxManage storageattach boot --storagectl "IDE Controller" --port 0 --device 0 --type hdd --medium drive.vdi

#	VBoxManage internalcommands setvdiuuid 6f0f2c58-9539-40e1-923f-e69977f830b9 drive.vdi


# assembly MBR boot code into "raw" binary 
# nasm boot.S -f bin -o boot.bin
# nasm k.S -f bin -o k.bin

# assembly the kernel bootstrap code into elf format
#i686-elf-as bootstrap.S -o bootstrap.o
# nasm bootstrap.S -f elf  -o bootstrap.o

# compile the C kernel code into elf format
# i686-elf-gcc -c kernel.c -o kernel.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra

# link the bootstrap and kernel code into one elf file
# i686-elf-gcc -T linker.ld -o os.elf -ffreestanding -O2 -nostdlib bootstrap.o kernel.o -lgcc
# objcopy -O binary os.elf os.bin



# fake.bin is 16 sector data to "fake" a  disk drive 
# this data was generated with a perl script
# cp fake.bin drive.bin
#   Another option is to use dd and fill the sectors with zeros
#   dd if=/dev/zero of=fake.bin bs=512 count=16

# write the boot program to the first sector on the fake disk drive
# dd if=boot.bin of=drive.bin bs=512 conv=notrunc

# write the kernel program to the second sector on the fake disk drive
# dd if=os.bin of=drive.bin bs=512 seek=1 conv=notrunc

# test using the QEMU emulator
# kvm -hda drive.bin

# convert raw disk image to VirtualBox VDI format
# VBoxManage convertfromraw drive.bin drive.vdi --format VDI


# dd if=/dev/zero of=floppy.bin bs=512 count=12
# dd if=/dev/zero of=floppy.bin bs=1440k count=1


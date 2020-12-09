#!/bin/bash
rm *.o
rm *.iso
rm *.bin
rm -rf isodir
as boot.s -o boot.o --32
as kernel.s -o kernel.o --32
if [ "$1" == "--debug" ]
then
	gcc -T linker.ld -o myos.bin -ffreestanding -g3 -nostdlib boot.o kernel.o -lgcc -m32
else
	gcc -T linker.ld -o myos.bin -ffreestanding -O2 -nostdlib boot.o kernel.o -lgcc -m32
fi
if grub-file --is-x86-multiboot myos.bin; then
  echo multiboot confirmed
else
  echo the file is not multiboot
  exit 1
fi
mkdir -p isodir/boot/grub
cp myos.bin isodir/boot/myos.bin
cp grub.cfg isodir/boot/grub/grub.cfg
grub-mkrescue -o myos.iso isodir
if [ "$1" == "--debug" ]
then
	if [ "$2" == "--gdb" ]
	then
		qemu-system-i386 -S -gdb tcp::9000 -cdrom myos.iso
	else
		qemu-system-i386 -cdrom myos.iso
	fi
else
	qemu-system-i386 -cdrom myos.iso
fi

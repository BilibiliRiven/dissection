all: lib_32.so lib_elf32.so

%_elf32.so: %_elf32.asm
	nasm -f bin -o $@ $<
	chmod +x $@

%_32.o: %_32.asm
	nasm -f elf32 -o $@ $<

%_64.o: %_64.asm
	nasm -f elf64 -o $@ $<

%_32.so: %_32.o
	ld -m elf_i386 -shared -Ttext-segment=0x00400000 -I /lib/ld-linux.so.2 -s -o $@ -L/usr/lib32 $<
	strip -R .hash $@
	#strip -R .gnu.hash $@
	strip -R .gnu.version $@
	#strip -R .eh_frame $@
	strip -R .shstrtab $@

%_64.so: %_64.o
	ld -shared -I /lib64/ld-linux-x86-64.so.2 -s -o $@ $< -lc
	strip -R .hash $@
	strip -R .gnu.hash $@
	strip -R .gnu.version $@
	strip -R .eh_frame $@
	strip -R .shstrtab $@

.PHONY: all clean

clean:
	$(RM) -v *.o
	$(RM) -v hello_32 hello_64
	$(RM) -v hello_elf32

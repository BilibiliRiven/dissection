BITS 32

%define round(n, r)     (((n + (r - 1)) / r) * r)

; Base addresses.
BASE           equ 0x0
PAGE           equ 0x1000
BASE_R_SEG     equ BASE
BASE_X_SEG     equ BASE_R_SEG + round(r_seg.size, PAGE)
BASE_RDATA_SEG equ BASE_X_SEG + round(x_seg.size, PAGE)
BASE_RW_SEG    equ BASE_RDATA_SEG + 0xFA0

; ___ [ Read-only segment ] ____________________________________________________

SECTION .r_seg vstart=BASE_R_SEG align=1

r_seg_off equ 0

r_seg:

; === [ ELF file header ] ======================================================

; ELF classes.
ELFCLASS32 equ 1 ; 32-bit architecture.

; Data encodings.
ELFDATA2LSB equ 1 ; 2's complement little-endian.

; Object file types.
ET_EXEC equ 2 ; Executable.
ET_DYN  equ 3 ; Shared object.

; CPU architectures.
EM_386 equ 3 ; Intel i386.

_text.start equ 0x00001000 ; TODO: remove

shdr_off equ 0x3040 ; TODO: remove
shdr.entsize equ 0x28 ; TODO: remove
shdr.count equ 0x08 ; TODO: remove
shdr.shstrtab_idx equ 0x07 ; TODO: remove

ehdr:

	db      0x7F, "ELF"               ; ident.magic: ELF magic number.
	db      ELFCLASS32                ; ident.class: File class.
	db      ELFDATA2LSB               ; ident.data: Data encoding.
	db      1                         ; ident.version: ELF header version.
	db      0, 0, 0, 0, 0, 0, 0, 0, 0 ; ident.pad: Padding.
	dw      ET_DYN                    ; type: File type.
	dw      EM_386                    ; machine: Machine architecture.
	dd      1                         ; version: ELF format version.
	dd      _text.start               ; entry: Entry point.
	dd      phdr_off                  ; phoff: Program header file offset.
	dd      shdr_off                  ; shoff: Section header file offset.
	dd      0                         ; flags: Architecture-specific flags.
	dw      ehdr.size                 ; ehsize: Size of ELF header in bytes.
	dw      phdr.entsize              ; phentsize: Size of program header entry.
	dw      phdr.count                ; phnum: Number of program header entries.
	dw      shdr.entsize              ; shentsize: Size of section header entry.
	dw      shdr.count                ; shnum: Number of section header entries.
	dw      shdr.shstrtab_idx         ; shstrndx: Section name strings section.

.size equ $ - ehdr

; === [/ ELF file header ] =====================================================

; === [ Program headers ] ======================================================

; Segment types.
PT_LOAD    equ 1 ; Loadable segment.
PT_DYNAMIC equ 2 ; Dynamic linking information segment.
PT_INTERP  equ 3 ; Pathname of interpreter.

; Segment flags.
PF_R equ 0x4 ; Readable.
PF_W equ 0x2 ; Writable.
PF_X equ 0x1 ; Executable.

phdr_off equ phdr - BASE_R_SEG

phdr:

; --- [ Read-only segment program header ] -------------------------------------

;  Type           Offset   VirtAddr   PhysAddr   FileSiz MemSiz  Flg Align
;  LOAD           0x000000 0x00000000 0x00000000 0x0014d 0x0014d R   0x1000

  .r_seg:
	dd      PT_LOAD    ; type: Segment type
	dd      r_seg_off  ; offset: Segment file offset
	dd      r_seg      ; vaddr: Segment virtual address
	dd      r_seg      ; paddr: Segment physical address
	dd      r_seg.size ; filesz: Segment size in file
	dd      r_seg.size ; memsz: Segment size in memory
	dd      PF_R       ; flags: Segment flags
	dd      PAGE       ; align: Segment alignment

.entsize equ $ - phdr

; --- [ Executable segment program header ] ------------------------------------

;  Type           Offset   VirtAddr   PhysAddr   FileSiz MemSiz  Flg Align
;  LOAD           0x001000 0x00001000 0x00001000 0x00006 0x00006 R E 0x1000

  .x_seg:
	dd      PT_LOAD     ; type: Segment type
	dd      x_seg_off   ; offset: Segment file offset
	dd      x_seg       ; vaddr: Segment virtual address
	dd      x_seg       ; paddr: Segment physical address
	dd      x_seg.size  ; filesz: Segment size in file
	dd      x_seg.size  ; memsz: Segment size in memory
	dd      PF_R | PF_X ; flags: Segment flags
	dd      PAGE        ; align: Segment alignment

; --- [ .rdata segment program header ] ----------------------------------------

;  Type           Offset   VirtAddr   PhysAddr   FileSiz MemSiz  Flg Align
;  LOAD           0x002000 0x00002000 0x00002000 0x00000 0x00000 R   0x1000

  .rdata_seg:
	dd      PT_LOAD        ; type: Segment type
	dd      rdata_seg_off  ; offset: Segment file offset
	dd      rdata_seg      ; vaddr: Segment virtual address
	dd      rdata_seg      ; paddr: Segment physical address
	dd      rdata_seg.size ; filesz: Segment size in file
	dd      rdata_seg.size ; memsz: Segment size in memory
	dd      PF_R           ; flags: Segment flags
	dd      PAGE           ; align: Segment alignment

; --- [ Read-write segment program header ] ------------------------------------

;  Type           Offset   VirtAddr   PhysAddr   FileSiz MemSiz  Flg Align
;  LOAD           0x002fa0 0x00002fa0 0x00002fa0 0x00060 0x00060 RW  0x1000

  .rw_seg:
	dd      PT_LOAD     ; type: Segment type
	dd      rw_seg_off  ; offset: Segment file offset
	dd      rw_seg      ; vaddr: Segment virtual address
	dd      rw_seg      ; paddr: Segment physical address
	dd      rw_seg.size ; filesz: Segment size in file
	dd      rw_seg.size ; memsz: Segment size in memory
	dd      PF_R | PF_W ; flags: Segment flags
	dd      PAGE        ; align: Segment alignment

; --- [ Dynamic array program header ] -----------------------------------------

;  Type           Offset   VirtAddr   PhysAddr   FileSiz MemSiz  Flg Align
;  DYNAMIC        0x002fa0 0x00002fa0 0x00002fa0 0x00060 0x00060 RW  0x4

  .dynamic:
	dd      PT_DYNAMIC    ; type: Segment type
	dd      dynamic_off   ; offset: Segment file offset
	dd      dynamic       ; vaddr: Segment virtual address
	dd      dynamic       ; paddr: Segment physical address
	dd      dynamic.size  ; filesz: Segment size in file
	dd      dynamic.size  ; memsz: Segment size in memory
	dd      PF_R | PF_W   ; flags: Segment flags
	dd      dynamic_align ; align: Segment alignment

.size  equ $ - phdr
.count equ .size / .entsize

; === [/ Program headers ] =====================================================

; 000000d4
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; |................|
; 000000e0
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; |................|
; 000000f0
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; |................|
; 00000100
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00 ; |................|
; 00000110
db 0x01, 0x00, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00 ; |................|
; 00000120
db 0x01, 0x00, 0x00, 0x00, 0x89, 0x73, 0x88, 0x0b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; |.....s..........|
; 00000130
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00 ; |................|
; 00000140
db 0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x05, 0x00, 0x00, 0x66, 0x6f, 0x6f, 0x00                   ; |.........foo.|

r_seg.size equ $ - r_seg

align PAGE, db 0x00

; ___ [/ Read-only segment ] ___________________________________________________

; ___ [ Executable segment ] ___________________________________________________

SECTION .x_seg vstart=BASE_X_SEG follows=.r_seg align=1

x_seg_off equ r_seg_off + round(r_seg.size, PAGE)

x_seg:

; 00001000
db 0xb8, 0x2a, 0x00, 0x00, 0x00, 0xc3 ; |.*....|

x_seg.size equ $ - x_seg

align PAGE, db 0x00

; ___ [/ Executable segment ] __________________________________________________

; ___ [ .rdata segment? ] ______________________________________________________

SECTION .rdata_seg vstart=BASE_RDATA_SEG follows=.x_seg align=1

rdata_seg_off equ x_seg_off + round(x_seg.size, PAGE)

rdata_seg:

; .rdata segment contains no data.

rdata_seg.size equ $ - rdata_seg

times (0x2FA0 - 0x2000) db 0x00 ; padding

; ___ [/ .rdata segment? ] _____________________________________________________

; ___ [ Read-write segment ] ___________________________________________________

SECTION .rw_seg vstart=BASE_RW_SEG follows=.rdata_seg align=1

rw_seg_off equ rdata_seg_off + 0xFA0

rw_seg:

; --- [ .dynamic section ] -----------------------------------------------------

; Dynamic tags.
DT_NULL     equ 0          ; Terminating entry.
DT_NEEDED   equ 1          ; String table offset of a needed shared library.
DT_HASH     equ 4          ; Address of symbol hash table.
DT_PLTGOT   equ 3          ; Processor-dependent address.
DT_STRTAB   equ 5          ; Address of string table.
DT_SYMTAB   equ 6          ; Address of symbol table.
DT_STRSZ    equ 10         ; Size of string table.
DT_SYMENT   equ 11         ; Size of each symbol table entry.
DT_JMPREL   equ 23         ; Address of PLT relocations.
DT_GNU_HASH equ 0x6FFFFEF5 ; Address of GNU symbol hash table.

dynamic_align equ 4

align dynamic_align, db 0x00

dynamic_off equ dynamic - BASE_R_SEG

dynamic:

;  Tag        Type                         Name/Value
; 0x00000004 (HASH)                       0xf4

hash equ 0xf4 ; TODO: remove

  .hash:
	dd      DT_HASH ; tag: Entry type.
	dd      hash    ; val: Integer/Address value.

.entsize equ $ - dynamic

;  Tag        Type                         Name/Value
; 0x6ffffef5 (GNU_HASH)                   0x108

gnu_hash equ 0x108 ; TODO: remove

  .gnu_hash:
	dd      DT_GNU_HASH ; tag: Entry type.
	dd      gnu_hash    ; val: Integer/Address value.

;  Tag        Type                         Name/Value
; 0x00000005 (STRTAB)                     0x148

dynstr equ 0x148 ; TODO: remove

  .strtab:
	dd      DT_STRTAB ; tag: Entry type.
	dd      dynstr    ; val: Integer/Address value.

;  Tag        Type                         Name/Value
; 0x00000006 (SYMTAB)                     0x128

dynsym equ 0x128 ; TODO: remove

  .symtab:
	dd      DT_SYMTAB ; tag: Entry type.
	dd      dynsym    ; val: Integer/Address value.

;  Tag        Type                         Name/Value
; 0x0000000a (STRSZ)                      5 (bytes)

dynstr.size equ 5 ; TODO: remove

  .strsz:
	dd      DT_STRSZ    ; tag: Entry type.
	dd      dynstr.size ; val: Integer/Address value.

;  Tag        Type                         Name/Value
; 0x0000000b (SYMENT)                     16 (bytes)

dynsym.entsize equ 16 ; TODO: remove

  .syment:
	dd      DT_SYMENT      ; tag: Dynamic entry type
	dd      dynsym.entsize ; val: Integer or address value

;  Tag        Type                         Name/Value
; 0x00000000 (NULL)                       0x0

  .null:
	dd      DT_NULL ; tag: Entry type.
	dd      0       ; val: Integer/Address value.

times (0x3000 - 0x2FD8) db 0x00 ; padding

.size equ $ - dynamic

; --- [/ .dynamic section ] ----------------------------------------------------

rw_seg.size equ $ - rw_seg

; ___ [/ Read-write segment ] __________________________________________________

; 00003000
db 0x00, 0x2e, 0x73, 0x68, 0x73, 0x74, 0x72, 0x74, 0x61, 0x62, 0x00, 0x2e, 0x67, 0x6e, 0x75, 0x2e ; |..shstrtab..gnu.|
; 00003010
db 0x68, 0x61, 0x73, 0x68, 0x00, 0x2e, 0x64, 0x79, 0x6e, 0x73, 0x79, 0x6d, 0x00, 0x2e, 0x64, 0x79 ; |hash..dynsym..dy|
; 00003020
db 0x6e, 0x73, 0x74, 0x72, 0x00, 0x2e, 0x74, 0x65, 0x78, 0x74, 0x00, 0x2e, 0x65, 0x68, 0x5f, 0x66 ; |nstr..text..eh_f|
; 00003030
db 0x72, 0x61, 0x6d, 0x65, 0x00, 0x2e, 0x64, 0x79, 0x6e, 0x61, 0x6d, 0x69, 0x63, 0x00, 0x00, 0x00 ; |rame..dynamic...|
; 00003040
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; |................|
; 00003050
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; |................|
; 00003060
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0b, 0x00, 0x00, 0x00, 0xf6, 0xff, 0xff, 0x6f ; |...............o|
; 00003070
db 0x02, 0x00, 0x00, 0x00, 0x08, 0x01, 0x00, 0x00, 0x08, 0x01, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00 ; |............ ...|
; 00003080
db 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00 ; |................|
; 00003090
db 0x15, 0x00, 0x00, 0x00, 0x0b, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x28, 0x01, 0x00, 0x00 ; |............(...|
; 000030a0
db 0x28, 0x01, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00 ; |(... ...........|
; 000030b0
db 0x04, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x1d, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00 ; |................|
; 000030c0
db 0x02, 0x00, 0x00, 0x00, 0x48, 0x01, 0x00, 0x00, 0x48, 0x01, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00 ; |....H...H.......|
; 000030d0
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; |................|
; 000030e0
db 0x25, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00 ; |%...............|
; 000030f0
db 0x00, 0x10, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; |................|
; 00003100
db 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x2b, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00 ; |........+.......|
; 00003110
db 0x02, 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; |..... ... ......|
; 00003120
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; |................|
; 00003130
db 0x35, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0xa0, 0x2f, 0x00, 0x00 ; |5............/..|
; 00003140
db 0xa0, 0x2f, 0x00, 0x00, 0x60, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; |./..`...........|
; 00003150
db 0x04, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00 ; |................|
; 00003160
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x30, 0x00, 0x00, 0x3e, 0x00, 0x00, 0x00 ; |.........0..>...|
; 00003170
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; |................|
; 00003180

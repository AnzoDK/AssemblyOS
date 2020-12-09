#Note to self - There is no Malloc, therefore no God - To be fucked is to code without having a malloc


#enum VGA_COLOR
.equ VGA_COLOR_BLACK,         0
.equ VGA_COLOR_BLUE,          1
.equ VGA_COLOR_GREEN,         2
.equ VGA_COLOR_CYAN,          3
.equ VGA_COLOR_RED,           4
.equ VGA_COLOR_MAGENTA,       5
.equ VGA_COLOR_BROWN,         6
.equ VGA_COLOR_LIGHT_GREY,    7
.equ VGA_COLOR_DARK_GREY,     8
.equ VGA_COLOR_LIGHT_BLUE,    9
.equ VGA_COLOR_LIGHT_GREEN,   10
.equ VGA_COLOR_LIGHT_CYAN,    11
.equ VGA_COLOR_LIGHT_RED,     12
.equ VGA_COLOR_LIGHT_MAGENTA, 13
.equ VGA_COLOR_LIGHT_BROWN,   14
.equ VGA_COLOR_WHITE,         15






.section .bss
    .align 4
        .comm vga_current_color, 1
        .comm terminal_row, 4
        .comm terminal_column, 4 
        
.section .data
    .align 4
        hello_str: .ascii "Hello World! - I'm a Kernel ;)"
        vga_width: .int 80
        vga_height: .int 25
        vga_buffer_ptr: .int 0xB8000

.text
.global kernel_main
kernel_main:
    movl %esp, %ebp #for correct debugging
    mov %esp, %ebp #for correct debugging
    # write your code here
    xorl  %eax, %eax
    mov   $0, %edx
    mov   $0, %ecx
    mov   $0, %ebx
    call  kernel_init
    mov   $30, %eax
    mov   $hello_str, %ebx
    call  kernel_print
    ret
    
kernel_print:
    mov $0, %ecx #loop counter
    call  get_vga_ptr
    kernel_print_L1:
    cmp  %ecx, %eax #Check if we should stop loop
    je   kernel_print_end
    pushl %ecx
    movb  (%ebx), %cl #move the char to upper 8 bits of dx
    movb  vga_current_color, %ch
    movw  %cx, (%edx)
    popl  %ecx
    inc   %ecx
    inc  %ebx #increment char[] pointer
    call  advance_terminal
    call  get_vga_ptr #Returns VGA pointer with offset on %edx
    jmp   kernel_print_L1
    kernel_print_end:
    ret
    

advance_terminal:
    pushl %eax
    mov  terminal_column, %eax
    inc  %eax
    cmp  vga_width, %eax #eax >= vga_width
    jge  advance_terminal_update
    mov  %eax, terminal_column
    jmp  advance_terminal_end
    
    advance_terminal_update:
    sub  $80, %eax
    pushl %edx
    mov  terminal_row, %edx
    inc  %edx
    cmp  vga_height, %edx #edx >= vga_height
    jge  advance_terminal_reset
    mov  %edx, terminal_row
    popl %edx
    mov  %eax, terminal_column
    jmp  advance_terminal_end
    
    advance_terminal_reset:
    popl %edx
    call clear_terminal
    
    advance_terminal_end:
    popl  %eax
    ret

get_vga_ptr:
    pushl %eax
    pushl %ebx
    pushl %ecx
    mov terminal_column, %eax
    mov $2, %ebx
    mull %ebx
    
    pushl %eax
    mov terminal_row, %eax
    mov vga_width, %ecx
    
    mull %ecx
    mov  %eax, %edx
    popl %eax
    add  %eax, %edx
    mov  vga_buffer_ptr, %eax
    add  %eax, %edx
    popl %ecx
    popl %ebx
    popl %eax
    
    ret


clear_terminal:
    pushl %eax
    mov   $0, %eax
    mov   %eax, terminal_column
    mov   %eax, terminal_row
    popl  %eax
    
    pushl %ecx
    pushl %edx
    pushl %eax
    pushl %ebx
    
    #reset the VGA buffer
    movl  $0, %ecx
    jmp  clear_terminal_L1 #Loop doesn't work because its a 16 bit array, meaning that we have to add 2 bytes everytime to the array, therefore
    #We have to convert the array offset to represent every other byte instead of every byte. #Yea I fixed that, but fuck you me, that was only the fucking SURFACE
    #OF THE FUCKING ISSUE???? - WHAT DID I EVEN CODE ? - I'm not sure I want to know....
    clear_terminal_L0:
    incl  %ecx
    clear_terminal_L1: #counts on ecx(y)
    cmp  %ecx, vga_height 
    je   clear_terminal_loop_end
    movl  $0, %edx
    clear_terminal_L2: #counts on edx (x)
    cmp  %edx, vga_width
    je   clear_terminal_L0
    movl  %ecx, %eax
    pushl %ecx
    pushl %edx
    movl  vga_width, %ecx
    
    mull  %ecx #multiply uses both edx and eax - eax stores the lower part and edx stores the higher part
    popl  %edx
    
    pushl %eax
    mov   $2, %eax 
    
    pushl  %edx
    
    mull  %edx
    
    popl  %edx
    
    mov   %eax, %ecx
    popl  %eax
    
    addl  %ecx, %eax
    
    movl  vga_buffer_ptr, %ecx
    addl  %ecx, %eax
    movb  $' ', %cl
    movb  vga_current_color, %ch
    
    movw  %cx, (%eax)
    popl  %ecx
    incl  %edx
    jmp  clear_terminal_L2
    clear_terminal_loop_end:
    
    popl %ebx
    popl %eax
    popl %edx
    popl %ecx
    
    ret
    
    
kernel_init:
    # Set the default color
    movb $VGA_COLOR_WHITE, %al
    movb $VGA_COLOR_CYAN, %ah
    shl  $4, %al
    shr  $4, %ax
    movb  %al, vga_current_color
    call clear_terminal
    retl
    

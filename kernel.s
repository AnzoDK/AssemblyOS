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
    kernel_print_L1:
    cmp  %ecx, %eax #Check if we should stop loop
    je   kernel_print_end
    mov  vga_buffer_ptr, %edx
    add   %ecx, %edx #Add counter to pointer
    add   %ecx, %ebx #Add counter to char[] pointer
    pushl %edx
    mov  (%ebx), %dh #move the char to upper 8 bits of dx
    popl  %ebx
    movb  vga_current_color, %dl
    mov   %dx, %bx
    inc   %ecx
    jmp   kernel_print_L1
    kernel_print_end:
    ret
    
    
    
kernel_init:
    # Set the default color
    movb $VGA_COLOR_WHITE, %al
    movb $VGA_COLOR_CYAN, %ah
    shl  $4, %al
    shr  $4, %ax
    movb  %al, vga_current_color
    movb $0, %bl
    movb %bl, terminal_row
    movb %bl, terminal_column
    #reset the VGA buffer
    movl  $0, %ecx
    jmp  kernel_init_L1
    kernel_init_L0:
    incl  %ecx
    kernel_init_L1: #counts on ecx(y)
    cmp  %ecx, vga_width
    je   kernel_init_loop_end
    movl  $0, %edx
    kernel_init_L2: #counts on edx (x)
    cmp  %edx, vga_height
    je   kernel_init_L0
    movl  %ecx, %eax
    mull  (vga_width)
    addl  %edx, %eax
    pushl %ecx
    movl  vga_buffer_ptr, %ecx
    addl  %ecx, %eax
    movb  $'F', %cl
    movb  vga_current_color, %ch
    
    movl  %ecx, (%eax)
    popl  %ecx
    incl  %edx
    jmp  kernel_init_L2
    kernel_init_loop_end:
    
    
    retl
    

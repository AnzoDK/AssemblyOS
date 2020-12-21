#Note to self - There is no Malloc, therefore no God - To be fucked is to code without having a malloc
#most functions use registers as parameters instead of the stack - That is probably a bad idea in the long run

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
        hello_str: .ascii "Hello World! - I'm a Kernel ;)\x0" #ascii is not zero terminated .string is
        init_msg: .string "Initilzing kernel in Default mode"
        vga_width: .int 80
        vga_height: .int 25
        vga_buffer_ptr: .int 0xB8000

.text
.global main
.global strlen

main:
    movl %esp, %ebp #for correct debugging #void kernel_main(void)
    # write your code here
    xorl  %eax, %eax
    mov   $0, %edx
    mov   $0, %ecx
    mov   $0, %ebx
    movl  %eax, 0x0
    call  kernel_init
    pushl %ebp
    movl  %esp, %ebp
    #pushl $30
    pushl $hello_str
    call  strlen
    pushl %eax
    pushl $hello_str
    call  kernel_printline
    #pushl $hello_str
    #call  strlen
    #pushl %eax
    #pushl $hello_str
    #call  kernel_printline
    pushl $'F'
    pushl $80
    pushl $0
    call  kernel_put_char_at
    mov %ebp, %esp
    popl %ebp
    #mov   $hello_str, %ebx
    #call  kernel_printline
    #mov   $init_msg, %ebx
    #call  strlen
    #call  kernel_printline
    #pushl %eax
    #pushl %ebx
    #pushw $'A'
    #pushl $0xB8050
    #call  kernel_put_char_at
    #popl  %ebx
    #popl  %eax
    
    ret
    
kernel_print_legacy: #!!! LEGACY FUNCTION - DEPRECATED !!!! # Set EBX to str pointer, and EAX to length # void kernel_print(char*, uint length)
    mov $0, %ecx #loop counter
    call  get_vga_ptr
    kernel_print_legacy_L1:
    cmp  %ecx, %eax #Check if we should stop loop
    je   kernel_print_legacy_end
    pushl %ecx
    movb  (%ebx), %cl #move the char to upper 8 bits of dx
    movb  vga_current_color, %ch
    movw  %cx, (%edx)
    popl  %ecx
    inc   %ecx
    inc  %ebx #increment char[] pointer
    call  advance_terminal
    call  get_vga_ptr #Returns VGA pointer with offset on %edx
    jmp   kernel_print_legacy_L1
    kernel_print_legacy_end:
    ret

kernel_print: #Use push # void kernel_print(char*, uint length)
    pushl %ebp
    movl  %esp, %ebp
    subl  $4, %esp #allocate space for the count variable
    movl  12(%ebp), %eax #length
    movl  8(%ebp), %ebx #char*
    movl  $0, %ecx #loop counter
    movl  %ecx, -4(%ebp) #-4(%ebp) = int* counter; *counter = 0
    call  get_vga_ptr
    kernel_print_L1:
    cmp   -4(%ebp), %eax #Check if we should stop loop
    je    kernel_print_end
    movb  (%ebx), %cl #move the char to lower 8 bits of cx
    movb  vga_current_color, %ch
    #movw  %cx, (%edx)
    incl   -4(%ebp)
    inc   %ebx #increment char[] pointer
    call  advance_terminal
    call  get_vga_ptr #Returns VGA pointer with offset on %edx
    jmp   kernel_print_L1
    kernel_print_end:
    mov %ebp, %esp
    pop %ebp
    ret

kernel_printline_legacy: #!!! LEGACY FUNCTION - DEPRECATED !!!! #Set EBX to str pointer, and EAX to length # void kernel_printline(char*, uint length)
    call kernel_print_legacy
    call kernel_newline
    ret
    
kernel_printline: #Use Push # void kernel_printline(char* string, uint length)
    pushl %ebp
    movl  %esp, %ebp
    pushl 12(%ebp)
    pushl 8(%ebp)
    call kernel_print
    call kernel_newline
    movl %ebp, %esp
    popl %ebp
    ret 

kernel_newline: # void kernel_newline(void)
    pushl %ebp
    movl  %esp, %ebp
    pushl %eax
    mov $0, %eax
    mov %eax, terminal_column
    mov terminal_row, %eax
    inc %eax 
    mov %eax, terminal_row
    popl %eax
    mov   %ebp, %esp
    popl  %ebp
    ret


advance_terminal: #void advance_terminal(void)
    pushl %eax
    mov  terminal_column, %eax
    inc  %eax
    cmp  vga_width, %eax #eax >= vga_width
    jge  advance_terminal_update
    mov  %eax, terminal_column
    jmp  advance_terminal_end
    
    advance_terminal_update:
    sub  vga_width, %eax
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

get_vga_ptr: #uint16* get_vga_ptr(void)
    pushl %ebp
    movl  %esp, %ebp
    pushl %eax
    pushl %ebx
    pushl %ecx
    mov terminal_column, %eax
    mov $2, %ebx
    mull %ebx
    
    pushl %eax # stores x*2
    mov terminal_row, %eax
    mov vga_width, %ecx
    
    mull %ecx # vga_width * terminal_row
    mov  %eax, %edx
    popl %eax
    add  %eax, %edx # (x*2) + (vga_width * terminal_row)
    mov  vga_buffer_ptr, %eax
    add  %eax, %edx # 0xB8000 + ((x*2) + (vga_width * terminal_row))
    popl %ecx
    popl %ebx
    popl %eax
    mov   %ebp, %esp
    popl  %ebp
    ret


kernel_put_char_at: #push the char and the address # void kernel_put_char_at(char c, int indexX, int indexY)
    pushl %ebp
    movl  %esp, %ebp
    subl  $8, %esp #Allocating space for Old_terminal_X and old terminalY
    pushl %eax
    movl  terminal_column, %eax
    movl  %eax, -4(%ebp) #OLD terminal_column
    movl  terminal_row, %eax
    movl  %eax, -8(%ebp) #OLD terminal_row
    pushl %ebx
    pushl %ecx
    movl  12(%ebp), %ebx #int indexX
    movl  8(%ebp), %ecx #int indexY
    movb  16(%ebp), %al #char c
    movl  %ecx, terminal_row
    movl  %ebx, terminal_column
    
    mov  vga_current_color, %ah
    pushl %edx
    call get_vga_ptr #returns VGA address on %edx
    #movw %ax, (%edx)
    popl %edx
    popl %ebx
    movl -4(%ebp), %eax
    movl %eax, terminal_column
    movl -8(%ebp), %eax
    movl %eax, terminal_row
    popl %eax
    movl %ebp, %esp
    popl %ebp
    ret


clear_terminal: #void clear_terminal(void)
    pushl %ebp
    movl  %esp, %ebp
    subl  $4, %esp #aligned to 4, allocate space for counter
    
    #Get the total amount of characters to place
    pushl %eax
    movl $0, %eax
    movl %eax, -4(%ebp) #set counter to 0
    pushl %edx
    movl  vga_width, %edx
    movl  vga_height, %eax
    mull  %edx
    decl  terminal_column #Indexing being fucked
    popl  %edx
    clear_terminal_loop_L0:
    cmp  %eax, -4(%ebp) #Eax hold the total byte count
    jl   clear_terminal_loop_L1
    jmp  clear_terminal_end
    
    clear_terminal_loop_L1:
    pushl %eax
    call advance_terminal
    call get_vga_ptr
    incl -4(%ebp)
    movb  $' ', %al
    movb  vga_current_color, %ah
    #movw  %ax, (%edx)
    popl %eax
    jmp  clear_terminal_loop_L0
    
    clear_terminal_end:
    movl $0, %eax
    movl %eax, terminal_column
    movl %eax, terminal_row
    popl %eax
    
    mov  %ebp, %esp
    popl %ebp
    ret
    
    
kernel_init:
    # Set the default color
    movb $VGA_COLOR_GREEN, %al
    movb $VGA_COLOR_RED, %ah
    shl  $4, %al
    shr  $4, %ax
    movb  %al, vga_current_color
    call clear_terminal
    retl
    
    
strlen: #Gets length of zero terminated string - Sets EAX to the length of the string - Expects a string ptr in stack 
# Only supports strings of 4,294967296*10^9-1 characters
    pushl %ebp
    movl  %esp, %ebp
    sub   $4, %esp #reserve space for orignal address
    pushl %eax
    movl  8(%ebp), %eax
    movl  %eax, -4(%ebp)
    popl  %eax
    strlen_loop:
    pushl %eax
    movl  8(%ebp), %eax
    cmpb  $0x0, (%eax)
    popl  %eax
    je strlen_loop_end
    incl 8(%ebp)
    jmp strlen_loop
    
    strlen_loop_end:
    movl 8(%ebp), %eax
    sub  -4(%ebp), %eax
    movl %ebp, %esp
    popl %ebp
    ret
    
exc_0d_handler: #Error handle
    #push %gs
    #mov $ZEROBASED_DATA_SELECTOR, %gs
    #mov $'D', vga_buffer_ptr
    # D in the top-left corner means we're handling
    #  a GPF exception right ATM.
 
    # your 'normal' handler comes here
    pushal
    #push %ds
    #push %es
    #mov $KERNEL_DATA_SELECTOR,%ax
    #mov %ax, %dx
    #mov %ax, %es
 
    #call gpfExcHandler
 
    #pop %es
    #pop %ds
    popal
 
    #movb $'D', ($0x8002)
    # the 'D' moved one character to the right, letting
    # us know that the exception has been handled properly
    # and that normal operations continues.
    #pop %gs
    iret
    
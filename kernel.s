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
.global kernel_main
.global strlen

kernel_main:
    movl %esp, %ebp #for correct debugging #void kernel_main(void)
    # write your code here
    xorl  %eax, %eax
    mov   $0, %edx
    mov   $0, %ecx
    mov   $0, %ebx
    call  kernel_init
    pushl %ebp
    movl  %esp, %ebp
    #pushl $30
    pushl $hello_str
    call  strlen
    pushl %eax
    pushl $hello_str
    call  kernel_printline
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
    movl  12(%ebp), %eax
    movl  8(%ebp), %ebx
    movl   $0, %ecx #loop counter
    movl  %ecx, -4(%ebp) #-4(%ebp) = int* counter; *counter = 0
    pushl %ebp
    movl  %esp, %ebp
    call  get_vga_ptr
    mov %ebp, %esp
    pop %ebp
    kernel_print_L1:
    cmp   -4(%ebp), %eax #Check if we should stop loop
    je    kernel_print_end
    movb  (%ebx), %cl #move the char to upper 8 bits of dx
    movb  vga_current_color, %ch
    movw  %cx, (%edx)
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
    pushl %eax
    mov $0, %eax
    mov %eax, terminal_column
    mov terminal_row, %eax
    inc %eax 
    mov %eax, terminal_row
    popl %eax
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
    
    ret


kernel_put_char_at: #push the char and the address # void kernel_put_char_at(char c, int index)
    popw %ax
    mov  vga_current_color, %ah
    popl %ebx
    movw %ax, (%ebx)
    ret


clear_terminal: #void clear_terminal(void)
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
    #OF THE FUCKING ISSUE???? - WHAT DID I EVEN CODE ? - I'm not sure I want to know.... ITS WORKING (KINDA) AND STILL SUCKS....
    clear_terminal_L0:
    incl  %ecx
    clear_terminal_L1: #counts on ecx(y)
    cmp  vga_height, %ecx #ecx < vga_height
    jl  clear_terminal_L2
    jmp clear_terminal_loop_end
    clear_terminal_L2:
    movl  $0, %edx
    clear_terminal_L3: #counts on edx (x)
    cmp   vga_width, %edx #edx < vga_width
    jl   clear_terminal_L4
    jmp  clear_terminal_L0
    clear_terminal_L4:
    movl  %ecx, %eax #%eax = counter_y
    pushl %ecx
    pushl %edx #save the contents of %edx from being overriden by mull
    movl  vga_width, %ecx
    
    mull  %ecx #multiply uses both edx and eax - eax stores the lower part and edx stores the higher part # vga_width*counter_y
    popl  %edx #restore %edx - counter_y is still on the stack
    
    pushl %eax #save result of vga_width*counter_y
    mov   $2, %eax 
    
    pushl  %edx# save edx from mull again
    
    mull  %edx# counter_x * 2
    
    popl  %edx #Stack contains [result of vga_width*counter_y, counter_y] after this pop
    
    mov   %eax, %ecx #move result of counter_x * 2 into ecx
    popl  %eax #Get result of vga_width*counter_y from stack
    
    addl  %ecx, %eax #(counter_x * 2)+(vga_width*counter_y)
    
    movl  vga_buffer_ptr, %ecx
    addl  %ecx, %eax # 0xB0000 + (counter_x * 2)+(vga_width*counter_y)
    movb  $' ', %cl
    movb  vga_current_color, %ch
    
    movw  %cx, (%eax)
    popl  %ecx #pops counter_y
    incl  %edx #counter_x++
    jmp  clear_terminal_L3
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
    
    
strlen: #Gets length of zero terminated string - Sets EAX to the length of the string - Expects a string ptr in stack 
# Only supports strings of 4,294967296*10^9 characters
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

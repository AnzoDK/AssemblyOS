.text
.global main
main:
    movl %esp, %ebp #for correct debugging
    # write your code here
    xorl  %eax, %eax
    mov   $444, %eax
    push  %eax
    mov   $555, %eax
    push  %eax
    mov   %esp, %ebx
    mov   4(%ebx), %ecx
    ret

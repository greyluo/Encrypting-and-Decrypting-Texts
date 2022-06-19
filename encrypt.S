//uncomment the next line when you want to use your routine
#define MYCODE
#ifdef MYCODE
// version 1.0 05/22/2022
    .arch armv6
    .arm
    .fpu vfp
    .syntax unified

    #include "encrypter.h"

    .text     // start of text segment

    //////////////////////////////////////////////////
    // int encrypt(char *IOBUF, char *BOOKBUF, int cnt)
    // encrypts  IOBUF with BOOKBUF; updating IOBUF
    //////////////////////////////////////////////////
    .global encrypt
    .type   encrypt, %function
    .equ    FP_OFF, 12

encrypt:
    push    {r4, r5, fp, lr}
    add     fp, sp, FP_OFF
    mov     r3, 0   
.Lloop:
    cmp     r3, r2 
    bge     .Ldone 
    ldrb    r4, [r0, r3]    // load x from IOBUF
    lsr     r5, r4, 4       // right shift 4 bits
    lsl     r4, r4, 28      // left shift 28 bits
    lsr     r4, r4, 24      // right shift 24 bits
    orr     r4, r4, r5      // x = x OOR y
    ldrb    r5, [r1, r3]    // load y from BOOKBUF
    eor     r4, r4, r5      // x = x EOR y
    strb    r4, [r0, r3]    // store x
    add     r3, r3, 1       // increment index
    b       .Lloop 

.Ldone:
    mov     r0, r2
    sub     sp, fp, FP_OFF
    pop     {r4, r5, fp, lr}
    bx      lr
    .size encrypt, (. - encrypt)
    .section .note.GNU-stack,"",%progbits
.end
#endif

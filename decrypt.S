
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
    // int decrypt(char *IOBUF, char *BOOKBUF, int cnt) 
    // decrypts  IOBUF using BOOKBUF; result in IOBUF
    //////////////////////////////////////////////////
    .global decrypt
    .type   decrypt, %function
    .equ    FP_OFF, 12

decrypt:
    push    {r4, r5, fp, lr}
    add     fp, sp, FP_OFF
    mov     r3, 0       // put r3 as index
.Lloop:
    cmp     r3, r2
    bge    .Ldone
    ldrb    r4, [r0, r3]    // load IOBUF[i]
    ldrb    r5, [r1, r3]    // load BOOKBUF[i]
    eor     r4, r4, r5      // x = x EOR y
    lsr     r5, r4, 4       // right shift 4 bits
    lsl     r4, r4, 28      // left shift 28 bits
    lsr     r4, r4, 24      // right shift 24 bits
    orr     r4, r4, r5      // x = x OOR y
    strb    r4, [r0, r3]    // store IOBUF[i]
    add     r3, r3, 1       // i++
    b       .Lloop

.Ldone:
    mov     r0, r2          // r0 = cnt
    sub     sp, fp, FP_OFF
    pop     {r4, r5, fp, lr}
    bx      lr

    .size decrypt, (. - decrypt)
    .section .note.GNU-stack,"",%progbits
.end
#endif
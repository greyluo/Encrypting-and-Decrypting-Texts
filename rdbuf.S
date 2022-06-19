//uncomment the next line when you want to use your routine
#define MYCODE
#ifdef MYCODE
// version 1.1 05/22/2022
    .arch   armv6
    .arm
    .fpu    vfp
    .syntax unified

    // global constants
    #include "encrypter.h"

    .section .rodata
.Lmsg:  .string "rdbuf: Bookfile is too short for message\n"
.Lmsg2: .string "rdbuf: Buffer size error\n"
    .text

    //////////////////////////////////////////////////////
    // int rdbuf(char *IOBUF, char *BOOKBUF, FILE *FPIN
    //              FILE *FPBOOK, int BUFSZ);
    // returns number of bytes read EXIT_FAIL otherwise
    //////////////////////////////////////////////////////

    .type   rdbuf, %function
    .global rdbuf
    .equ    IARG5,  4 
    .equ    FP_OFF, 12
 
    ////////////////////////////////////////
    // preserved register use             //
    // r4 pointer to book buffer          //
    // r5 FILE *FPBOOK  & cnt read saved  //
    ////////////////////////////////////////

rdbuf:
    push    {r4, r5, fp, lr}
    add     fp, sp, FP_OFF
    mov     r4, r1          // r4 = BOOKBUF
    mov     r5, r3          // r5 = FPBOOK
    ldr     r1, [fp, IARG5] // r1 = BUFSZ
    cmp     r1, 0
    bgt     .Lnext
    ldr     r0, =.Lmsg2
    bl      errmsg
    mov     r0, EXIT_FAIL
    b      .Ldone
.Lnext:
    mov     r3, r2          // r3 = FPIN
    mov     r2, r1          // r2 = BUFSZ
    mov     r1, 1           // r1 = 1
    bl      fread
    cmp     r0, 0
    beq     .Ldone
.Lthen:
    mov     r2, r0          // r2 = cnt read
    mov     r0, r4          // r0 = BOOKBUF
    mov     r1, 1           // r1 = 1
    mov     r3, r5          // r3 = FPBOOK
    mov     r5, r2          // r5 = cnt read
    bl      fread 
    cmp     r0, r5          // check if == cnt read
    beq     .Ldone
    ldr     r0, =.Lmsg
    bl      errmsg
    mov     r0, EXIT_FAIL
.Ldone:
    sub     sp, fp, FP_OFF
    pop     {r4, r5, fp, lr}
    bx      lr

    .size   rdbuf, (. - rdbuf)
    .section .note.GNU-stack,"",%progbits
.end
#endif
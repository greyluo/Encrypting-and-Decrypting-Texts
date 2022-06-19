//uncomment the next line when you want to use your routine
#define MYCODE
#ifdef MYCODE
// version 1.1 05/27/2022
    .arch   armv6
    .arm
    .fpu    vfp
    .syntax unified

    // function import
    .extern encrypt
    .extern decrypt
    .extern setup
    .extern rdbuf
    .extern cleanup
    .extern wrbuf

    // global constants
    #include "encrypter.h"

    .text

    //////////////////////////////////////////////////////
    // int main(int argc, char **argv)                  //
    // encrypter [-d | -e] -b bookfile encryption_file  //
    //////////////////////////////////////////////////////

    // finish the stack frame first
   .global main
    .type   main, %function
    .equ    BUFSZ,      1024            // buffer size
    .equ    FP_OFF,     28              // fp offset in main stack frame
    .equ    FPBOOK,     FP_OFF + 4      // FILE * to book file
    .equ    FPIN,       FPBOOK + 4      // FILE * to input file
    .equ    FPOUT,      FPIN + 4        // FILE * to output file
    .equ    MODE,       FPOUT + 4       // decrypt or encrypt mode
    .equ    IOBUF,      MODE + BUFSZ    // buffer for input file
    .equ    BOOKBUF,    IOBUF + BUFSZ   // buffer for book file
    // add local variables here: adjust PAD size
    .equ    PAD,        BOOKBUF + 0     // Stack frame PAD 
    .equ    OARG6,      PAD + 4         // output arg6
    .equ    OARG5,      OARG6 + 4       // output arg5 must be at bottom
    .equ    FRAMESZ,    OARG5 - FP_OFF  // total space for frame
    ////////////////////////////////////////////////////////////////
    // make sure that FRAMESZ + FP_OFF + 4 divides by 8 EVENLY!
    ////////////////////////////////////////////////////////////////
 
    ////////////////////////////////////////
    // preserved register use             //
    // r4 pointer to input/output buffer  //
    // r5 pointer to book buffer          //
    // r6 mode flag                       //
    // r7 input FILE *                    //
    // r8 book FILE *                     //
    // r9 output FILE *                  //
    ////////////////////////////////////////

main:
    push    {r4-r9, fp, lr}
    add     fp, sp, FP_OFF          // set frame pointer to frame base
    ldr     r3, =FRAMESZ            // frame size is big, use pseudo ldr
    sub     sp, sp, r3              // allocate space for locals and passed args 
     
    // call int setup(argc, argv, *mode, *FPBOOK, *FPIN, *FPOUT)
    add     r2, fp, -MODE            // r2 = &mode
    add     r3, fp, -FPBOOK          // r3 = &book file
    add     r4, fp, -FPIN            // r4 = &input file
    str     r4, [fp, -OARG5]         // save &input file pointer in frame
    add     r5, fp, -FPOUT           // r5 = &output file
    str     r5, [fp, -OARG6]         // save &output file pointer in frame
    bl      setup
    cmp     r0, EXIT_FAIL
    bne     .Lsetup
    mov     r0, EXIT_FAILURE
    b       .Lexit

.Lsetup:    
    // set up for main loop
    ldr     r4, =IOBUF              // r4 = &input buffer
    sub     r4, fp, r4              // r4 = IO buffer
    ldr     r5, =BOOKBUF            // r5 = &book buffer
    sub     r5, fp, r5              // r5 = book buffer
    ldr     r6, [fp, -MODE]         // r6 = mode
    ldr     r7, [fp, -FPIN]         // r7 = input file
    ldr     r8, [fp, -FPBOOK]       // r8 = book file
    ldr     r9, [fp, -FPOUT]        // r9 = output file

.Lloop:
    // int rdbuf(char *IOBUF, char *BOOKBUF, FILE *FPIN
    //              FILE *FPBOOK, int BUFSZ);
    // returns number of bytes read EXIT_FAIL otherwise
    mov     r0, r4                  // pass IO buffer to arg1
    mov     r1, r5                  // pass book buffer to arg2
    mov     r2, r7                  // pass input FILE * to arg3
    ldr     r3, =BUFSZ              // pass output FILE * to arg5
    str     r3, [fp,-OARG5]         // save input buffer size to arg5
    mov     r3, r8                  // pass book FILE * to arg4
    bl      rdbuf
    cmp     r0, 0
    ble     .Ldone                  // if read failed, exit
.Lprocinput:
    // int XXcrypt(char *IOBUF, char *BOOKBUF, int cnt)
    cmp     r6, ENCRYPT_MODE        // if encrypting
    bne     .Ldecrypt               // not then decrypt
    mov     r2, r0
    mov     r0, r4                  // pass IO buffer to arg1
    mov     r1, r5                  // pass book buffer to arg2
    bl      encrypt
    b       .Lwriteout
.Ldecrypt: 
    // decrypt the input
    mov     r2, r0
    mov     r0, r4                  // pass IO buffer to arg1
    mov     r1, r5                  // pass book buffer to arg2
    bl      decrypt
.Lwriteout:

    // int wrbuf(char *IOBUF, int cnt, FILE *FPOUT);
    // return cnt on success EXIT_FAIL otherwise 
    cmp     r0, EXIT_FAIL           // if count is EXIT_FAIL
    beq     .Ldone                  // then exit
    mov     r1, r0                  // pass count to arg2
    mov     r0, r4                  // pass input buffer to arg1
    mov     r2, r9                  // pass output FILE * to arg3
    bl      wrbuf
    cmp     r0, EXIT_FAIL
    bne     .Lloop
    mov     r0, EXIT_FAIL
    
.Ldone:
    // int cleanup(int status)
    // r0 should have exit status in it
    bl      cleanup

.Lexit:
    sub     sp, fp, FP_OFF
    pop     {r4-r9, fp, lr}
    bx      lr

    .size   main, (. - main)
    .section .note.GNU-stack,"",%progbits
.end
#endif

// This is a test program.

boot:
  ; Start by setting up the stack.
  ldi    sp, 0x00020000  ; We grow down from 128KB.

main:
  ldi    s16, 0         ; s16 is the return code (0 = success, 1 = fail)

  bl     test_1
  or     s16, s16, s1
  bz     s1, .test1_passed
  bl     .test_failed
.test1_passed:

  bl     test_2
  or     s16, s16, s1
  bz     s1, .test2_passed
  bl     .test_failed
.test2_passed:

  bl     test_3
  or     s16, s16, s1
  bz     s1, .test3_passed
  bl     .test_failed
.test3_passed:

  bl     test_4
  or     s16, s16, s1
  bz     s1, .test4_passed
  bl     .test_failed
.test4_passed:

  bl     test_5
  or     s16, s16, s1
  bz     s1, .test5_passed
  bl     .test_failed
.test5_passed:

  bl     test_6
  or     s16, s16, s1
  bz     s1, .test6_passed
  bl     .test_failed
.test6_passed:

  bl     test_7
  or     s16, s16, s1
  bz     s1, .test7_passed
  bl     .test_failed
.test7_passed:

  bl     test_8
  or     s16, s16, s1
  bz     s1, .test8_passed
  bl     .test_failed
.test8_passed:

  bl     test_9
  or     s16, s16, s1
  bz     s1, .test9_passed
  bl     .test_failed
.test9_passed:

  bl     test_10
  or     s16, s16, s1
  bz     s1, .test10_passed
  bl     .test_failed
.test10_passed:

.done:
  ; exit(s16 != 0 ? 1 : 0)
  sne    s1, s16, z
  and    s1, s1, 1
  b      _exit


.test_failed:
  lea    s1, .fail_msg
  b      _puts


.fail_msg:
  .asciz "*** Failed!"
  .align 4


; ----------------------------------------------------------------------------
; A loop with a decrementing conunter.

test_1:
  add    sp, sp, -4
  stw    lr, sp, 0

  ldi    s9, 0x20
  ldi    s10, 12

.loop:
  add    s9, s9, s10
  add    s10, s10, -1
  bnz    s10, .loop

  lea    s9, .data
  ldw    s1, s9, 0
  ldw    s2, s9, 4
  pbadd  s1, s1, s2
  bl     _printhex
  ldi    s1, 10
  bl     _putc

  ldi    s1, 0

  ldw    lr, sp, 0
  add    sp, sp, 4
  j      lr

.data:
  .u32   0x12345678, 0xffffffff


; ----------------------------------------------------------------------------
; Sum elements in a data array.

test_2:
  add    sp, sp, -12
  stw    lr, sp, 0
  stw    s16, sp, 4
  stw    s17, sp, 8

  lea    s16, .data
  ldw    s1, s16, 0       ; s1 = data[0]
  ldw    s17, s16, 4
  add    s1, s1, s17      ; s1 += data[1]
  ldw    s17, s16, 8
  add    s1, s1, s17      ; s1 += data[2]
  mov    s16, s1          ; Save the result for the comparison later
  bl     _printhex
  ldi    s1, 10
  bl     _putc

  ldi    s1, 0xbeef0042
  sne    s1, s16, s1      ; Expected value?

  ldw    lr, sp, 0
  ldw    s16, sp, 4
  ldw    s17, sp, 8
  add    sp, sp, 12

  j      lr

.data:
  .u32   0x40, 1, 0xbeef0001
  .align 4


; ----------------------------------------------------------------------------
; Call a subroutine that prints hello world.

test_3:
  add    sp, sp, -4
  stw    lr, sp, 0

  lea    s1, .hello_world
  bl     _puts

  ldw    lr, sp, 0
  add    sp, sp, 4
  ldi    s1, 0
  j      lr


.hello_world:
  .asciz "Hello world!"
  .align 4


; ----------------------------------------------------------------------------
; 64-bit arithmetic.

test_4:
  add    sp, sp, -8
  stw    lr, sp, 0
  stw    s16, sp, 4

  ; Load two 64-bit numbers into s11:s10 and s13:s12
  lea    s9, .dword1
  ldw    s10, s9, 0  ; s10 = low bits
  ldw    s11, s9, 4  ; s11 = high bits
  lea    s9, .dword2
  ldw    s12, s9, 0  ; s12 = low bits
  ldw    s13, s9, 4  ; s13 = high bits

  ; Add the numbers into s1:s16
  add    s16, s10, s12  ; s16 = low bits
  add    s1, s11, s13   ; s1 = high bits
  sltu   s9, s16, s10   ; s9 = "carry" (0 or -1)
  sub    s1, s1, s9     ; Add carry to the high word

  bl     _printhex      ; Print high word
  mov    s1, s16
  bl     _printhex      ; Print low word
  ldi    s1, 10
  bl     _putc

  ldw    lr, sp, 0
  ldw    s16, sp, 4
  add    sp, sp, 8

  ldi    s1, 0
  j      lr

.dword1:
  .u32   0x89abcdef, 0x01234567
.dword2:
  .u32   0xaaaaaaaa, 0x00010000


; ----------------------------------------------------------------------------
; Floating point arithmetic.

test_5:
  add    sp, sp, -8
  stw    lr, sp, 0
  stw    s16, sp, 4

  ; Calculate 2 * PI
  ldw    s9, .pi
  ldw    s10, .two
  fmul   s16, s9, s10  ; s16 = 2 * PI

  mov    s1, s16
  bl     _printhex
  ldi    s1, 10
  bl     _putc

  ; Was the result 2 * PI?
  ldw    s9, .twopi
  fsub   s9, s16, s9  ; s9 = (2 * PI) - .twopi

  ldw    lr, sp, 0
  ldw    s16, sp, 4
  add    sp, sp, 8

  ; s1 = (result == 2*PI) ? 0 : 1
  ldi    s1, 0
  bz     s9, .ok
  ldi    s1, 1
.ok:

  j      lr


.one:
  .u32   0x3f800000
.two:
  .u32   0x40000000
.pi:
  .u32   0x40490fdb
.twopi:
  .u32   0x40c90fdb


; ----------------------------------------------------------------------------
; Vector operations.

test_6:
  add    sp, sp, -20
  stw    lr, sp, 0
  stw    vl, sp, 4
  stw    s16, sp, 8
  stw    s17, sp, 12
  stw    s18, sp, 16

  ; Print the maximum vector length
  lea    s1, .vector_length_text
  bl     _puts
  cpuid  s1, z
  bl     _printhex
  ldi    s1, 10
  bl     _putc

  ; Prepare scalars
  lea    s9, .in
  lea    s16, .result

  ldi    s11, 37       ; We want to process 37 elements

  ; Prepare the vector operation
  cpuid  s10, z        ; s10 is the max number of vector elements
  lsl    s12, s10, 2   ; s12 is the memory increment per vector operation

.vector_loop:
  min    vl, s10, s11  ; VL = min(s10, s11)

  ; Load v9 from memory
  ldw    v9, s9, 4

  ; Initialize v10 to a constant value
  ldi    v10, 0x1234

  ; Add vectors v9 and v10
  add    v9, v9, v10

  ; Subtract a scalar from v9
  add    v9, v9, -8

  ; Store the result to memory
  stw    v9, s16, 4

  sub    s11, s11, s10      ; Decrement the loop counter
  add    s9, s9, s12        ; Increment the memory pointers
  add    s16, s16, s12
  bgt    s11, .vector_loop

  ; Print the result
  lea    s16, .result
  ldi    s17, 0
.print:
  lsl    s9, s17, 2
  ldw    s1, s16, s9
  bl     _printhex
  ldi    s1, 0x2c
  add    s18, s17, -36  ; s17 == 36 ?
  add    s17, s17, 1
  bnz    s18, .not_last_element
  ldi    s1, 10         ; Print comma or newline depending on if this is the last element
.not_last_element:
  bl     _putc
  bnz    s18, .print

  ldw    lr, sp, 0
  ldw    vl, sp, 4
  ldw    s16, sp, 8
  ldw    s17, sp, 12
  ldw    s18, sp, 16
  add    sp, sp, 20

  ldi    s1, 0
  j      lr

.in:
  .i32   1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
  .i32   17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32
  .i32   33, 34, 35, 36, 37

.result:
  .space 148

.vector_length_text:
  .asciz "Max vector length: "


; ----------------------------------------------------------------------------
; Software multiply.

test_7:
  add    sp, sp, -4
  stw    lr, sp, 0

  ldi    s1, 123
  ldi    s2, 456
  bl     _mul32
  ; mul    s1, s1, s2
  bl     _printhex
  ldi    s1, 10
  bl     _putc

  ldw    lr, sp, 0
  add    sp, sp, 4
  ldi    s1, 0
  j      lr


; ----------------------------------------------------------------------------
; Software divide.

test_8:
  add    sp, sp, -8
  stw    lr, sp, 0

  ldi    s1, 5536
  ldi    s2, 13
  bl     _divu32

  stw    s2, sp, 4
  bl     _printhex    ; Print the quotient
  ldi    s1, 0x3a     ; ":"
  bl     _putc
  ldw    s1, sp, 4
  bl     _printhex    ; Print the remainder
  ldi    s1, 10       ; "\n"
  bl     _putc

  ldw    lr, sp, 0
  add    sp, sp, 8
  ldi    s1, 0
  j      lr


; ----------------------------------------------------------------------------
; Floating point operations.

test_9:
  add    sp, sp, -20
  stw    lr, sp, 0
  stw    s16, sp, 4
  stw    s17, sp, 8
  stw    s18, sp, 12
  stw    s19, sp, 16

  ldi    s16, 0x3fd98000    ; s16 = 1.6992188F
  ldi    s17, 0x41c5bfff    ; s17 = 24.718748F
  fmul   s18, s16, s17      ; s18 = 42.002561F (0x4228029f)

  ldw    s9, .answer
  sne    s19, s9, s18       ; Expected value?

  or     s1, s18, z
  bl     _printhex          ; Print the product
  ldi    s1, 0x2c           ; ","
  bl     _putc

  ldi    s9, 2
  ftoi   s1, s18, s9        ; s1 = (int)(s18 * 2.0^2) (0x000000a8)

  ldi    s9, 0x00a8
  sne    s9, s9, s1         ; Expected value?
  or     s19, s19, s9

  bl     _printhex          ; Print the integer representation
  ldi    s1, 10             ; "\n"
  bl     _putc

  or     s1, s19, z         ; Result in s1

  ldw    lr, sp, 0
  ldw    s16, sp, 4
  ldw    s17, sp, 8
  ldw    s18, sp, 12
  ldw    s19, sp, 16
  add    sp, sp, 20

  j      lr


.answer:
  .u32  0x4228029f


; ----------------------------------------------------------------------------
; Vector folding.

test_10:
  add    sp, sp, -24

  ldi    vl, 4
  lea    s9, .data1
  lea    s10, .data2
  ldw    v1, s9, 4    ; v1 = [1, 2, 3, 4]
  ldw    v2, s10, 4   ; v2 = [9, 8, 7, 6]

  add    v3, v1, v2   ; v3 = [10, 10, 10, 10]
  add    s10, sp, 0
  stw    v3, s10, 4
  ldi    vl, 2
  add.f  v4, v1, v2   ; v4 = [8, 8]
  add    s10, sp, 16
  stw    v4, s10, 4

  ldi    s1, -1

  lea    s9, .answer1
  add    s10, sp, 0
  ldw    s2, s10, 0
  ldw    s3, s9, 0
  seq    s2, s2, s3
  and    s1, s1, s2
  ldw    s2, s10, 4
  ldw    s3, s9, 4
  seq    s2, s2, s3
  and    s1, s1, s2
  ldw    s2, s10, 8
  ldw    s3, s9, 8
  seq    s2, s2, s3
  and    s1, s1, s2
  ldw    s2, s10, 12
  ldw    s3, s9, 12
  seq    s2, s2, s3
  and    s1, s1, s2

  lea    s9, .answer2
  add    s10, sp, 16
  ldw    s2, s10, 0
  ldw    s3, s9, 0
  seq    s2, s2, s3
  and    s1, s1, s2
  ldw    s2, s10, 4
  ldw    s3, s9, 4
  seq    s2, s2, s3
  and    s1, s1, s2

  xor    s1, s1, -1

  add    sp, sp, 24
  j      lr

.data1:
  .u32   1,2,3,4

.data2:
  .u32   9,8,7,6

.answer1:
  .u32   10, 10, 10, 10

.answer2:
  .u32   8, 8


; ----------------------------------------------------------------------------

  .include "sys.s"


ooo_test.s:
.align 4
.section .text
.globl _start
    # This program will provide a simple test for
    # demonstrating OOO-ness

    # This test is NOT exhaustive
_start:
lui x5, 0x12345 
lui x4, 0xc1f71
lui x6, 0x12345
lui x7, 0x12345
# initialize
li x1, 10
li x2, 20
li x5, 50
li x6, 60
li x8, 21
li x9, 28
li x11, 8
li x12, 4
li x14, 3
li x15, 1

nop
nop
nop
nop
nop
nop

# this should take many cycles
# if this writes back to the ROB after the following instructions, you get credit for CP2
mul x3, x1, x2

# these instructions should  resolve before the multiply
add x4, x5, x6
xor x7, x8, x9
sll x10, x11, x12
and x13, x14, x15

# Initialize some registers
li x1, -10       # Load immediate 10 into x1
li x2, 1        # Load immediate 5 into x2
li x3, 3       # Load immediate -3 into x3
lui x5, 0x12345 
lui x4, 0xc1f71
lui x6, 0x12345
lui x7, 0x12345
auipc x7, 0x67890
auipc x8, 0xaaaaa

# Integer Arithmetic Instructions
add   x4, x1, x2     # x4 = x1 + x2 (10 + 5 = 15)
sub   x5, x1, x2     # x5 = x1 - x2 (10 - 5 = 5)
sll   x6, x1, x2     # x6 = x1 << x2 (10 << 5 = 320)
slt   x7, x3, x1     # x7 = x3 < x1 (-3 < 10) => x7 = 1
sltu  x8, x1, x2     # x8 = x1 < x2 (10 < 5 unsigned) => x8 = 0
xor   x9, x1, x2     # x9 = x1 ^ x2 (10 ^ 5 = 15)
srl   x10, x1, x2    # x10 = x1 >> x2 (logical shift)
sra   x11, x1, x2    # x11 = x1 >>> x2 (arithmetic shift)
or    x12, x1, x2    # x12 = x1 | x2 (10 | 5 = 15)
and   x13, x1, x2    # x13 = x1 & x2 (10 & 5 = 0)

# Integer Arithmetic with Immediate Instructions
addi  x14, x1, -4    # x14 = x1 + (-4) = 6
slti  x15, x3, 0     # x15 = (x3 < 0) => 1
sltiu x16, x1, 20    # x16 = (10 < 20 unsigned) => 1
xori  x17, x1, 8     # x17 = x1 ^ 8 = 2
ori   x18, x1, 1     # x18 = x1 | 1 = 11
andi  x19, x1, 7     # x19 = x1 & 7 = 2
slli  x20, x1, 2     # x20 = x1 << 2 = 40
srli  x21, x1, 1     # x21 = x1 >> 1 = 5
srai  x22, x3, 1     # x22 = x3 >> 1 (arithmetic, -3 >> 1 = -2)

# Multiplication and Division Instructions (M-extension)
mul   x23, x1, x2    # x23 = x1 * x2 (10 * 5 = 50)
mulh  x24, x3, x2    # x24 = high 32 bits of x3 * x2 (-3 * 5)
mulhsu x25, x3, x2   # x25 = high bits of x3 * x2 signed x3 unsigned x2
mulhu x26, x1, x2    # x26 = high bits of unsigned x1 * x2
div   x27, x1, x2    # x27 = x1 / x2 (10 / 5 = 2)
divu  x28, x1, x2    # x28 = x1 / x2 unsigned (10 / 5 = 2)
rem   x29, x1, x2    # x29 = x1 % x2 (10 % 5 = 0)
remu  x30, x1, x2    # x30 = x1 % x2 unsigned (10 % 5 = 0)


halt:
    slti x0, x0, -256

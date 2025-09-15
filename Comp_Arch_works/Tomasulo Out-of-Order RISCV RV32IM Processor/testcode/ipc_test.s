depend_test.s:
.align 4
.section .text
.globl _start
    # This program consists of small snippets
    # containing RAW, WAW, and WAR hazards

    # This test is NOT exhaustive

_start:  
  li x1, 0x00000001      # Load immediate value 1 into x1
    li x2, 0x00000002      # Load immediate value 2 into x2
    li x3, 0x00000003      # Load immediate value 3 into x3
    li x4, 0x00000004      # Load immediate value 4 into x4
    li x5, 0xFFFFFFFF      # Load -1 (all bits set) into x5
    li x6, 0x00000000      # Load 0 into x6
    li x7, 0x00000007      # Load 7 into x7

    # Arithmetic and Logical Instructions
    add  x3, x1, x2        # x3 = x1 + x2 = 1 + 2
    sub  x4, x2, x1        # x4 = x2 - x1 = 2 - 1
    sll  x5, x1, x2        # x5 = x1 << x2 (logical shift left)
    srl  x6, x4, x1        # x6 = x4 >> x1 (logical shift right)
    sra  x7, x5, x1        # x7 = x5 >> x1 (arithmetic shift right)

    and  x3, x1, x2        # x3 = x1 & x2 (bitwise AND)
    or   x4, x2, x1        # x4 = x2 | x1 (bitwise OR)
    xor  x5, x3, x4        # x5 = x3 ^ x4 (bitwise XOR)

    # Immediate Arithmetic and Logical Instructions
    addi x1, x0, 5         # x1 = x0 + 5 = 5
    slti x2, x1, 10        # x2 = (x1 < 10) ? 1 : 0
    sltiu x3, x1, 10       # x3 = (x1 < 10 unsigned) ? 1 : 0
    andi x4, x1, 0x0F      # x4 = x1 & 0x0F
    ori  x5, x1, 0xF0      # x5 = x1 | 0xF0
    xori x6, x1, 0xAA      # x6 = x1 ^ 0xAA

    # Comparison Instructions
    slt  x7, x1, x2        # x7 = (x1 < x2) ? 1 : 0
    sltu x3, x1, x2        # x3 = (x1 < x2 unsigned) ? 1 : 0

    # Shift Instructions with Immediate
    slli x4, x1, 2         # x4 = x1 << 2
    srli x5, x2, 1         # x5 = x2 >> 1 (logical shift right)
    srai x6, x7, 1         # x6 = x7 >> 1 (arithmetic shift right)

slti       x0, x0, -256               # this is the magic instruction to end the simulation 
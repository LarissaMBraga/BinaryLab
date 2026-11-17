; Extended ISA demonstration
; All calculations execute on the SystemVerilog CPU.

ADDI R1, 12
ADDI R2, 2

; 12 << 2 = 48
SHL R1, R2

; 48 >> 2 = 12
SHR R1, R2

; Arithmetic shift: -8 >> 2 = -2 (254)
ADDI R3, -8
SAR R3, R2

; Rotate left and right
ADDI R4, 85
ADDI R5, 1
ROL R4, R5
ROR R4, R5

; Bitwise inversion: 85 -> 170
NOT R4

; Multiplication and division
ADDI R6, 6
ADDI R7, 3
MUL R6, R7
DIV R6, R7

HALT
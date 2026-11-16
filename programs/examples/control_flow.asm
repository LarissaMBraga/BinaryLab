
ADDI R1, 5
ADDI R2, 5

CMP R1, R2
BEQ equal

ADDI R3, 99

equal:
ADDI R3, 10
ADDI R2, 1

CMP R1, R2
BNE different

ADDI R4, 99

different:
JMP finish

ADDI R5, 99

finish:
HALT

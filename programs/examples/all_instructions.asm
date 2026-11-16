NOP

ADDI R1, 10
ADDI R2, 5
ADDI R4, 10

MOV R3, R1
ADD R3, R2
SUB R3, R2

AND R3, R2
OR R3, R1
XOR R3, R2

ST R3, [R4 + 1]
LD R5, [R4 + 1]

CMP R1, R2
BEQ should_not_equal

CMP R1, R1
BNE should_not_differ

BEQ equal

ADDI R6, 99

equal:
CMP R1, R2
BNE different

ADDI R6, 98

different:
JMP finish

ADDI R6, 97

should_not_equal:
HALT

should_not_differ:
HALT

finish:
HALT
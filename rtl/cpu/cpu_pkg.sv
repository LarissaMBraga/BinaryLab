package cpu_pkg;

    parameter int DATA_WIDTH = 8;
    parameter int ADDRESS_WIDTH = 16;
    parameter int INSTRUCTION_WIDTH = 16;
    parameter int REGISTER_COUNT = 8;
    parameter int REGISTER_WIDTH = 3;
    parameter int MEMORY_DEPTH = 65536;

    parameter int OPCODE_WIDTH = 4;
    parameter int OPCODE_MSB = 15;
    parameter int OPCODE_LSB = 12;

    typedef enum logic [3:0] {
        OP_NOP = 4'h0, OP_HALT = 4'h1,
        OP_MOV = 4'h2, OP_ADD = 4'h3,
        OP_SUB = 4'h4, OP_AND = 4'h5,
        OP_OR = 4'h6, OP_XOR = 4'h7,
        OP_ADDI = 4'h8, OP_LD = 4'h9,
        OP_ST = 4'hA, OP_JMP = 4'hB,
        OP_BEQ = 4'hC, OP_BNE = 4'hD,
        OP_CMP = 4'hE, OP_EXT = 4'hF
    } opcode_t;

    typedef enum logic [2:0] {
        REG_R0 = 3'd0, REG_R1 = 3'd1,
        REG_R2 = 3'd2, REG_R3 = 3'd3,
        REG_R4 = 3'd4, REG_R5 = 3'd5,
        REG_R6 = 3'd6, REG_R7 = 3'd7
    } register_t;

    typedef struct packed {
        logic zero;
        logic carry;
        logic negative;
        logic overflow;
    } flags_t;

    typedef enum logic [3:0] {
        ALU_PASS = 4'd0,
        ALU_ADD = 4'd1,
        ALU_SUB = 4'd2,
        ALU_AND = 4'd3,
        ALU_OR = 4'd4,
        ALU_XOR = 4'd5,
        ALU_SHL = 4'd6,
        ALU_SHR = 4'd7,
        ALU_SAR = 4'd8,
        ALU_ROL = 4'd9,
        ALU_ROR = 4'd10,
        ALU_NOT = 4'd11,
        ALU_MUL = 4'd12,
        ALU_DIV = 4'd13
    } alu_operation_t;

    typedef enum logic [1:0] {
        FORMAT_R = 2'b00,
        FORMAT_I = 2'b01,
        FORMAT_M = 2'b10,
        FORMAT_B = 2'b11
    } instruction_format_t;

endpackage

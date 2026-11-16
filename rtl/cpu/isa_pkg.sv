package isa_pkg;

    // Instruction width
    parameter int INSTRUCTION_WIDTH = 16;

    // Data width
    parameter int DATA_WIDTH = 8;

    // Register configuration
    parameter int REGISTER_COUNT = 8;
    parameter int REGISTER_ADDRESS_WIDTH = 3;

    // Address configuration
    parameter int ADDRESS_WIDTH = 16;

    // Opcode definitions
    typedef enum logic [3:0] {
        OP_NOP    = 4'h0,
        OP_HALT   = 4'h1,
        OP_MOV    = 4'h2,
        OP_LDI    = 4'h3,
        OP_ADD    = 4'h4,
        OP_SUB    = 4'h5,
        OP_AND    = 4'h6,
        OP_OR     = 4'h7,
        OP_XOR    = 4'h8,
        OP_NOT    = 4'h9,
        OP_SHL    = 4'hA,
        OP_SHR    = 4'hB,
        OP_LOAD   = 4'hC,
        OP_STORE  = 4'hD,
        OP_BRANCH = 4'hE,
        OP_SYSTEM = 4'hF
    } opcode_t;

    // Instruction format definitions
    typedef enum logic [1:0] {
        FORMAT_R = 2'b00,
        FORMAT_I = 2'b01,
        FORMAT_M = 2'b10,
        FORMAT_B = 2'b11
    } instruction_format_t;

    // Status flag bit positions
    localparam int FLAG_ZERO     = 0;
    localparam int FLAG_CARRY    = 1;
    localparam int FLAG_NEGATIVE = 2;
    localparam int FLAG_OVERFLOW = 3;

    // Branch condition definitions
    typedef enum logic [3:0] {
        COND_ALWAYS    = 4'h0,
        COND_ZERO      = 4'h1,
        COND_NOT_ZERO  = 4'h2,
        COND_CARRY     = 4'h3,
        COND_NOT_CARRY = 4'h4,
        COND_NEGATIVE  = 4'h5,
        COND_NOT_NEG   = 4'h6,
        COND_OVERFLOW  = 4'h7,
        COND_NOT_OVF   = 4'h8,
        COND_LESS      = 4'h9,
        COND_GREATER_EQ = 4'hA
    } branch_condition_t;

    // System operation definitions
    typedef enum logic [3:0] {
        SYS_PUSH = 4'h0,
        SYS_POP  = 4'h1,
        SYS_CALL = 4'h2,
        SYS_RET  = 4'h3,
        SYS_CMP  = 4'h4,
        SYS_JMP  = 4'h5
    } system_operation_t;

    // Register pair definitions
    typedef enum logic [1:0] {
        PAIR_0 = 2'b00,
        PAIR_1 = 2'b01,
        PAIR_2 = 2'b10,
        PAIR_3 = 2'b11
    } register_pair_t;

endpackage

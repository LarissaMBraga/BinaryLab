module control_unit (
    input logic clk,
    input logic reset,
    input logic [cpu_pkg::INSTRUCTION_WIDTH-1:0] instruction,
    input logic [cpu_pkg::ADDRESS_WIDTH-1:0] pc_current,
    input cpu_pkg::flags_t flags,
    output logic [2:0] state,
    output logic [cpu_pkg::REGISTER_WIDTH-1:0] destination_register,
    output logic [cpu_pkg::REGISTER_WIDTH-1:0] source_register,
    output logic [cpu_pkg::REGISTER_WIDTH-1:0] base_register,
    output logic [cpu_pkg::DATA_WIDTH-1:0] immediate,
    output logic signed [5:0] memory_offset,
    output logic signed [11:0] branch_offset,
    output logic register_write_enable,
    output logic memory_read_enable,
    output logic memory_write_enable,
    output logic flags_write_enable,
    output logic alu_operand_immediate,
    output cpu_pkg::alu_operation_t alu_operation,
    output logic writeback_from_memory,
    output logic pc_enable,
    output logic pc_load_enable,
    output logic [cpu_pkg::ADDRESS_WIDTH-1:0] pc_load_address,
    output logic halted,
    output logic illegal_instruction
);

    import cpu_pkg::*;

    typedef enum logic [2:0] {
        FETCH = 3'd0, DECODE = 3'd1,
        EXECUTE = 3'd2, MEMORY = 3'd3,
        WRITEBACK = 3'd4, HALTED = 3'd5,
        ILLEGAL = 3'd6
    } state_t;

    state_t current_state, next_state;
    opcode_t opcode;

    assign state = current_state;
    assign opcode = opcode_t'(instruction[15:12]);

    assign destination_register =
        opcode == OP_EXT ? instruction[8:6] : instruction[11:9];

    assign source_register =
        opcode == OP_EXT ? instruction[5:3] : instruction[8:6];

    assign base_register = instruction[8:6];
    assign immediate = {{2{instruction[8]}}, instruction[8:0]};
    assign memory_offset = instruction[5:0];
    assign branch_offset = instruction[11:0];

    function automatic logic instruction_is_valid(input logic [15:0] encoded);
        case (encoded[15:12])
            OP_NOP, OP_HALT:
                instruction_is_valid = encoded[11:0] == 12'b0;
            OP_MOV, OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR, OP_CMP:
                instruction_is_valid = encoded[5:0] == 6'b0;
            OP_ADDI, OP_LD, OP_ST, OP_JMP, OP_BEQ, OP_BNE:
                instruction_is_valid = 1'b1;
            OP_EXT:
                instruction_is_valid = encoded[2:0] == 3'b000;
            default:
                instruction_is_valid = 1'b0;
        endcase
    endfunction

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= FETCH;
        else
            current_state <= next_state;
    end

    always_comb begin
        next_state = current_state;
        register_write_enable = 1'b0;
        memory_read_enable = 1'b0;
        memory_write_enable = 1'b0;
        flags_write_enable = 1'b0;
        alu_operand_immediate = 1'b0;
        alu_operation = ALU_PASS;
        writeback_from_memory = 1'b0;
        pc_enable = 1'b0;
        pc_load_enable = 1'b0;
        pc_load_address = '0;
        halted = 1'b0;
        illegal_instruction = 1'b0;

        case (current_state)
            FETCH: begin
                pc_enable = 1'b1;
                next_state = DECODE;
            end

            DECODE: begin
                if (!instruction_is_valid(instruction))
                    next_state = ILLEGAL;
                else if (opcode == OP_HALT)
                    next_state = HALTED;
                else
                    next_state = EXECUTE;
            end

            EXECUTE: begin
                case (opcode)
                    OP_NOP: next_state = FETCH;

                    OP_MOV: begin
                        alu_operation = ALU_PASS;
                        next_state = WRITEBACK;
                    end

                    OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR: begin
                        case (opcode)
                            OP_ADD: alu_operation = ALU_ADD;
                            OP_SUB: alu_operation = ALU_SUB;
                            OP_AND: alu_operation = ALU_AND;
                            OP_OR: alu_operation = ALU_OR;
                            OP_XOR: alu_operation = ALU_XOR;
                            default: alu_operation = ALU_PASS;
                        endcase
                        flags_write_enable = 1'b1;
                        next_state = WRITEBACK;
                    end

                    OP_CMP: begin
                        alu_operation = ALU_SUB;
                        flags_write_enable = 1'b1;
                        next_state = FETCH;
                    end

                    OP_ADDI: begin
                        alu_operation = ALU_ADD;
                        alu_operand_immediate = 1'b1;
                        flags_write_enable = 1'b1;
                        next_state = WRITEBACK;
                    end

                    OP_EXT: begin
                        case (instruction[11:9])
                            3'd0: alu_operation = ALU_SHL;
                            3'd1: alu_operation = ALU_SHR;
                            3'd2: alu_operation = ALU_SAR;
                            3'd3: alu_operation = ALU_ROL;
                            3'd4: alu_operation = ALU_ROR;
                            3'd5: alu_operation = ALU_NOT;
                            3'd6: alu_operation = ALU_MUL;
                            3'd7: alu_operation = ALU_DIV;
                            default: alu_operation = ALU_PASS;
                        endcase
                        flags_write_enable = 1'b1;
                        next_state = WRITEBACK;
                    end

                    OP_LD, OP_ST: next_state = MEMORY;

                    OP_JMP: begin
                        pc_load_enable = 1'b1;
                        pc_load_address = pc_current +
                            ({{4{instruction[11]}}, instruction[11:0]} << 1);
                        next_state = FETCH;
                    end

                    OP_BEQ, OP_BNE: begin
                        if ((opcode == OP_BEQ && flags.zero) ||
                            (opcode == OP_BNE && !flags.zero)) begin
                            pc_load_enable = 1'b1;
                            pc_load_address = pc_current +
                                ({{4{instruction[11]}}, instruction[11:0]} << 1);
                        end
                        next_state = FETCH;
                    end

                    default: next_state = ILLEGAL;
                endcase
            end

            MEMORY: begin
                if (opcode == OP_LD) begin
                    memory_read_enable = 1'b1;
                    next_state = WRITEBACK;
                end else if (opcode == OP_ST) begin
                    memory_write_enable = 1'b1;
                    next_state = FETCH;
                end else begin
                    next_state = ILLEGAL;
                end
            end

            WRITEBACK: begin
                register_write_enable = 1'b1;
                writeback_from_memory = opcode == OP_LD;
                next_state = FETCH;
            end

            HALTED: begin
                halted = 1'b1;
                next_state = HALTED;
            end

            ILLEGAL: begin
                illegal_instruction = 1'b1;
                next_state = ILLEGAL;
            end

            default: next_state = ILLEGAL;
        endcase
    end

endmodule

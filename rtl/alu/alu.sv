module alu (
    input logic [cpu_pkg::DATA_WIDTH-1:0] operand_a,
    input logic [cpu_pkg::DATA_WIDTH-1:0] operand_b,
    input cpu_pkg::alu_operation_t operation,
    output logic [cpu_pkg::DATA_WIDTH-1:0] result,
    output cpu_pkg::flags_t flags
);

    import cpu_pkg::*;

    logic [DATA_WIDTH:0] extended_result;
    logic [2*DATA_WIDTH-1:0] rotate_value;
    integer shift_amount;

    always_comb begin
        result = '0;
        flags = '0;
        extended_result = '0;
        rotate_value = '0;
        shift_amount = operand_b[2:0];

        case (operation)
            ALU_PASS:
                result = operand_a;

            ALU_ADD: begin
                extended_result = {1'b0, operand_a} + {1'b0, operand_b};
                result = extended_result[DATA_WIDTH-1:0];
                flags.carry = extended_result[DATA_WIDTH];
                flags.overflow =
                    (~(operand_a[DATA_WIDTH-1] ^ operand_b[DATA_WIDTH-1])) &
                    (result[DATA_WIDTH-1] ^ operand_a[DATA_WIDTH-1]);
            end

            ALU_SUB: begin
                extended_result = {1'b0, operand_a} - {1'b0, operand_b};
                result = extended_result[DATA_WIDTH-1:0];
                flags.carry = operand_a >= operand_b;
                flags.overflow =
                    (operand_a[DATA_WIDTH-1] ^ operand_b[DATA_WIDTH-1]) &
                    (result[DATA_WIDTH-1] ^ operand_a[DATA_WIDTH-1]);
            end

            ALU_AND: result = operand_a & operand_b;
            ALU_OR: result = operand_a | operand_b;
            ALU_XOR: result = operand_a ^ operand_b;
            ALU_SHL: result = operand_a << shift_amount;
            ALU_SHR: result = operand_a >> shift_amount;
            ALU_SAR: result = $signed(operand_a) >>> shift_amount;

            ALU_ROL: begin
                rotate_value = {operand_a, operand_a} << shift_amount;
                result = rotate_value[2*DATA_WIDTH-1:DATA_WIDTH] |
                         rotate_value[DATA_WIDTH-1:0];
            end

            ALU_ROR: begin
                rotate_value = {operand_a, operand_a} >> shift_amount;
                result = rotate_value[2*DATA_WIDTH-1:DATA_WIDTH];
            end

            ALU_NOT: result = ~operand_a;
            ALU_MUL: result = operand_a * operand_b;

            ALU_DIV: begin
                if (operand_b == 0) begin
                    result = '0;
                    flags.carry = 1'b1;
                end else begin
                    result = operand_a / operand_b;
                end
            end

            default: begin
                result = '0;
                flags = '0;
            end
        endcase

        flags.zero = result == '0;
        flags.negative = result[DATA_WIDTH-1];
    end

endmodule

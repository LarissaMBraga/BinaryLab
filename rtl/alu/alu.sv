module alu (
    input  logic [cpu_pkg::DATA_WIDTH-1:0] operand_a,
    input  logic [cpu_pkg::DATA_WIDTH-1:0] operand_b,
    input  cpu_pkg::alu_operation_t       operation,

    output logic [cpu_pkg::DATA_WIDTH-1:0] result,
    output cpu_pkg::flags_t                flags
);

    import cpu_pkg::*;

    logic [DATA_WIDTH:0] extended_result;

    always_comb begin
        result = '0;
        flags = '0;
        extended_result = '0;

        case (operation)

            ALU_PASS: begin
                result = operand_a;
            end

            ALU_ADD: begin
                extended_result =
                    {1'b0, operand_a} + {1'b0, operand_b};

                result = extended_result[DATA_WIDTH-1:0];
                flags.carry = extended_result[DATA_WIDTH];

                flags.overflow =
                    (~(operand_a[DATA_WIDTH-1] ^ operand_b[DATA_WIDTH-1])) &
                    (result[DATA_WIDTH-1] ^ operand_a[DATA_WIDTH-1]);
            end

            ALU_SUB: begin
                extended_result =
                    {1'b0, operand_a} - {1'b0, operand_b};

                result = extended_result[DATA_WIDTH-1:0];
                flags.carry = (operand_a >= operand_b);

                flags.overflow =
                    (operand_a[DATA_WIDTH-1] ^ operand_b[DATA_WIDTH-1]) &
                    (result[DATA_WIDTH-1] ^ operand_a[DATA_WIDTH-1]);
            end

            ALU_AND: begin
                result = operand_a & operand_b;
            end

            ALU_OR: begin
                result = operand_a | operand_b;
            end

            ALU_XOR: begin
                result = operand_a ^ operand_b;
            end

            default: begin
                result = '0;
                flags = '0;
            end

        endcase

        flags.zero = (result == '0);
        flags.negative = result[DATA_WIDTH-1];
    end

endmodule
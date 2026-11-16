module cpu #(
    parameter integer INSTRUCTION_MEMORY_DEPTH = cpu_pkg::MEMORY_DEPTH,
    parameter integer DATA_MEMORY_DEPTH = cpu_pkg::MEMORY_DEPTH,
    parameter INSTRUCTION_INIT_FILE = "",
    parameter INSTRUCTION_INIT_FORMAT = "HEX"
) (
    input  logic clk,
    input  logic reset,
    input  logic [7:0] gpio_input,
    output logic [7:0] gpio_output,
    output logic [7:0] gpio_direction,
    output logic [cpu_pkg::ADDRESS_WIDTH-1:0] pc,
    output logic [2:0] state,
    output logic halted,
    output logic illegal_instruction
);

    import cpu_pkg::*;

    localparam logic [2:0] STATE_FETCH = 3'd0;
    localparam logic [2:0] STATE_EXECUTE = 3'd2;

    localparam logic [ADDRESS_WIDTH-1:0] GPIO_DATA_ADDRESS = 16'h00F0;
    localparam logic [ADDRESS_WIDTH-1:0] GPIO_DIRECTION_ADDRESS = 16'h00F1;

    logic [INSTRUCTION_WIDTH-1:0] fetched_instruction;
    logic [INSTRUCTION_WIDTH-1:0] instruction_register;

    logic [REGISTER_WIDTH-1:0] destination_register;
    logic [REGISTER_WIDTH-1:0] source_register;
    logic [REGISTER_WIDTH-1:0] base_register;

    logic [DATA_WIDTH-1:0] immediate;
    logic signed [5:0] memory_offset;
    logic signed [11:0] branch_offset;

    logic register_write_enable;
    logic memory_read_enable;
    logic memory_write_enable;
    logic flags_write_enable;

    logic alu_operand_immediate;
    alu_operation_t alu_operation;
    logic writeback_from_memory;

    logic pc_enable;
    logic pc_load_enable;
    logic [ADDRESS_WIDTH-1:0] pc_load_address;

    logic [DATA_WIDTH-1:0] register_read_data_a;
    logic [DATA_WIDTH-1:0] register_read_data_b;
    logic [DATA_WIDTH-1:0] register_write_data;

    logic [DATA_WIDTH-1:0] alu_operand_a;
    logic [DATA_WIDTH-1:0] alu_operand_b;
    logic [DATA_WIDTH-1:0] alu_result;
    logic [DATA_WIDTH-1:0] alu_result_register;
    flags_t alu_flags;
    flags_t flags_register;

    logic [ADDRESS_WIDTH-1:0] data_memory_address;
    logic [DATA_WIDTH-1:0] data_memory_read_data;
    logic [DATA_WIDTH-1:0] data_memory_read_register;
    logic [DATA_WIDTH-1:0] ram_read_data;
    logic [DATA_WIDTH-1:0] gpio_read_data;

    logic gpio_address_selected;
    logic ram_read_enable;
    logic ram_write_enable;
    logic gpio_write_enable;

    program_counter program_counter_instance (
        .clk(clk),
        .reset(reset),
        .enable(pc_enable),
        .load_enable(pc_load_enable),
        .load_address(pc_load_address),
        .pc(pc)
    );

    instruction_memory #(
        .MEMORY_DEPTH(INSTRUCTION_MEMORY_DEPTH),
        .INIT_FILE(INSTRUCTION_INIT_FILE),
        .INIT_FORMAT(INSTRUCTION_INIT_FORMAT)
    ) instruction_memory_instance (
        .read_enable(1'b1),
        .address(pc),
        .instruction(fetched_instruction)
    );

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            instruction_register <= '0;
        end else if (state == STATE_FETCH) begin
            instruction_register <= fetched_instruction;
        end
    end

    control_unit control_unit_instance (
        .clk(clk),
        .reset(reset),
        .instruction(instruction_register),
        .pc_current(pc),
        .flags(flags_register),
        .state(state),
        .destination_register(destination_register),
        .source_register(source_register),
        .base_register(base_register),
        .immediate(immediate),
        .memory_offset(memory_offset),
        .branch_offset(branch_offset),
        .register_write_enable(register_write_enable),
        .memory_read_enable(memory_read_enable),
        .memory_write_enable(memory_write_enable),
        .flags_write_enable(flags_write_enable),
        .alu_operand_immediate(alu_operand_immediate),
        .alu_operation(alu_operation),
        .writeback_from_memory(writeback_from_memory),
        .pc_enable(pc_enable),
        .pc_load_enable(pc_load_enable),
        .pc_load_address(pc_load_address),
        .halted(halted),
        .illegal_instruction(illegal_instruction)
    );

    register_file register_file_instance (
        .clk(clk),
        .reset(reset),
        .write_enable(register_write_enable),
        .write_address(destination_register),
        .write_data(register_write_data),
        .read_address_a(destination_register),
        .read_address_b(source_register),
        .read_data_a(register_read_data_a),
        .read_data_b(register_read_data_b)
    );

    always_comb begin
        if (instruction_register[15:12] == OP_MOV) begin
            alu_operand_a = register_read_data_b;
        end else begin
            alu_operand_a = register_read_data_a;
        end

        if (alu_operand_immediate) begin
            alu_operand_b = immediate;
        end else begin
            alu_operand_b = register_read_data_b;
        end
    end

    alu alu_instance (
        .operand_a(alu_operand_a),
        .operand_b(alu_operand_b),
        .operation(alu_operation),
        .result(alu_result),
        .flags(alu_flags)
    );

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            alu_result_register <= '0;
        end else if (state == STATE_EXECUTE) begin
            alu_result_register <= alu_result;
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            flags_register <= '0;
        end else if (flags_write_enable) begin
            flags_register <= alu_flags;
        end
    end

    assign data_memory_address =
        {8'b0, register_read_data_b} +
        {{10{memory_offset[5]}}, memory_offset};

    memory_bus #(
        .DATA_MEMORY_DEPTH(DATA_MEMORY_DEPTH)
    ) memory_bus_instance (
        .clk(clk),
        .reset(reset),
        .read_enable(memory_read_enable),
        .write_enable(memory_write_enable),
        .address(data_memory_address),
        .write_data(register_read_data_a),
        .read_data(data_memory_read_data),
        .gpio_input(gpio_input),
        .gpio_output(gpio_output),
        .gpio_direction(gpio_direction)
    );
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            data_memory_read_register <= '0;
        end else if (memory_read_enable) begin
            data_memory_read_register <= data_memory_read_data;
        end
    end

    always_comb begin
        if (writeback_from_memory) begin
            register_write_data = data_memory_read_register;
        end else begin
            register_write_data = alu_result_register;
        end
    end

endmodule
`timescale 1ns/1ps

module tb_control_unit;

    import cpu_pkg::*;

    logic clk;
    logic reset;

    logic [INSTRUCTION_WIDTH-1:0] instruction;
    logic [ADDRESS_WIDTH-1:0] pc_current;
    flags_t flags;

    logic [2:0] state;

    logic [REGISTER_WIDTH-1:0] destination_register;
    logic [REGISTER_WIDTH-1:0] source_register;
    logic [REGISTER_WIDTH-1:0] base_register;

    logic [DATA_WIDTH-1:0] immediate;
    logic signed [5:0] memory_offset;
    logic signed [11:0] branch_offset;

    logic register_write_enable;
    logic memory_read_enable;
    logic memory_write_enable;

    logic alu_operand_immediate;
    alu_operation_t alu_operation;

    logic writeback_from_memory;

    logic pc_enable;
    logic pc_load_enable;
    logic [ADDRESS_WIDTH-1:0] pc_load_address;

    logic halted;
    logic illegal_instruction;

    integer test_count;

    control_unit dut (
        .clk(clk),
        .reset(reset),
        .instruction(instruction),
        .pc_current(pc_current),
        .flags(flags),
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
        .alu_operand_immediate(alu_operand_immediate),
        .alu_operation(alu_operation),
        .writeback_from_memory(writeback_from_memory),
        .pc_enable(pc_enable),
        .pc_load_enable(pc_load_enable),
        .pc_load_address(pc_load_address),
        .halted(halted),
        .illegal_instruction(illegal_instruction)
    );

    always #5 clk = ~clk;

    task automatic tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task automatic check(
        input logic condition,
        input string test_name
    );
        begin
            test_count = test_count + 1;

            if (condition !== 1'b1) begin
                $display("FAIL: %s", test_name);
                $fatal(1);
            end

            $display("PASS: %s", test_name);
        end
    endtask

    task automatic start_instruction(
        input logic [15:0] encoded_instruction
    );
        begin
            @(negedge clk);
            reset = 1'b1;
            #1;
            reset = 1'b0;
            instruction = encoded_instruction;

            tick();
            tick();
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b0;
        instruction = 16'h0000;
        pc_current = 16'h0000;
        flags = '0;
        test_count = 0;

        $display("Starting Control Unit tests...");

        reset = 1'b1;
        #1;
        check(state == 3'd0, "Reset enters FETCH");

        reset = 1'b0;

        #1;
        check(pc_enable, "FETCH enables PC");

        tick();
        check(state == 3'd1, "FETCH transitions to DECODE");

        tick();
        check(state == 3'd2, "Valid instruction enters EXECUTE");

        $display("Testing arithmetic instruction decoding...");

        start_instruction({OP_ADD, 3'd1, 3'd2, 6'b0});
        #1;
        check(alu_operation == ALU_ADD, "ADD selects ALU_ADD");

        tick();
        check(register_write_enable, "ADD enables register writeback");

        tick();
        check(state == 3'd0, "WRITEBACK returns to FETCH");

        $display("Testing immediate instruction...");

        start_instruction({OP_ADDI, 3'd1, 9'h005});
        #1;
        check(alu_operand_immediate, "ADDI selects immediate operand");
        check(immediate == 8'h05, "ADDI immediate is decoded");

        $display("Testing load instruction...");

        start_instruction({OP_LD, 3'd1, 3'd2, 6'h04});
        tick();
        check(memory_read_enable, "LD enables memory read");

        tick();
        check(register_write_enable, "LD enables register writeback");
        check(writeback_from_memory, "LD selects memory writeback");

        $display("Testing store instruction...");

        start_instruction({OP_ST, 3'd1, 3'd2, 6'h04});
        tick();
        check(memory_write_enable, "ST enables memory write");

        $display("Testing unconditional jump...");

        pc_current = 16'h0100;
        start_instruction({OP_JMP, 12'h003});
        #1;
        check(pc_load_enable, "JMP enables PC load");
        check(pc_load_address == 16'h0106, "JMP calculates relative target");

        $display("Testing conditional branches...");

        flags.zero = 1'b1;
        start_instruction({OP_BEQ, 12'h002});
        #1;
        check(pc_load_enable, "BEQ branches when zero is set");

        flags.zero = 1'b0;
        start_instruction({OP_BEQ, 12'h002});
        #1;
        check(!pc_load_enable, "BEQ does not branch when zero is clear");

        flags.zero = 1'b0;
        start_instruction({OP_BNE, 12'h002});
        #1;
        check(pc_load_enable, "BNE branches when zero is clear");

        flags.zero = 1'b1;
        start_instruction({OP_BNE, 12'h002});
        #1;
        check(!pc_load_enable, "BNE does not branch when zero is set");

        $display("Testing HALT...");

        start_instruction({OP_HALT, 12'b0});
        check(state == 3'd5, "HALT enters HALTED state");
        check(halted, "HALT asserts halted signal");

        tick();
        check(halted, "HALTED state is persistent");

        $display("Testing illegal instructions...");

        reset = 1'b1;
        #1;
        reset = 1'b0;

        start_instruction({OP_EXT, 12'h000});
        check(state == 3'd6, "EXT enters ILLEGAL state");
        check(illegal_instruction, "EXT asserts illegal instruction");

        $display("Testing reserved bits...");

        reset = 1'b1;
        #1;
        reset = 1'b0;

        start_instruction({OP_ADD, 3'd1, 3'd2, 6'b000001});
        check(state == 3'd6, "Nonzero reserved bits are rejected");

        $display("--------------------------------");
        $display("All %0d Control Unit checks passed!", test_count);
        $display("--------------------------------");

        $finish;
    end

endmodule
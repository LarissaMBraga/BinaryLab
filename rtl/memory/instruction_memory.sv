
`timescale 1ns/1ps

module instruction_memory #(
    parameter MEMORY_DEPTH = 65536,
    parameter INIT_FILE = ""
) (
    input  logic        read_enable,
    input  logic [15:0] address,
    output logic [15:0] instruction
);

    logic [7:0] memory [0:MEMORY_DEPTH-1];

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, memory);
        end
    end

    always_comb begin
        instruction = 16'h0000;

        if (read_enable && address <= MEMORY_DEPTH - 2) begin
            instruction = {
                memory[address],
                memory[address + 16'd1]
            };
        end
    end

endmodule

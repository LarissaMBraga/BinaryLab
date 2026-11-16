
`timescale 1ns/1ps

module data_memory #(
    parameter MEMORY_DEPTH = 65536
) (
    input  logic        clk,
    input  logic        read_enable,
    input  logic        write_enable,
    input  logic [15:0] address,
    input  logic [7:0]  write_data,
    output logic [7:0]  read_data
);

    logic [7:0] memory [0:MEMORY_DEPTH-1];

    always_comb begin
        read_data = 8'h00;

        if (read_enable && address < MEMORY_DEPTH) begin
            read_data = memory[address];
        end
    end

    always_ff @(posedge clk) begin
        if (write_enable && address < MEMORY_DEPTH) begin
            memory[address] <= write_data;
        end
    end

endmodule

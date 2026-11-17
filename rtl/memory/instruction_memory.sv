`timescale 1ns/1ps

module instruction_memory #(
    parameter MEMORY_DEPTH = 65536,
    parameter INIT_FILE = "",
    parameter INIT_FORMAT = "HEX"
) (
    input  logic        read_enable,
    input  logic [15:0] address,
    output logic [15:0] instruction
);

    logic [7:0] memory [0:MEMORY_DEPTH-1];

    integer file_handle;
    integer file_byte;
    integer byte_count;
    integer index;

    reg [8*1024-1:0] runtime_init_file;
    reg [8*16-1:0] runtime_format;

    initial begin
        for (index = 0; index < MEMORY_DEPTH; index = index + 1) begin
            memory[index] = 8'h00;
        end

        runtime_init_file = "";
        runtime_format = "";

        if ($value$plusargs("program=%s", runtime_init_file)) begin
            file_handle = $fopen(runtime_init_file, "rb");

            if (file_handle == 0) begin
                $fatal(1, "Unable to open binary program: %0s", runtime_init_file);
            end

            byte_count = 0;

            while (1) begin
                file_byte = $fgetc(file_handle);

                if (file_byte == -1) begin
                    break;
                end

                if (byte_count >= MEMORY_DEPTH) begin
                    $fclose(file_handle);
                    $fatal(1, "Binary program exceeds instruction memory capacity.");
                end

                memory[byte_count] = file_byte[7:0];
                byte_count = byte_count + 1;
            end

            $fclose(file_handle);

            if (byte_count == 0 || byte_count % 2 != 0) begin
                $fatal(1, "Invalid binary program size: %0d bytes.", byte_count);
            end

            $display("PROGRAM_BYTES=%0d", byte_count);
            $display("PROGRAM_LOADED=%0s", runtime_init_file);
        end
        else if (INIT_FILE != "") begin
            if (INIT_FORMAT == "HEX") begin
                $readmemh(INIT_FILE, memory);
            end
            else if (INIT_FORMAT == "BIN") begin
                file_handle = $fopen(INIT_FILE, "rb");

                if (file_handle == 0) begin
                    $fatal(1, "Unable to open binary instruction file: %s", INIT_FILE);
                end

                byte_count = 0;

                while (1) begin
                    file_byte = $fgetc(file_handle);

                    if (file_byte == -1) begin
                        break;
                    end

                    if (byte_count >= MEMORY_DEPTH) begin
                        $fclose(file_handle);
                        $fatal(1, "Binary instruction file exceeds memory capacity.");
                    end

                    memory[byte_count] = file_byte[7:0];
                    byte_count = byte_count + 1;
                end

                $fclose(file_handle);

                if (byte_count % 2 != 0) begin
                    $fatal(1, "Binary instruction file must contain complete 16-bit words.");
                end

                $display("Loaded %0d bytes from binary file: %s", byte_count, INIT_FILE);
            end
            else begin
                $fatal(1, "Unsupported instruction memory format: %s", INIT_FORMAT);
            end
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

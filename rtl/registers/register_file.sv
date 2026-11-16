module register_file (
    input  logic clk,
    input  logic reset,

    input  logic write_enable,
    input  logic [cpu_pkg::REGISTER_WIDTH-1:0] write_address,
    input  logic [cpu_pkg::DATA_WIDTH-1:0] write_data,

    input  logic [cpu_pkg::REGISTER_WIDTH-1:0] read_address_a,
    input  logic [cpu_pkg::REGISTER_WIDTH-1:0] read_address_b,
    output logic [cpu_pkg::DATA_WIDTH-1:0] read_data_a,
    output logic [cpu_pkg::DATA_WIDTH-1:0] read_data_b
);

    import cpu_pkg::*;

    logic [DATA_WIDTH-1:0] registers [0:REGISTER_COUNT-1];

    integer index;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (index = 0; index < REGISTER_COUNT; index = index + 1) begin
                registers[index] <= '0;
            end
        end else if (write_enable) begin
            registers[write_address] <= write_data;
        end
    end

    assign read_data_a = registers[read_address_a];
    assign read_data_b = registers[read_address_b];

endmodule
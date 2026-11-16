module memory_bus #(
    parameter integer DATA_MEMORY_DEPTH = 65536
) (
    input  logic        clk,
    input  logic        reset,

    input  logic        read_enable,
    input  logic        write_enable,
    input  logic [15:0] address,
    input  logic [7:0]  write_data,
    output logic [7:0]  read_data,

    input  logic [7:0]  gpio_input,
    output logic [7:0]  gpio_output,
    output logic [7:0]  gpio_direction
);

    logic ram_select;
    logic gpio_select;

    logic ram_read_enable;
    logic ram_write_enable;
    logic gpio_write_enable;

    logic [7:0] ram_read_data;
    logic [7:0] gpio_read_data;

    address_decoder #(
        .DATA_MEMORY_DEPTH(DATA_MEMORY_DEPTH)
    ) address_decoder_instance (
        .read_enable(read_enable),
        .write_enable(write_enable),
        .address(address),
        .ram_select(ram_select),
        .gpio_select(gpio_select),
        .ram_read_enable(ram_read_enable),
        .ram_write_enable(ram_write_enable),
        .gpio_write_enable(gpio_write_enable)
    );

    data_memory #(
        .MEMORY_DEPTH(DATA_MEMORY_DEPTH)
    ) data_memory_instance (
        .clk(clk),
        .read_enable(ram_read_enable),
        .write_enable(ram_write_enable),
        .address(address),
        .write_data(write_data),
        .read_data(ram_read_data)
    );

    gpio gpio_instance (
        .clk(clk),
        .reset(reset),
        .write_enable(gpio_write_enable),
        .address(address[7:0]),
        .write_data(write_data),
        .input_data(gpio_input),
        .read_data(gpio_read_data),
        .output_data(gpio_output),
        .direction(gpio_direction)
    );

    always_comb begin
        if (gpio_select) begin
            read_data = gpio_read_data;
        end else if (ram_select) begin
            read_data = ram_read_data;
        end else begin
            read_data = 8'h00;
        end
    end

endmodule
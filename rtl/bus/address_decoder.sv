module address_decoder #(
    parameter integer DATA_MEMORY_DEPTH = 65536,
    parameter logic [15:0] GPIO_DATA_ADDRESS = 16'h00F0,
    parameter logic [15:0] GPIO_DIRECTION_ADDRESS = 16'h00F1
) (
    input  logic        read_enable,
    input  logic        write_enable,
    input  logic [15:0] address,
    output logic        ram_select,
    output logic        gpio_select,
    output logic        ram_read_enable,
    output logic        ram_write_enable,
    output logic        gpio_write_enable
);

    always_comb begin
        gpio_select =
            (address == GPIO_DATA_ADDRESS) ||
            (address == GPIO_DIRECTION_ADDRESS);

        ram_select =
            !gpio_select && (address < DATA_MEMORY_DEPTH);

        ram_read_enable = read_enable && ram_select;
        ram_write_enable = write_enable && ram_select;
        gpio_write_enable = write_enable && gpio_select;
    end

endmodule
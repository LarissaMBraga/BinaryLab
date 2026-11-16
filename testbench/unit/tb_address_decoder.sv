`timescale 1ns/1ps

module tb_address_decoder;

    logic read_enable;
    logic write_enable;
    logic [15:0] address;

    logic ram_select;
    logic gpio_select;
    logic ram_read_enable;
    logic ram_write_enable;
    logic gpio_write_enable;

    address_decoder #(.DATA_MEMORY_DEPTH(256)) dut (
        .read_enable(read_enable),
        .write_enable(write_enable),
        .address(address),
        .ram_select(ram_select),
        .gpio_select(gpio_select),
        .ram_read_enable(ram_read_enable),
        .ram_write_enable(ram_write_enable),
        .gpio_write_enable(gpio_write_enable)
    );

    initial begin
        read_enable = 1'b0;
        write_enable = 1'b0;
        address = 16'h0000;

        #10;

        address = 16'h0020;
        read_enable = 1'b1;
        #10;

        if (!ram_select || !ram_read_enable || gpio_select)
            $fatal(1, "RAM read decode failed.");

        address = 16'h0020;
        read_enable = 1'b0;
        write_enable = 1'b1;
        #10;

        if (!ram_select || !ram_write_enable || gpio_write_enable)
            $fatal(1, "RAM write decode failed.");

        address = 16'h00F0;
        #10;

        if (!gpio_select || !gpio_write_enable || ram_select)
            $fatal(1, "GPIO data address decode failed.");

        address = 16'h00F1;
        #10;

        if (!gpio_select || !gpio_write_enable || ram_select)
            $fatal(1, "GPIO direction address decode failed.");

        address = 16'hFFFF;
        #10;

        if (ram_select || gpio_select || ram_write_enable)
            $fatal(1, "Out-of-range address decode failed.");

        $display("ADDRESS DECODER TEST PASSED");
        $finish;
    end

endmodule
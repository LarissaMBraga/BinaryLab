
`timescale 1ns/1ps

module tb_data_memory;

    logic clk;
    logic read_enable;
    logic write_enable;
    logic [15:0] address;
    logic [7:0] write_data;
    logic [7:0] read_data;

    integer test_count;
    integer passed_count;

    data_memory dut (
        .clk(clk),
        .read_enable(read_enable),
        .write_enable(write_enable),
        .address(address),
        .write_data(write_data),
        .read_data(read_data)
    );

    always #5 clk = ~clk;

    task automatic check(
        input logic condition,
        input string test_name
    );
        begin
            test_count = test_count + 1;

            if (condition === 1'b1) begin
                passed_count = passed_count + 1;
                $display("PASS: %s", test_name);
            end else begin
                $display("FAIL: %s", test_name);
                $fatal(1);
            end
        end
    endtask

    task automatic write_byte(
        input logic [15:0] target_address,
        input logic [7:0] value
    );
        begin
            @(negedge clk);
            address = target_address;
            write_data = value;
            write_enable = 1'b1;

            @(posedge clk);
            #1;
            write_enable = 1'b0;
        end
    endtask

    initial begin
        clk = 1'b0;
        read_enable = 1'b0;
        write_enable = 1'b0;
        address = 16'h0000;
        write_data = 8'h00;
        test_count = 0;
        passed_count = 0;

        $display("Starting Data Memory tests...");

        write_byte(16'h0010, 8'hA5);

        address = 16'h0010;
        read_enable = 1'b1;
        #1;
        check(read_data == 8'hA5,
              "Reads previously written byte");

        write_byte(16'h0010, 8'h3C);

        address = 16'h0010;
        #1;
        check(read_data == 8'h3C,
              "Overwrites existing memory value");

        write_byte(16'h0020, 8'h7F);

        address = 16'h0010;
        #1;
        check(read_data == 8'h3C,
              "Writing another address preserves previous data");

        address = 16'h0020;
        #1;
        check(read_data == 8'h7F,
              "Stores data at independent addresses");

        read_enable = 1'b0;
        #1;
        check(read_data == 8'h00,
              "Disabled read returns zero");

        write_byte(16'h0030, 8'hAA);

        address = 16'h0030;
        write_data = 8'h55;
        write_enable = 1'b0;

        @(posedge clk);
        #1;

        read_enable = 1'b1;
        #1;
        check(read_data == 8'hAA,
              "Disabled write preserves stored data");

        $display(
            "Data Memory: %0d/%0d tests passed.",
            passed_count,
            test_count
        );

        $finish;
    end

endmodule

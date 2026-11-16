module tb_register_file;

    import cpu_pkg::*;

    logic clk;
    logic reset;

    logic write_enable;
    logic [REGISTER_WIDTH-1:0] write_address;
    logic [DATA_WIDTH-1:0] write_data;

    logic [REGISTER_WIDTH-1:0] read_address_a;
    logic [REGISTER_WIDTH-1:0] read_address_b;
    logic [DATA_WIDTH-1:0] read_data_a;
    logic [DATA_WIDTH-1:0] read_data_b;

    integer test_count;
    integer i;

    register_file dut (
        .clk(clk),
        .reset(reset),
        .write_enable(write_enable),
        .write_address(write_address),
        .write_data(write_data),
        .read_address_a(read_address_a),
        .read_address_b(read_address_b),
        .read_data_a(read_data_a),
        .read_data_b(read_data_b)
    );

    always #5 clk = ~clk;

    task automatic write_register(
        input logic [REGISTER_WIDTH-1:0] address,
        input logic [DATA_WIDTH-1:0] value
    );
        begin
            @(negedge clk);
            write_enable = 1'b1;
            write_address = address;
            write_data = value;

            @(posedge clk);
            #1;
            write_enable = 1'b0;
        end
    endtask

    task automatic check_read_a(
        input logic [REGISTER_WIDTH-1:0] address,
        input logic [DATA_WIDTH-1:0] expected
    );
        begin
            read_address_a = address;
            #1;
            test_count = test_count + 1;

            if (read_data_a !== expected) begin
                $display(
                    "FAIL: R%0d expected %h, received %h",
                    address,
                    expected,
                    read_data_a
                );
                $fatal(1);
            end

            $display("PASS: Read port A, R%0d = %h", address, read_data_a);
        end
    endtask

    task automatic check_read_b(
        input logic [REGISTER_WIDTH-1:0] address,
        input logic [DATA_WIDTH-1:0] expected
    );
        begin
            read_address_b = address;
            #1;
            test_count = test_count + 1;

            if (read_data_b !== expected) begin
                $display(
                    "FAIL: R%0d expected %h, received %h",
                    address,
                    expected,
                    read_data_b
                );
                $fatal(1);
            end

            $display("PASS: Read port B, R%0d = %h", address, read_data_b);
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b0;
        write_enable = 1'b0;
        write_address = '0;
        write_data = '0;
        read_address_a = '0;
        read_address_b = '0;
        test_count = 0;

        $display("Starting Register File tests...");

        reset = 1'b1;
        #1;

        for (i = 0; i < REGISTER_COUNT; i = i + 1) begin
            check_read_a(i[REGISTER_WIDTH-1:0], '0);
        end

        reset = 1'b0;
        @(negedge clk);

        $display("Testing writes to all registers...");

        for (i = 0; i < REGISTER_COUNT; i = i + 1) begin
            write_register(
                i[REGISTER_WIDTH-1:0],
                (8'h10 + i)
            );
        end

        for (i = 0; i < REGISTER_COUNT; i = i + 1) begin
            check_read_a(
                i[REGISTER_WIDTH-1:0],
                (8'h10 + i)
            );
        end

        $display("Testing independent read ports...");

        read_address_a = 3'd1;
        read_address_b = 3'd6;
        #1;
        test_count = test_count + 1;

        if (read_data_a !== 8'h11 || read_data_b !== 8'h16) begin
            $display(
                "FAIL: Independent read ports returned A=%h B=%h",
                read_data_a,
                read_data_b
            );
            $fatal(1);
        end

        $display("PASS: Both read ports operate independently");

        $display("Testing write disabled...");

        @(negedge clk);
        write_enable = 1'b0;
        write_address = 3'd1;
        write_data = 8'hFF;

        @(posedge clk);
        #1;
        check_read_a(3'd1, 8'h11);

        $display("Testing write occurs only on clock edge...");

        @(negedge clk);
        write_enable = 1'b1;
        write_address = 3'd2;
        write_data = 8'hA5;

        #1;
        check_read_a(3'd2, 8'h12);

        @(posedge clk);
        #1;
        write_enable = 1'b0;
        check_read_a(3'd2, 8'hA5);

        $display("Testing asynchronous reset...");

        reset = 1'b1;
        #1;

        for (i = 0; i < REGISTER_COUNT; i = i + 1) begin
            check_read_a(i[REGISTER_WIDTH-1:0], '0);
        end

        reset = 1'b0;

        $display("--------------------------------");
        $display("All %0d Register File checks passed!", test_count);
        $display("--------------------------------");

        $finish;
    end

endmodule
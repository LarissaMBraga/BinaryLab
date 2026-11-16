`timescale 1ns/1ps

module tb_program_counter;

    logic clk;
    logic reset;
    logic enable;
    logic load_enable;
    logic [15:0] load_address;
    logic [15:0] pc;

    program_counter dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .load_enable(load_enable),
        .load_address(load_address),
        .pc(pc)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        enable = 1'b0;
        load_enable = 1'b0;
        load_address = 16'd0;

        #1;
        if (pc !== 16'd0)
            $fatal(1, "PC reset failed");

        reset = 1'b0;
        enable = 1'b1;

        @(posedge clk);
        #1;
        if (pc !== 16'd2)
            $fatal(1, "PC increment failed");

        @(negedge clk);
        load_enable = 1'b1;
        load_address = 16'h1234;

        @(posedge clk);
        #1;
        if (pc !== 16'h1234)
            $fatal(1, "PC load priority failed");

        @(negedge clk);
        load_enable = 1'b0;

        @(posedge clk);
        #1;
        if (pc !== 16'h1236)
            $fatal(1, "PC increment after load failed");

        reset = 1'b1;
        #1;

        if (pc !== 16'd0)
            $fatal(1, "PC asynchronous reset failed");

        $display("PROGRAM COUNTER UNIT TEST PASSED");
        $finish;
    end

endmodule

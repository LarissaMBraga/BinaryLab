module program_counter (
    input  logic clk,
    input  logic reset,
    input  logic enable,
    input  logic load_enable,
    input  logic [cpu_pkg::ADDRESS_WIDTH-1:0] load_address,
    output logic [cpu_pkg::ADDRESS_WIDTH-1:0] pc
);

    import cpu_pkg::*;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= '0;
        end else if (load_enable) begin
            pc <= load_address;
        end else if (enable) begin
            pc <= pc + 16'd2;
        end
    end

endmodule
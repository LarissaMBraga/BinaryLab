module gpio (
    input  logic       clk,
    input  logic       reset,
    input  logic       write_enable,
    input  logic [7:0] address,
    input  logic [7:0] write_data,
    input  logic [7:0] input_data,
    output logic [7:0] read_data,
    output logic [7:0] output_data,
    output logic [7:0] direction
);

    localparam logic [7:0] GPIO_DATA_ADDRESS = 8'hF0;
    localparam logic [7:0] GPIO_DIRECTION_ADDRESS = 8'hF1;

    logic [7:0] output_register;

    assign output_data = output_register;

    always_comb begin
        read_data = 8'h00;

        case (address)
            GPIO_DATA_ADDRESS: begin
                read_data =
                    (output_register & direction) |
                    (input_data & ~direction);
            end

            GPIO_DIRECTION_ADDRESS: begin
                read_data = direction;
            end

            default: begin
                read_data = 8'h00;
            end
        endcase
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            output_register <= 8'h00;
            direction <= 8'h00;
        end else if (write_enable) begin
            case (address)
                GPIO_DATA_ADDRESS: begin
                    output_register <= write_data;
                end

                GPIO_DIRECTION_ADDRESS: begin
                    direction <= write_data;
                end

                default: begin
                    output_register <= output_register;
                    direction <= direction;
                end
            endcase
        end
    end

endmodule
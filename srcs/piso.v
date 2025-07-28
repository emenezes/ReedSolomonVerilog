module PISO #(
    parameter N = 7
)(
    input              clk,
    input              rst,
    input  [N-1:0]     data_in,
    input              data_valid,
    output             serial_out,
    output             clk_out,
    output reg         done         // novo sinal: 1 por 1 ciclo ao final da transmissão
);

    reg [N-1:0] shift_reg = 0;
    reg [N-1:0] shift_reg_temp = 0;
    reg data_valid_temp = 0;

    reg [$clog2(N):0] bit_cnt = 0;
    reg busy = 0;

    always @(negedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 0;
            shift_reg_temp <= 0;
            data_valid_temp <= 0;
            bit_cnt <= 0;
            busy <= 0;
            done <= 0;
        end else begin
            done <= 0;  // default: zero

            if (!clk) begin
                if (data_valid_temp) begin
                    data_valid_temp <= 0;
                    shift_reg <= shift_reg_temp;
                    busy <= 1;
                    bit_cnt <= 0;
                end else if (data_valid) begin
                    shift_reg <= data_in;
                    shift_reg_temp <= data_in;
                    busy <= 1;
                    bit_cnt <= 0;
                end else if (busy) begin
                    if (bit_cnt == N-1) begin
                        busy <= 0;
                        bit_cnt <= 0;
                        done <= 1;  // <-- pulso de término
                    end else begin
                        bit_cnt <= bit_cnt + 1;
                        shift_reg <= {shift_reg[N-2:0], 1'b0};
                    end
                end
            end else begin
                if (data_valid) begin
                    data_valid_temp <= 1;
                    shift_reg_temp <= data_in;
                end
            end
        end
    end

    assign serial_out = shift_reg[N-1];
    assign clk_out = clk && busy;
endmodule

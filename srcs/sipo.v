module SIPO #(
    parameter N = 8
)(
    input  wire clk,
    input  wire rst,
    input  wire serial_in,
    input  wire enable,
    output reg  [N-1:0] data_out,
    output reg  data_valid
);

    reg [N-1:0] shift_reg;
    reg enable_d;

    // Detecta borda de subida de enable
    wire enable_posedge = enable && ~enable_d;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg   <= 0;
            data_out    <= 0;
            data_valid  <= 0;
            enable_d    <= 0;
        end else begin
            enable_d <= enable; // Armazena valor anterior de enable

            // Deslocamento contínuo
            shift_reg <= {shift_reg[N-2:0], serial_in};

            if (enable_posedge) begin
                data_out   <= {shift_reg[N-2:0], serial_in}; // Inclui o bit atual
                data_valid <= 1;
                shift_reg  <= 0; // Zera imediatamente após envio
            end else begin
                data_valid <= 0;
            end
        end
    end
endmodule



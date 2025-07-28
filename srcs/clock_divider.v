module clock_divider #(
    parameter DIVISOR = 100_000  // Fator de divisão do clock
)(
    input wire clk_in,       // Clock de entrada
    input wire reset,      // Reset ativo em nível baixo
    output reg clk_out       // Clock de saída
);

    reg [31:0] counter = 0; // Contador para dividir o clock

    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            counter <= counter + 1;
            if (counter == DIVISOR - 1) begin
                counter <= 0;
            end
        end
    end

    always @(posedge clk_in) begin
        clk_out <= (counter < (DIVISOR / 2)) ? 1'b1 : 1'b0;
    end
endmodule

module clock_divider_non_synth #(
    parameter INPUT_FREQ = 100_000_000, // Frequência do clock de entrada (em Hz)
    parameter OUTPUT_FREQ = 1_000       // Frequência do clock de saída desejada (em Hz)
)(
    input wire clk_in,       // Clock de entrada
    input wire reset,      // Reset ativo em nível baixo
    output reg clk_out       // Clock de saída
);

    // Calcula o fator de divisão
    localparam DIV_FACTOR = INPUT_FREQ / OUTPUT_FREQ;

    reg [$clog2(DIV_FACTOR)-1:0] counter; // Contador para dividir o clock

    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            if (counter == (DIV_FACTOR / 2) - 1) begin
                clk_out <= ~clk_out; // Alterna o clock de saída
                counter <= 0;        // Reseta o contador
            end else begin
                counter <= counter + 1; // Incrementa o contador
            end
        end
    end
endmodule
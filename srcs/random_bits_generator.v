module random_bits_generator_with_clock_divider #(
    parameter USE_PATTERN = 0, // Padrão de bits a ser usado (opcional)
    parameter DIVISOR_FREQ = 100_000
)(
    input wire clk_in,       // Clock de entrada
    input wire rst,      // Reset ativo em nível alto
    output wire random_bit,   // Bit aleatório gerado
    output wire clk_out      // Clock gerado pelo divisor de clock
);

    // Sinal do clock dividido
    wire clk_div;

    // Instância do divisor de clock
    clock_divider #(.DIVISOR(DIVISOR_FREQ)) clk_div_inst (
        .clk_in(clk_in),
        .reset(rst),
        .clk_out(clk_out)
    );

    random_bits_generator #(.SEED(USE_PATTERN)) random_gen (
        .clk_in(!clk_out),
        .reset(rst),
        .random_bit(random_bit)
    );

endmodule

module random_bits_generator #(
    parameter SEED = 0 // Padrão de bits a ser usado (opcional)
)(
    input wire clk_in,       // Clock de entrada
    input wire reset,      // Reset ativo em nível alto
    output reg random_bit   // Bit aleatório gerado
);
    initial begin
        random_bit = 0; // Inicializa o bit aleatório
    end

    // Registrador LFSR para gerar bits aleatórios
    reg [127:0] lfsr; // Registrador de 128 bits para o LFSR
    reg [6:0] count = 0;  
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            lfsr <= SEED;
            random_bit <= 0;
        end else
            lfsr <= lfsr ^ (lfsr >> 1) ^ (lfsr >> 2) ^ (lfsr >> 7);

        random_bit <= lfsr[0]; // O bit aleatório é o LSB do LFSR
    end

endmodule

module clock_divider #(
    parameter DIVISOR = 100_000  // Fator de divisão do clock
)(
    input wire clk_in,       // Clock de entrada
    input wire reset,      // Reset ativo em nível alto
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
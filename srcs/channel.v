// Modulo para injetar erros em uma transmissao serial de dados
module bit_error (
    input wire [2:0] num_errors,  // Numero maximo de erros permitidos (entre 0 e 7)
    input wire data_in,           // Bit de dado de entrada (serial)
    input wire clk_in,               // Sinal de clock usado para sincronizar as operacoes
    output reg data_out,           // Bit de dado de saida (com ou sem erro injetado)
    output wire clk_out
);

    // Registrador de deslocamento do tipo LFSR (registrador de deslocamento com realimentacao linear)
    // Utilizado para gerar numeros pseudoaleatorios
	// O semente pode ser alterada para criar uma nova sequencia
    reg [2:0] lfsr = 3'b111; // Valor inicial fixo diferente de "0"

    // Calculo do bit de realimentacao do LFSR
    // Usa a operacao XOR entre tres bits internos para gerar o proximo bit
    wire lfsr_feedback = lfsr[2] ^ lfsr[1];
	
    //LFSR desloca os bits e insere o bit de realimentacao na extremidade
    always @(posedge clk_in) begin
	    lfsr <= {lfsr[1:0], lfsr_feedback}; // Desloca os bits e insere o feedback
    end	

    // Extraimos os 3 bits menos significativos do LFSR para formar um valor aleatorio entre 1 e 7
    wire [2:0] rnd_value = lfsr[2:0];

    // Comparamos o valor aleatorio com o numero maximo de erros permitidos
    // Se o valor for menor ou igual que num_errors, entao um erro sera injetado
    wire inject_error = (rnd_value <= num_errors);

    // Bloco que realiza a decisao final da saida
	// Se for para injetar erro, o bit de entrada e invertido
    // Caso contrario, o bit de entrada e passado diretamente
    always @(posedge clk_in) begin
        data_out <= inject_error ? ~data_in : data_in;
    end

    assign clk_out = clk_in;
endmodule

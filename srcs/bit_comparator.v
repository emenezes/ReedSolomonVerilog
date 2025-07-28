module bit_comparator (
    input wire clk,                  //Clock do sistema
    input wire rst,            //Reset do modulo
    input wire bit_in_generator,     //Bit gerado pelo gerador de números aleatórios
    input wire clk_in_generator,     //Clock de amostragem de dados da geração de números aleatórios
    input wire bit_in_decoder,       //Bit de saída da decodificação
    input wire clk_in_decoder,       //Clock de amostragem de dados da decodificação
    output [6:0] error     //Valor do erro do decodificador para o bit gerado em porcentagem
  );

  localparam PORCENTAGE = 100;                //Parâmetro local de auxílio nas operações internas

  reg [100:0] vet_error;                      //Registrador de armazenamento do resultado de erro das últimas 100 comparações realizadas
  reg bit_error_out;                          //Registrador de armazenamento do bit de saída do vetor de erros
  reg [6:0] count_error;                      //Registrador de contagem de erros nos últimos 100 bits comparados
  reg [6:0] count_bit;                        //Registrador de contagem de bits comparados
  reg [6:0] percentage_error;                 //Registrador de armazenamento da porcentagem de erros
  reg [13:0] mult_div;                        //Registrador para operações internas ao cálculo de porcentagem de erros

  //Geração de clocks internos para amostragem de dados
  reg last_clk_generator, new_clk_generator;
  reg last_clk_decoder, new_clk_decoder;
  reg rising_edge_generator;
  reg rising_edge_decoder;

  //Construção de fifo por buffer circular
  reg [127:0] bit_in_generator_fifo;          //Fifo para armazenar bits do gerador de bits aleatórios
  reg [6:0] w_ptr;                            //Ponteiro de escrita da FIFO
  reg [6:0] r_ptr;                            //Ponteiro de leitura da FIFO
  reg bit_in_generator_fifo_out;              //Bit de saída da FIFO para comparação
  reg [6:0] elements_fifo;                    //Contador de elementos da FIFO
  reg fifo_is_full;                           //Indica que a FIFO está cheia
  reg last_fifo_is_full;                      //Indica que o estado anterior de preenchimento da FIFO
  reg [6:0] count_dequeue;                    //Contador para retirar da fila as últimas amostras para comparação 
  
  //O bloco gera sinais de eventos dos clocks de saída da geração de números aleatórios e decodificação, em função do clock principal do sistema
  //de forma que possam ser amostrados os bits de cada um desses módulos
  always @(posedge clk or posedge rst)
  begin
    if(rst)
    begin
      vet_error = 0;
      bit_error_out = 0;
      count_error = 0;
      count_bit = 0;
      percentage_error = 0;
      mult_div = 0;

      rising_edge_generator = 0;
      rising_edge_decoder = 0;
      last_clk_generator = 0;
      new_clk_generator = 0;
      last_clk_decoder = 0;
      new_clk_decoder = 0;

      bit_in_generator_fifo_out = 0;
      bit_in_generator_fifo = 0;
      fifo_is_full = 0;
      elements_fifo = 0;
      w_ptr = 0;
      r_ptr = 0;
      last_fifo_is_full = 0;
      count_dequeue = 0;

    end

    else
    begin

      last_clk_generator = new_clk_generator;
      new_clk_generator = clk_in_generator;
      last_clk_decoder = new_clk_decoder;
      new_clk_decoder = clk_in_decoder;

      rising_edge_generator = ~last_clk_generator && new_clk_generator;
      rising_edge_decoder = ~last_clk_decoder && new_clk_decoder;

    end
  end

  //Bloco de operações de entrada e saída de dados do buffer
  //Operações de escrita são mais recorrentes que as de leitura, por isso é importante perceber o momento em que o buffer pode ficar
  //cheio em função da diferença de frequência dos clocks de dados da entrada

  always @(posedge rising_edge_generator or posedge rising_edge_decoder)
  begin

    last_fifo_is_full = fifo_is_full;
    
    //Considera a escrita de dados do gerador na FIFO
    //Verifica se a quantidade de elementos do buffer corresponde ao teto máximo, então gera uma flag indicativa de que a FIFO está cheia
    //Caso contrário incrementa a posição do ponteiro de escrita
    if(rising_edge_generator)
    begin
      if(elements_fifo == 127)
        fifo_is_full = 1;
      else
      begin
        bit_in_generator_fifo[w_ptr] = bit_in_generator;
        w_ptr = w_ptr + 1;
        fifo_is_full = 0;
        elements_fifo = elements_fifo + 1;
      end
    end

    //Quando dados do decodificador estão disponíveis, os dados da fila são lidos
    //Caso a fila esteja cheia, é iniciada uma contagem de leitura dos últimos dados da FIFO para comparação
    if ((rising_edge_decoder) && (count_dequeue < 127))
    begin

      if(fifo_is_full)
      begin
        count_dequeue = count_dequeue + 1;
      end

      //Incremento do ponteiro de leitura
      bit_in_generator_fifo_out = bit_in_generator_fifo[r_ptr];
      r_ptr = r_ptr + 1;

      //Quando a FIFO está completa a contagem de seus elementos não é mais decrementada
      if(~fifo_is_full)
      begin
        elements_fifo = elements_fifo - 1;
      end

      //Após sincronizados os dados do gerador e do decodificador inicia-se a comparação
      //Vetor de erros é deslocado à esquerda e resultado da comparação entra na posição 0 do vetor: 1 se houver erro e 0 se bits correspoderem
      //Contagem de erros é atualizada a depender do valor do bit de saída do deslocamento do vetor de erros
      //Se a contagem de bits comparados for menor que 100 o erro corresponde ao percentual da contagem de erros/ contagem de bits comparados
      //Acima de 100 bits comparados o percentual de erros corresponde ao número de erros contados

      {bit_error_out, vet_error} = vet_error << 1;

      if((bit_in_generator_fifo_out) ^~ (bit_in_decoder) == 1'b1)
      begin
        vet_error[0] = 1'b0;

        if(bit_error_out)
        begin
          count_error = count_error - 1;
        end
      end

      else
      begin
        vet_error[0] = 1'b1;

        if(!bit_error_out)
        begin
          count_error = count_error + 1;
        end

      end

      if(count_bit < 100)
      begin
        count_bit = count_bit + 1;
        mult_div = (PORCENTAGE * count_error)/count_bit;
        percentage_error = mult_div;
      end

      else
      begin
        mult_div = 0;
        percentage_error = count_error;
      end
    end
  end
  
  //A saída "error" do bloco recebe a atribuição do resultado da porcentagem de erros calculada
  assign error = percentage_error;

endmodule
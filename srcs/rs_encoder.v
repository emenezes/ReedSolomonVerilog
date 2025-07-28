module rs_enc_ser#(
    parameter N = 7,
    parameter K = 3
)(
    input wire         clk,
    input wire         reset,
    input wire         data_in,
    input wire         clk_data_in,
    output wire[N-1:0] data_out,
    output wire        clk_data_out
);

reg [K-1:0] msg_in;
reg [K-1:0] msg_in_temp;
reg   [1:0] msg_in_count;

reg [1:0] clk_data_in_buf;
wire      clk_data_in_posedge;
assign clk_data_in_posedge = clk_data_in_buf[0] & ~clk_data_in_buf[1];

reg rs_enc_clk;
assign clk_data_out = rs_enc_clk;

rs_enc#(N, K) rs_enc(rs_enc_clk, reset, msg_in, data_out);

always @(posedge clk, posedge reset) begin
    if (reset) begin
        msg_in <= 0;
        msg_in_temp <= 0;
        msg_in_count <= 0;
        clk_data_in_buf[0] <= clk_data_in;
        clk_data_in_buf[1] <= clk_data_in_buf[0];
        rs_enc_clk <= 0;
    end else begin
        clk_data_in_buf[0] <= clk_data_in;
        clk_data_in_buf[1] <= clk_data_in_buf[0];

        if (clk_data_in_posedge) begin
            case (msg_in_count)
            2'b00: begin
                msg_in_count <= msg_in_count + 1;
                msg_in_temp[0] <= data_in;
            end
            2'b01: begin
                msg_in_count <= msg_in_count + 1;
                msg_in_temp[1] <= data_in;
            end
            2'b10: begin 
                msg_in_count <= 0;
                msg_in_temp[2] <= data_in;
                msg_in <= {data_in, msg_in_temp[1:0]};
                rs_enc_clk <= 1'b1;
            end
            endcase
        end

        if (msg_in_count == 2'b00) begin
            rs_enc_clk <= 1'b0;
        end
    end
end
endmodule

// ----------------------------------------------------------------------------

module rs_enc#(
    parameter N = 7,
    parameter K = 3
)(
    input wire         clk,
    input wire         reset,
    input wire [K-1:0] data_in,
    output reg [N-1:0] data_out
);

// store the input message with N bits (instead of K) so that it is actually
// aligned to the left.
wire [N-1:0] msg_enc_in;

// assign the top K bits to the input data
genvar i;
generate
for (i = 0; i < K; i = i + 1)
    assign msg_enc_in[N-K+i] = data_in[i];
endgenerate

// assign the lower N-K bits to 0
genvar j;
generate
for (j = 0; j < N-K; j = j + 1)
    assign msg_enc_in[j] = 1'b0;
endgenerate

// Our generator polynomial
wire [N-1:0] gen_poly;
assign gen_poly = 7'b0010011;

// The output of the polynomial division
wire [N-K-1:0] msg_enc_out;

// We need to keep the input message for K clock cycles because our code is
// systematic.
reg [K-1:0] msg_in_buf [K-1:0];

poly_div_pip poly_div(clk, reset, msg_enc_in, gen_poly, msg_enc_out);

always @(posedge clk, posedge reset) begin :da_block
    integer i;

    if (reset) begin
        data_out <= 0;
        for (i = 0; i < K; i = i + 1)
            msg_in_buf[i] <= 0;
    end

    else begin
        msg_in_buf[0] <= msg_enc_in[N-1:N-K];

        for (i = 0; i < K - 1; i = i + 1)
            msg_in_buf[i + 1] <= msg_in_buf[i];

        // The lower K bits come from the input message, the the top N-K bits
        // come from the encoded output.
        data_out <= { msg_enc_out, msg_in_buf[K-1] };
    end
end
endmodule

// ----------------------------------------------------------------------------

module poly_div(
    input wire       clk,
    input wire       reset,
    input wire [6:0] dividend,
    input wire [6:0] divisor,
    output reg       done,
    output reg [3:0] remainder
);

reg [1:0] count;
reg [6:0] dividend_buf;
reg [6:0] divisor_buf;

always @(posedge clk, posedge reset) begin
    if (reset) begin
        count        <= 0;
        dividend_buf <= 0;
        divisor_buf  <= 0;
        done         <= 0;
        remainder    <= 0;
    end

    else begin
        if (count == 0) begin
            // increment count and reset done signal
            count <= count + 1;
            done <= 0;

            // save copy of divisor and calculate first step, saving result
            // in the internal bufffer
            divisor_buf <= divisor;
            if (dividend[6])
                dividend_buf <= dividend ^ (divisor << 2);
            else
                dividend_buf <= dividend;
        end

        else if (count == 1) begin
            count <= count + 1;
            if (dividend_buf[5])
                dividend_buf <= dividend_buf ^ (divisor_buf << 1);
        end

        else if (count == 2) begin
            // sinal completion and reset count, as we don't have a step with
            // index 3. This means that the next calculation would begin
            // immediatly. An opportunity for pipeling can be seen.
            done  <= 1;
            count <= 0;

            if (dividend_buf[4])
                remainder <= dividend_buf ^ divisor_buf;
            else
                remainder <= dividend_buf;
        end
    end
end

endmodule

// ----------------------------------------------------------------------------

module poly_div_pip(
    input wire       clk,
    input wire       reset,
    input wire [6:0] dividend,
    input wire [6:0] divisor,
    output reg [3:0] remainder
);

reg [6:0] dividend_buf [1:0];
reg [6:0] divisor_buf  [1:0];

always @(posedge clk, posedge reset) begin
    if (reset) begin
        dividend_buf[0] <= 0;
        dividend_buf[1] <= 0;
        divisor_buf[0]  <= 0;
        divisor_buf[1]  <= 0;
        remainder    <= 0;
    end

    else begin
        // step 1
        divisor_buf[0] <= divisor;
        if (dividend[6])
            dividend_buf[0] <= dividend ^ (divisor << 2);
        else
            dividend_buf[0] <= dividend;

        // step 2
        divisor_buf[1] <= divisor_buf[0];
        if (dividend_buf[0][5])
            dividend_buf[1] <= dividend_buf[0] ^ (divisor_buf[0] << 1);
        else
            dividend_buf[1] <= dividend_buf[0];

        // step 3
        if (dividend_buf[1][4])
            remainder <= dividend_buf[1] ^ divisor_buf[1];
        else
            remainder <= dividend_buf[1];
    end
end
endmodule

// ----------------------------------------------------------------------------

module par_to_ser#(
    parameter N = 7
)(
    input wire         clk,
    input wire         reset,
    input wire         clk_data_in,
    input wire [N-1:0] data_in,
    output reg         clk_data_out,
    output reg         data_out
);

reg [1:0] clk_data_in_buf;
wire      clk_data_in_posedge;
assign clk_data_in_posedge = clk_data_in_buf[0] & ~clk_data_in_buf[1];

reg [N-1:0] data_out_buffer;
reg [$clog2(N):0] data_out_cnt;
//reg [$clog2(N-1)-1:0] data_out_cnt;

always @(posedge clk, posedge reset) begin
    if (reset) begin
        clk_data_in_buf <= 0;
        data_out_buffer <= 0;
        data_out_cnt    <= 0;

        clk_data_out <= 0;
        data_out     <= 0;
    end

    else begin
        clk_data_in_buf[0] <= clk_data_in;
        clk_data_in_buf[1] <= clk_data_in_buf[0];

        // we have data in the input. In case we still have pending bits in
        // data_out_buffer, these are lost.
        if (clk_data_in_posedge) begin
            // cut out the bottom bit, it goes directly to the output
            data_out_buffer <= data_in[N-1:1];
            data_out        <= data_in[0];
            data_out_cnt    <= N-1;
            clk_data_out    <= 1'b1;
        end

        // if the clock is high, we need to lower it first
        if (clk_data_out) begin
            clk_data_out <= 1'b0;
        end

        // has pending data
        else if (data_out_cnt > 0) begin
            // ready to output another bit. Shift the output buffer and send
            // output clock up.
            data_out_cnt    <= data_out_cnt - 1;
            data_out_buffer <= data_out_buffer[N-1:1];
            data_out        <= data_out_buffer[0];
            clk_data_out    <= 1'b1;
        end
    end
end
endmodule

module rs_enc_validator#(
    parameter DELAY = 3
)(
    input wire  clk,
    input wire  reset,
    output wire clk_data_out
);

reg [$clog2(DELAY)-1:0] counter;

assign clk_data_out = counter == DELAY ? clk : 1'b0;

always @(posedge clk, posedge reset) begin
    if (reset) begin
        counter <= 0;
    end

    else begin
        if (counter < DELAY)
            counter <= counter + 1;
    end
end
endmodule

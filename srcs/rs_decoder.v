module syndrome_comb (
    input  [6:0] dividend,
    output [3:0] remainder
);
    wire [6:0] stage1 = dividend[6] ? dividend ^ (7'b1001100) : dividend;
    wire [6:0] stage2 = stage1[5] ? stage1 ^ (7'b0100110) : stage1;
    wire [6:0] stage3 = stage2[4] ? stage2 ^ (7'b0010011) : stage2;
    assign remainder = stage3[3:0];
endmodule

module error_locator (
    input      [3:0] syndrome,
    output reg [6:0] error_mask,
    output reg       error_detected
);

    always @(*) begin
        case (syndrome)
            4'b0000: begin
                error_mask     = 7'b0000000;
                error_detected = 0;
            end
            4'b0001: begin error_mask = 7'b0000001; error_detected = 1; end // erro em bit 0
            4'b0010: begin error_mask = 7'b0000010; error_detected = 1; end // bit 1
            4'b0100: begin error_mask = 7'b0000100; error_detected = 1; end // bit 2
            4'b1000: begin error_mask = 7'b0001000; error_detected = 1; end // bit 3
            4'b0011: begin error_mask = 7'b0010000; error_detected = 1; end // bit 4
            4'b0110: begin error_mask = 7'b0100000; error_detected = 1; end // bit 5
            4'b1100: begin error_mask = 7'b1000000; error_detected = 1; end // bit 6

            // Síndromes de erro duplo ou inválidas
            default: begin
                error_mask     = 7'b0000000; // não tenta corrigir
                error_detected = 1;          // mas sinaliza erro detectado
            end
        endcase
    end
endmodule


module serial_to_parallel #(
    parameter K = 8
)(
    input              clk,
    input              rst,
    input              serial_in,
    output reg [K-1:0] data_out,
    output reg         data_valid
    );
    reg [K-1:0] data_temp;

    reg [$clog2(K):0] bit_cnt = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_temp   <= 0;
            bit_cnt    <= 0;
        end else begin
            data_temp <= {data_temp[K-2:0], serial_in};
            if (bit_cnt == K-1) begin
                bit_cnt    <= 0;
            end else begin
                bit_cnt    <= bit_cnt + 1;
            end
        end
    end

    always @(negedge clk or posedge rst) begin
        if (rst) begin
            data_valid <= 0;
            data_out <= 0;
        end else if (bit_cnt == 0) begin
            data_valid <= 1;
            data_out <= data_temp;
        end else begin
            data_valid <= 0;
        end
    end
endmodule


module parallel_to_serial #(
    parameter N = 8
)(
    input              clk,
    input              rst,
    input  [N-1:0]     data_in,
    input              data_valid,
    output             clk_out,
    output             serial_out
);

    reg [N-1:0] shift_reg = 0;
    reg [N-1:0] shift_reg_temp = 0;
    reg data_valid_temp = 0;
    reg data_valid_down = 0;

    reg [$clog2(N):0] bit_cnt = 0;
    reg busy = 0;

    always @(negedge clk or negedge data_valid) begin
        if(data_valid) begin
            data_valid_down <= 0;
        end else begin
            data_valid_down <= 1;
        end
    end


    always @(negedge clk or posedge data_valid) begin
        if(!clk) begin
            if(data_valid_temp) begin
                data_valid_temp <= 0;
                shift_reg <= shift_reg_temp;
                busy <= 1;
                bit_cnt <= 0;
            end else if (data_valid && data_valid_down && !busy) begin
                shift_reg <= data_in;
                shift_reg_temp <= data_in;
                busy <= 1;
                bit_cnt <= 0;
            end else if (busy) begin
                if (bit_cnt == N-1) begin
                    busy <= 0;
                    bit_cnt <= 0;
                end else begin
                    bit_cnt <= bit_cnt + 1;
                    shift_reg <= {1'b0, shift_reg[N-1:1]};
                end
            end
        end else begin
            if(data_valid) begin
                data_valid_temp <= 1;
                shift_reg_temp <= data_in;
            end
        end
    end

    assign serial_out = shift_reg[0];
    assign clk_out = clk && busy;
endmodule

module clock_divider_dec #(
    parameter D = 2
)(
    input  clk_in,
    input  rst,
    output reg clk_out
);

    reg [$clog2(D)-1:0] cnt = 0;

    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            cnt     <= 0;
            clk_out <= 0;
        end else begin
            if (cnt == D-1) begin
                cnt     <= 0;
                clk_out <= ~clk_out;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end

endmodule

module rs_decoder #(
    parameter N = 7,
    parameter K = 3
)(
    input              clk_sys,
    input              rst,
    input              serial_in,
    input              clk_in,
    output             serial_out,
    output             clk_out,
    output             error
);
wire [N-1:0] data_parallel_in;
wire         data_valid_in;
wire clk_p2s;
reg [N-1:0] data_parallel;
wire [N-1:0] data_parallel_out;
wire [3:0] syndrome;

wire [K-1:0] decoded_data;
wire [N-1:0] error_mask;
wire         error_detected;

clock_divider_dec #(.D(N)) clkdiv_inst (
    .clk_in(clk_sys),
    .rst(rst),
    .clk_out(clk_p2s)
);

serial_to_parallel #(.K(N)) s2p_inst (
    .clk(!clk_in),
    .rst(rst),
    .serial_in(serial_in),
    .data_out(data_parallel_in),
    .data_valid(data_valid_in)
);

syndrome_comb syndrome_inst(
    .dividend({data_parallel[0], data_parallel[1], data_parallel[2], data_parallel[3], data_parallel[4], data_parallel[5], data_parallel[6]}),
    .remainder(syndrome)
);


error_locator error_locator_inst (
    .syndrome(syndrome),
    .error_mask(error_mask),
    .error_detected(error_detected)
);

parallel_to_serial #(.N(K)) p2s_inst (
    .clk(!clk_p2s),
    .rst(rst),
    .data_in(data_parallel_out[K-1:0]),
    .data_valid(data_valid_in),
    .clk_out(clk_out),
    .serial_out(serial_out)
);

always @(posedge data_valid_in or posedge rst) begin
    if (rst) begin
        data_parallel <= 0;
    end else if (data_valid_in) begin
        data_parallel <= data_parallel_in;
    end
end

assign error = !error_detected;
assign data_parallel_out = data_parallel ^ error_mask;

endmodule


module rs_decoder_tb;

    parameter N = 7;
    parameter K = 3;

    reg rst;
    reg clk_sys;
    wire clk_in;
    reg serial_in;
    wire clk_out;
    wire serial_out;
    wire valid_out;
    reg clk_bit;

    // Clock generation
    initial begin
        clk_sys = 0;
        forever #1 clk_sys = ~clk_sys; // 100MHz clock (10ns period)
    end

    clock_divider #(.D(K)) clkdiv_tb (
        .clk_in(clk_sys),
        .rst(rst),
        .clk_out(clk_in)
    );

    // Instantiate the decoder
    rs_decoder #(.N(N), .K(K)) dut (
        .rst(rst),
        .clk_sys(clk_sys),
        .clk_in(clk_bit),
        .serial_in(serial_in),
        .clk_out(clk_out),
        .serial_out(serial_out),
        .valid_out(valid_out)
    );

    // Test stimulus
    reg [N-1:0] test_vector = 7'b0010011;
    reg [N-1:0] test_vector1 = 7'b0010010;
    integer i;
    

    task send_serial;
        input [N-1:0] data;
        integer j;
        begin
            for (j = N-1; j >= 0; j = j - 1) begin
                @(negedge clk_in);
                clk_bit = 0;
                serial_in = data[j];
                @(posedge clk_in);
                clk_bit = 1;
            end

        end
    endtask


    initial begin
        rst = 1;
        serial_in = 0;
        #20;
        rst = 0;

        // Send first test vector
        send_serial(test_vector);
        // Send second test vector
        send_serial(test_vector1);

        send_serial(test_vector);

        send_serial(test_vector1);

        @(negedge clk_in);
        clk_bit = 0;
        @(posedge clk_in);
        clk_bit = 1;
        @(negedge clk_in);
        clk_bit = 0;

    end

endmodule


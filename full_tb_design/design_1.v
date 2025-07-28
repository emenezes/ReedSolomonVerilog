//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.1 (win64) Build 5076996 Wed May 22 18:37:14 MDT 2024
//Date        : Mon Jul 28 16:51:11 2025
//Host        : Z820 running 64-bit major release  (build 9200)
//Command     : generate_target design_1.bd
//Design      : design_1
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "design_1,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=design_1,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=8,numReposBlks=8,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=6,numPkgbdBlks=0,bdsource=USER,synth_mode=Hierarchical}" *) (* HW_HANDOFF = "design_1.hwdef" *) 
module design_1
   ();

  wire Net;
  wire PISO_0_clk_out;
  wire PISO_0_serial_out;
  wire bit_error_0_clk_out;
  wire bit_error_0_data_out;
  wire random_bits_generato_0_clk_out;
  wire random_bits_generato_0_random_bit;
  wire rs_decoder_0_clk_out;
  wire rs_decoder_0_serial_out;
  wire rs_enc_ser_0_clk_data_out;
  wire [6:0]rs_enc_ser_0_data_out;
  wire sim_clk_gen_0_sync_rst;
  wire [2:0]xlconstant_0_dout;

  design_1_PISO_0_0 PISO_0
       (.clk(Net),
        .clk_out(PISO_0_clk_out),
        .data_in(rs_enc_ser_0_data_out),
        .data_valid(rs_enc_ser_0_clk_data_out),
        .rst(sim_clk_gen_0_sync_rst),
        .serial_out(PISO_0_serial_out));
  design_1_bit_comparator_0_0 bit_comparator_0
       (.bit_in_decoder(rs_decoder_0_serial_out),
        .bit_in_generator(random_bits_generato_0_random_bit),
        .clk(Net),
        .clk_in_decoder(rs_decoder_0_clk_out),
        .clk_in_generator(random_bits_generato_0_clk_out),
        .rst(sim_clk_gen_0_sync_rst));
  design_1_bit_error_0_0 bit_error_0
       (.clk_in(PISO_0_clk_out),
        .clk_out(bit_error_0_clk_out),
        .data_in(PISO_0_serial_out),
        .data_out(bit_error_0_data_out),
        .num_errors(xlconstant_0_dout));
  design_1_random_bits_generato_0_2 random_bits_generato_0
       (.clk_in(Net),
        .clk_out(random_bits_generato_0_clk_out),
        .random_bit(random_bits_generato_0_random_bit),
        .rst(sim_clk_gen_0_sync_rst));
  design_1_rs_decoder_0_2 rs_decoder_0
       (.clk_in(bit_error_0_clk_out),
        .clk_out(rs_decoder_0_clk_out),
        .clk_sys(Net),
        .rst(sim_clk_gen_0_sync_rst),
        .serial_in(bit_error_0_data_out),
        .serial_out(rs_decoder_0_serial_out));
  design_1_rs_enc_ser_0_0 rs_enc_ser_0
       (.clk(Net),
        .clk_data_in(random_bits_generato_0_clk_out),
        .clk_data_out(rs_enc_ser_0_clk_data_out),
        .data_in(random_bits_generato_0_random_bit),
        .data_out(rs_enc_ser_0_data_out),
        .reset(sim_clk_gen_0_sync_rst));
  design_1_sim_clk_gen_0_0 sim_clk_gen_0
       (.clk(Net),
        .sync_rst(sim_clk_gen_0_sync_rst));
  design_1_xlconstant_0_0 xlconstant_0
       (.dout(xlconstant_0_dout));
endmodule

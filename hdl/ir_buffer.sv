`timescale 1ns / 1ps
`default_nettype none

module ir_buffer #(parameter MEMORY_DEPTH = 16'd6000)
                    (input wire audio_clk,
                    input wire rst_in,
                    input wire [15:0] ir_sample_index,
                    input wire signed [15:0] write_data,
                    input wire write_enable, 
                    input wire ir_data_in_valid,
                    input wire [12:0] first_ir_index,
                    input wire [12:0] second_ir_index,
                    output logic signed [15:0] ir_vals [7:0]
    );


    // Locations 23999 to 18000
    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(16),
        .RAM_DEPTH(MEMORY_DEPTH)
    ) ir_buffer_0 (
        .addra((ir_data_in_valid && (ir_sample_index < 6000)) ? (16'd5999 - ir_sample_index) : first_ir_index),
        .clka(audio_clk),
        .wea(write_enable && ir_data_in_valid && (ir_sample_index < 6000)),
        .dina(write_data),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(rst_in),
        .douta(ir_vals[0]),
        .addrb(second_ir_index),
        .dinb(),
        .clkb(audio_clk),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst_in),
        .regceb(1'b1),
        .doutb(ir_vals[1])
    );

    //17999 to 12000
    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(16),
        .RAM_DEPTH(MEMORY_DEPTH)
    ) ir_buffer_1 (
        .addra((ir_data_in_valid && (ir_sample_index < 16'd12000) && (ir_sample_index >= 16'd6000)) ? (16'd11999 - ir_sample_index) : first_ir_index),
        .clka(audio_clk),
        .wea(write_enable && ir_data_in_valid && (ir_sample_index < 16'd12000) && (ir_sample_index >= 16'd6000)),
        .dina(write_data),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(rst_in),
        .douta(ir_vals[2]),
        .addrb(second_ir_index),
        .dinb(),
        .clkb(audio_clk),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst_in),
        .regceb(1'b1),
        .doutb(ir_vals[3])
    );

    //11999 to 6000
    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(16),
        .RAM_DEPTH(MEMORY_DEPTH)
    ) ir_buffer_2 (
        .addra((ir_data_in_valid && (ir_sample_index < 16'd18000) && (ir_sample_index >= 16'd12000)) ? (16'd17999 - ir_sample_index) : first_ir_index),
        .clka(audio_clk),
        .wea(write_enable && ir_data_in_valid && (ir_sample_index < 16'd18000) && (ir_sample_index >= 16'd12000)),
        .dina(write_data),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(rst_in),
        .douta(ir_vals[4]),
        .addrb(second_ir_index),
        .dinb(),
        .clkb(audio_clk),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst_in),
        .regceb(1'b1),
        .doutb(ir_vals[5])
    );

    //5999 to 0
    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(16),
        .RAM_DEPTH(MEMORY_DEPTH)
    ) ir_buffer_3 (
        .addra((ir_data_in_valid && (ir_sample_index >= 16'd18000)) ? (16'd23999 - ir_sample_index) : first_ir_index),
        .clka(audio_clk),
        .wea(write_enable && ir_data_in_valid && (ir_sample_index >= 16'd18000)),
        .dina(write_data),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(rst_in),
        .douta(ir_vals[6]),
        .addrb(second_ir_index),
        .dinb(),
        .clkb(audio_clk),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst_in),
        .regceb(1'b1),
        .doutb(ir_vals[7])
    );
endmodule

`timescale 1ns / 1ps
`default_nettype wire
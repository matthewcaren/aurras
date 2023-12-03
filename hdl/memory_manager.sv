`timescale 1ns / 1ps
`default_nettype none

module memory_manager #(parameter impulse_length = 48000)
                    (input wire audio_clk,
                      input wire rst_in,
                      input wire [15:0] write_addr,
                      input wire signed [15:0] write_data,
                      input wire write_enable,
                      input wire [15:0] read_addr,
                      output logic signed [15:0] read_data                        
                      );


    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(16),
        .RAM_DEPTH(impulse_length)
    ) impulse_memory (
        .addra(write_addr),
        .clka(audio_clk),
        .wea(write_enable),
        .dina(write_data),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(rst_in),
        .douta(),
        .addrb(read_addr),
        .dinb(),
        .clkb(audio_clk),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst_in),
        .regceb(1'b1),
        .doutb(read_data)
    );

endmodule

`timescale 1ns / 1ps
`default_nettype wire
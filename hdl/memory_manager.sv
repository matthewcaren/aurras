`timescale 1ns / 1ps
`default_nettype none

module memory_manager(input wire audio_clk,
                      input wire rst_in,
                      input wire [15:0] write_addr,
                      input wire [15:0] write_data,
                      input wire [15:0] impulse_length,
                      
                      );


    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(16),
        .RAM_DEPTH(impulse_length)
    ) 
    impulse_memory (
        .addra(write_addr),
        .clka(clk_in),
        .wea(1'b1),
        .dina(write_data),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(rst_in),
        .douta(),
        .addrb(),
        .dinb(),
        .clkb(clk_in),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst_in),
        .regceb(1'b1),
        .doutb()
    );

endmodule

`timescale 1ns / 1ps
`default_nettype wire
`timescale 1ns / 1ps
`default_nettype none

module delayed_sound_out (
    input wire clk_in,
    input wire rst_in,
    input wire store_audio_in,
    input wire audio_valid_in,
    input wire [15:0] delay_cycle,  // This is the delay length
    input wire [15:0] audio_in,
    output wire [15:0] delayed_audio_out 
);

    parameter RAM_DEPTH = 16'd48000; 
    logic [15:0] write_data;
    logic [15:0] write_addr = 0;
    logic [15:0] read_addr = 0;
    logic write_enable = 0;

    // Writing Logic
    always @(posedge clk_in) begin
        if (rst_in) begin
            write_addr <= 0;
            write_enable <= 0;
        end else if (audio_valid_in && store_audio_in) begin
            write_data <= audio_in;
            write_enable <= 1;
            write_addr <= (write_addr + 1) % RAM_DEPTH;
        end else begin
            write_enable <= 0;
        end
    end

    // Reading Logic with Delay
    always @(posedge clk_in) begin
        if (audio_valid_in) begin
            read_addr <= (write_addr - delay_cycle) % RAM_DEPTH;
        end
    end


    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(16),
        .RAM_DEPTH(RAM_DEPTH)
    ) 
    audio_buffer (
        .addra(write_addr),
        .clka(clk_in),
        .wea(write_enable),
        .dina(write_data),
        .ena(store_audio_in),
        .regcea(1'b1),
        .rsta(rst_in),
        .douta(),
        .addrb(read_addr),
        .dinb(16'd0),
        .clkb(clk_in),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst_in),
        .regceb(1'b1),
        .doutb(delayed_audio_out)
    );

endmodule


`timescale 1ns / 1ps
`default_nettype wire

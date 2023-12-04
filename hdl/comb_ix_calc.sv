`timescale 1ns / 1ps
`default_nettype none

module comb_ix_calc(
        input wire [1023:0] live_read_data,
        input wire signed [15:0] audio_in,
        input wire [15:0] audio_buffer_index,
        output logic [1023:0] line_to_write
    );

    logic [5:0] word_index;
    assign word_index = audio_buffer_index[5:0];
    logic [62:1] [1023:0] words;
    genvar i;
    generate 
        for (i=1; i<63; i=i+1) begin
            always_comb begin
                words[i] = {live_read_data[1023 : ((word_index << 4) + 16)], audio_in, live_read_data[((word_index << 4) - 1) : 0]}; 
            end  
        end
    endgenerate
    
    always_comb begin
        if (word_index == 0) begin
            line_to_write = {live_read_data[1023:15], audio_in};
        end else if (word_index == 63) begin
            line_to_write = {audio_in, live_read_data[1007:0]};
        end else begin
            line_to_write = words[word_index];
        end
    end
endmodule

`timescale 1ns / 1ps
`default_nettype wire
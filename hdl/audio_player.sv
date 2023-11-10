`timescale 1ns / 1ps
`default_nettype none


module audio_player( 
    input wire clk_in,
    input wire rst_in,
    input wire signed [15:0] sound_source_in,
    output logic sound_out
  );

  pdm my_pdm(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .level_in(sound_source_in),
    .pdm_out(sound_out)
  );


  
endmodule
`default_nettype wire
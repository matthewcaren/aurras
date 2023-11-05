`timescale 1ns / 1ps
`default_nettype none 

module audio_player(
    input wire clk_in,
    input wire [15:0] sw,
    input wire [7:0] sound_sample_in,
    input wire rst_in, 
    output logic signal_out
);

  
  logic clk_m;
  audio_clk_wiz macw (.clk_in(clk_in), .clk_out(clk_m)); //98.3MHz
  // we make 98.3 MHz since that number is cleanly divisible by
  // 32 to give us 3.072 MHz.  3.072 MHz is nice because it is cleanly divisible
  // by nice powers of 2 to give us reasonable audio sample rates. For example,
  // a decimation by a factor of 64 could give us 6 bit 48 kHz audio
  // a decimation by a factor of 256 gives us 8 bit 12 kHz audio
  //we do the latter in this lab.


  //logic to produce 25 MHz step signal for pdm module
  logic [1:0] pdm_counter;
  logic pdm_step; //single-cycle pdm step
  assign pdm_step = (pdm_counter==2'b11);

  always_ff @(posedge clk_m) begin
    pdm_counter <= pdm_counter + 1;
  end

  logic signed [7:0] vol_out;

  volume_control vc (
    .vol_in(sw[15:13]),
    .signal_in(sound_sample_in), 
    .signal_out(vol_out));

  logic pdm_out_signal;

  logic pdm_out_signal; 


  logic pdm_signal_valid;

  pdm my_pdm(
    .clk_in(clk_m),
    .rst_in(rst_in),
    .level_in(vol_out),
    .tick_in(pdm_step),
    .pdm_out(pdm_out_signal)
  );

  assign signal_out = pdm_out_signal; 


endmodule 

//Volume Control
module volume_control (
  input wire [2:0] vol_in,
  input wire signed [7:0] signal_in,
  output logic signed [7:0] signal_out);
    logic [2:0] shift;
    assign shift = 3'd7 - vol_in;
    assign signal_out = signal_in>>>shift;
endmodule

`default_nettype wire
    

    
    

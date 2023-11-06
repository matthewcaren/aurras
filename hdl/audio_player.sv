`timescale 1ns / 1ps
`default_nettype none 

module audio_player(
    input wire clk_in,
    input wire [15:0] sw,
    input wire [15:0] sound_sample_in,
    input wire audio_trigger_in, 
    input wire rst_in, 
    output logic signal_out
);

 
  //logic to produce 25 MHz step signal for pdm module
  // logic [1:0] pdm_counter;
  // logic pdm_step; //single-cycle pdm step
  // assign pdm_step = (pdm_counter==2'b11);

  // always_ff @(posedge clk_in) begin
  //   pdm_counter <= pdm_counter + 1;
  // end

  logic signed [15:0] vol_out;

  volume_control vc (
    .vol_in(sw[15:12]),
    .signal_in(sound_sample_in), 
    .signal_out(vol_out));

  pdm my_pdm(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .level_in(vol_out),
    .tick_in(audio_trigger_in),
    .pdm_out(signal_out)
  );

  // pwm my_pwm(
  //   .clk_in(clk_in),
  //   .rst_in(rst_in),
  //   .tick_in(audio_trigger_in),

  //   .
  //   .pwm_out(signal_out)
  // );
endmodule 

//Volume Control
module volume_control (
  input wire [3:0] vol_in,
  input wire signed [15:0] signal_in,
  output logic signed [15:0] signal_out);
    logic [3:0] shift;
    assign shift = 4'd15 - vol_in;
    assign signal_out = signal_in>>>shift;
endmodule

`default_nettype wire
    

    
    

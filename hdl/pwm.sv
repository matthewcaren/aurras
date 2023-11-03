`timescale 1ns / 1ps
`default_nettype none
module  pwm(
            input wire clk_in,
            input wire rst_in,
            input wire signed [7:0] level_in,
            input wire tick_in,
            output logic pwm_out
  );
  logic [7:0] level;
  //convert to unsigned (offset binary):
  //easier with pwm logic
  assign level = {~level_in[7],level_in[6:0]};

  logic [7:0] count;

  assign pwm_out = count<level;

  always_ff @(posedge clk_in)begin
    if (rst_in)begin
      count <= 8'b0;
    end else begin
      if (tick_in)begin
        count <= count+8'b1;
      end
    end
  end
endmodule
`default_nettype wire

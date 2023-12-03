`timescale 1ns / 1ps
`default_nettype none
module dc_blocker(  input wire clk_in,
                    input wire rst_in,
                    input wire audio_trigger,
                    input wire signed [15:0] signal_in,
                    output logic signed [15:0] signal_out
  );

  logic signed [15:0] current_input;
  logic signed [15:0] last_input;
  logic signed [15:0] last_result;

  // Eqn: y(n) = x(n) - x(n-1) + K*y(n-1), with K = 0.984
  assign signal_out = current_input - last_input + (last_result - (last_result >>> 6));

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      current_input <= 0;
      last_input <= 0;
      last_result <= 0;
    end else begin
      if (audio_trigger) begin
        current_input <= signal_in;
        last_input <= current_input;
        last_result <= signal_out;
      end
    end
  end
endmodule

`timescale 1ns / 1ps
`default_nettype wire

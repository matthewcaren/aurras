`timescale 1ns / 1ps
`default_nettype none


module pdm( input wire clk_in,
            input wire rst_in,
            input wire signed [15:0] level_in,
            output logic pdm_out
  );

  logic signed [16:0] stored_value;
  logic signed [15:0] feedback;

  assign pdm_out = rst_in ? silence : ~(stored_value[16]);
  assign feedback = stored_value[16] ? -'sd32768 : 'sd32767;

  logic [3:0] pdm_counter;
  logic pdm_trig;
  assign pdm_trig = (pdm_counter==0);

  logic silence;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      stored_value <= 0;
      pdm_counter <= 0;
      silence <= 0;
    end else begin
      pdm_counter <= pdm_counter + 1;
      if (pdm_trig) begin
        stored_value <= stored_value + level_in - feedback;
      end
    end

    silence <= ~silence;
  end
endmodule
`default_nettype wire
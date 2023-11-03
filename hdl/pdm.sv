`timescale 1ns / 1ps
`default_nettype none


module pdm(
            input wire clk_in,
            input wire rst_in,
            input wire signed [7:0] level_in,
            input wire tick_in,
            output logic pdm_out
  );
  //your code here!
  logic signed [9:0] accumulator = 10'sb0000000000; 
  logic signed [7:0] feedback = 8'sb00000000; 

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            pdm_out <= 0;  
        end
        else if (tick_in) begin
          feedback <= (accumulator > 0) ? 8'sb01111111 : 8'sb10000000;
          pdm_out <= feedback[7];
          
          accumulator <= $signed(accumulator) + $signed(level_in) - $signed(feedback);
        end

    end

endmodule


`default_nettype wire
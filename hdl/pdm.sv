`timescale 1ns / 1ps
`default_nettype none


module pdm(
            input wire clk_in,
            input wire rst_in,
            input wire signed [17:0] level_in,
            input wire tick_in,
            output logic pdm_out
  );
  logic signed [19:0] accumulator = 18'sb0000_0000_0000_0000_0000; 
  logic signed [17:0] feedback = 16'sb0000_0000_0000_000000; 

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            pdm_out <= 0;  
        end
        else if (tick_in) begin
          feedback <= (accumulator > 0) ? 18'sb0111_1111_1111_1111_11 : 18'sb1000_0000_0000_0000_00;
          pdm_out <= feedback[17];
          
          accumulator <= $signed(accumulator) + $signed(level_in) - $signed(feedback);
        end

    end

endmodule


`default_nettype wire
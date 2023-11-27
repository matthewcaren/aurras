`timescale 1ns / 1ps
`default_nettype none

module frequency_sweep (
  input wire clk_in,
  input wire rst_in,
  output wire [15:0] sound_out
);

// Paramaters to be adjusted based on desired outcome
parameter sweep_start_freq = 1000; 
parameter sweep_stop_freq = 20000; 

logic [31:0] counter, accumulator, phase_increment = 0; 

always_ff @(posedge clk_in) begin 
    if (rst_in) begin
        counter <= 0; 
        accumulator <= 0;
        phase_increment <= 0; 
    end else begin 
        
    end 
end

 

endmodule


`timescale 1ns / 1ps
`default_nettype wire

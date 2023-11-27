`timescale 1ns / 1ps
`default_nettype none

module frequency_sweep (
  input wire clk_in,
  input wire rst_in,
  output logic signed [15:0] sound_out
);

// Paramaters to be adjusted based on desired outcome
parameter sweep_start_freq = 1000; // 1khz
parameter sweep_stop_freq = 20000; // 20khz
parameter sweep_duration =  10_000_000; // this means the sweep will last 10 seconds
parameter clock_frequency = 100_000_000; // 100Mhz

logic [31:0] counter, accumulator, phase_increment = 0; 

always_ff @(posedge clk_in) begin 
    if (rst_in) begin
        counter <= 0; 
        accumulator <= 0;
        phase_increment <= 0; 
    end else begin 
        if (counter < sweep_duration) begin 
            counter <= counter + 1; 
            accumulator <= accumulator + phase_increment; 


            // Output the msb 
            sound_out <= accumulator[31]; 
        end 
    end 
end

 

endmodule


`timescale 1ns / 1ps
`default_nettype wire

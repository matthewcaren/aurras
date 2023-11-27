`timescale 1ns / 1ps
`default_nettype none

module frequency_sweep (
  input wire clk_in,
  input wire rst_in,
  output logic signed [15:0] sound_out
);

// Parameters to be adjusted based on desired outcome
parameter sweep_start_freq = 1000; // 1khz
parameter sweep_stop_freq = 20000; // 20khz
parameter sweep_duration =  10_000_000; // this means the sweep will last 10 seconds
parameter clock_frequency = 100_000_000; // 100Mhz

logic [31:0] counter, accumulator, phase_increment = 0; 

// Adjust the phase increment dynamically 
// To generate a waveform of f freq, the accumulator must complete a full cycle (overflow and wrap back) f times per second 
// One complete cycle of accumulator is the number 2^32 units. 
// We add to the accumulator every clock cycle, so for each clock cycle, we need to add (f_desired/f_clock) * 2^32 

// Do some sort of LUT for the phase increment since the below equation is probably not feasible. 

//assign phase_increment = (sweep_start_freq +  ((sweep_stop_freq - sweep_start_freq) * counter/sweep_duration) * 2 ** 32 / clock_frequency )

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

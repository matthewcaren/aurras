`timescale 1ns / 1ps
`default_nettype none

module convolve_audio(input wire audio_clk,
                      input wire rst_in,
                      input wire audio_trigger,
                      input wire signed [15:0] audio_in,
                      input wire [15:0] delay_length,
                      input wire [15:0] impulse_length,
                      input wire impulse_complete,
                      output logic signed [15:0] convolved_audio);



    delayed_sound_out delayed_audio(.clk_in(audio_clk),
                                    .rst_in(rst_in), 
                                    .audio_valid_in(audio_trigger), 
                                    .enable_delay(impulse_complete), 
                                    .delay_cycle(delay_length - 1),
                                    .audio_in(convolved_audio_to_memory),
                                    .delayed_audio_out(convolved_audio));

    logic signed [47:0] build_up_sum; 


    typedef enum logic [1:0] {WAITING_FOR_AUDIO = 0, CONVOLVING = 1, TRANSMITTING = 2} convolving_state;
    convolving_state state;
    logic [15:0] cycles_completed;
    
    always_ff @(posedge audio_clk) begin
        if (rst_in) begin
            build_up_sum <= 0;
            state <= WAITING_FOR_AUDIO
        end else begin
            case (state)
                WAITING_FOR_AUDIO: begin
                    build_up_sum <= 0;
                    if (audio_trigger) begin
                        state <= CONVOLVING;
                    end 
                end 

                CONVOLVING: begin

                end

                TRANSMITTING: begin
                    convolved_audio <= build_up_sum[47:32];
                    state <= WAITING_FOR_AUDIO;
                end

                default: begin
                    state <= WAITING_FOR_AUDIO;
                    build_up_sum <= 0;
                end
            endcase 
        end
    end 


endmodule

`timescale 1ns / 1ps
`default_nettype wire
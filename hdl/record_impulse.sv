
`timescale 1ns / 1ps
`default_nettype none

module record_impulse #(parameter IMPULSE_LENGTH = 16'd24000) 
    (input wire audio_clk,
     input wire rst_in,
     input wire audio_trigger,
     input wire record_impulse_trigger,
     input wire [15:0] delay_length,
     input wire signed [15:0] audio_in,
     
     output logic impulse_recorded,
     output logic [15:0] ir_sample_index,
     output logic signed [15:0] write_data,
     output logic write_enable,
     output logic ir_data_in_valid,
     output logic signed [15:0] impulse_amp_out
    );

    typedef enum logic [1:0] {WAITING_FOR_IMPULSE = 0, DELAYING = 1, RECORDING = 2} impulse_record_state;
    logic impulse_completed;
    logic [15:0] delayed_so_far, recorded_so_far;
    impulse_record_state state;

    impulse_generator generate_impulse(.clk_in(audio_clk),
                                        .rst_in(rst_in),
                                        .step_in(audio_trigger),
                                        .impulse_in(record_impulse_trigger),
                                        .impulse_out(impulse_completed),
                                        .amp_out(impulse_amp_out));

 
    always_ff @(posedge audio_clk) begin
        if (rst_in) begin
            delayed_so_far <= 0;
            recorded_so_far <= 0;
            impulse_recorded <= 0;
            ir_sample_index <= 0;
            write_enable <= 0;
            ir_data_in_valid <= 0;
            state <= WAITING_FOR_IMPULSE;
        end else begin
            case (state)
                WAITING_FOR_IMPULSE: begin
                    ir_sample_index <= 0;
                    recorded_so_far <= 0;
                    delayed_so_far <= 0;
                    ir_data_in_valid <= 0;
                    write_enable <= 0;
                    impulse_recorded <= 0;
                    if (impulse_completed) begin
                        state <= DELAYING;
                        
                        delayed_so_far <= 1;
                    end 
                end 
                DELAYING: begin
                    if (audio_trigger) begin
                        if (delayed_so_far == (delay_length - 1)) begin
                            state <= RECORDING;
                            write_enable <= 1;
                        end else begin
                            delayed_so_far <= delayed_so_far + 1;
                        end
                    end
                end
                RECORDING: begin
                    if (audio_trigger) begin
                        ir_data_in_valid <= 1;
                        if (recorded_so_far == IMPULSE_LENGTH) begin
                            impulse_recorded <= 1;
                            write_enable <= 0;
                            state <= WAITING_FOR_IMPULSE;
                            ir_data_in_valid <= 0;
                        end else begin
                            // if ((recorded_so_far >= 16'd18000) && (recorded_so_far < 16'd18002)) begin
                            //     write_data <= recorded_so_far - 15000;
                            // end else begin
                            //     write_data <= 0;
                            // end
                            ir_sample_index <= recorded_so_far;
                            write_data <= audio_in;
                            recorded_so_far <= recorded_so_far + 1;
                        end
                    end else begin
                        ir_data_in_valid <= 0;
                    end
                end 
                default: begin
                    impulse_recorded <= 0;
                    delayed_so_far <= 0;
                    recorded_so_far <= 0;
                    ir_sample_index <= 0;
                    ir_data_in_valid <= 0;
                    write_enable <= 0;
                    state <= WAITING_FOR_IMPULSE;
                end 
            endcase 
        end

    end

endmodule

`timescale 1ns / 1ps
`default_nettype wire
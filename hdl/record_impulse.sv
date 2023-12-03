
`timescale 1ns / 1ps
`default_nettype none

module record_impulse(
    input wire audio_clk,
    input wire rst_in,
    input wire audio_trigger,
    input wire record_impulse_trigger,
    input wire [15:0] impulse_length,
    input wire [15:0] delay_length,
    input wire [15:0] audio_in,
    input wire redo_impulse,
    output logic impulse_recorded
    );
    
    logic [15:0] impulse_amp_out;
    logic impulse_completed;
    impulse_generator generate_impulse(.clk_in(audio_clk),
                                        .rst_in(rst_in),
                                        .step_in(audio_trigger),
                                        .impulse_in(record_impulse_trigger),
                                        .impulse_out(impulse_completed),
                                        .amp_out(impulse_amp_out));

    typedef enum logic [2:0] {WAITING_FOR_IMPULSE = 0, DELAYING = 1, RECORDING = 2, COMPLETE = 3} impulse_record_state;
    logic [15:0] delayed_so_far;
    logic [15:0] recorded_so_far;
    logic [15:0] write_data;
    logic [15:0] write_addr;
    impulse_record_state state;
    always_ff @(posedge audio_clk) begin
        if (rst_in) begin
            delayed_so_far <= 0;
            recorded_so_far <=0;
            state <= WAITING_FOR_IMPULSE;
            impulse_recorded <= 0;
            write_addr <= 0;
        end else begin
            case (state)
                WAITING_FOR_IMPULSE: begin
                    if (impulse_completed) begin
                        state <= DELAYING;
                        delayed_so_far <= 1;
                    end 
                end 
                DELAYING: begin
                    if (audio_trigger) begin
                        if (delayed_so_far == (delay_length - 1)) begin
                            state <= RECORDING;
                        end else begin
                            delayed_so_far <= delayed_so_far + 1;
                        end
                    end
                end
                RECORDING: begin
                    if (audio_trigger) begin
                        if (recorded_so_far == impulse_length) begin
                            impulse_recorded <= 1;
                            state <= COMPLETE;
                        end else begin
                            write_data <= audio_in;
                            write_addr <= recorded_so_far;
                            recorded_so_far <= recorded_so_far + 1;
                        end
                    end
                end 
                COMPLETE: begin
                    if (redo_impulse) begin
                        impulse_recorded <= 0;
                        state <= WAITING_FOR_IMPULSE;
                    end
                end
                default: begin
                    impulse_recorded <= 0;
                    delayed_so_far <= 0;
                    recorded_so_far <= 0;
                    write_addr <= 0;
                    state <= WAITING_FOR_IMPULSE;
                end 
            endcase 
        end

    end

endmodule

`timescale 1ns / 1ps
`default_nettype wire
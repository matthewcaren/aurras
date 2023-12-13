`timescale 1ns / 1ps
`default_nettype none

module calculate_offset (input wire audio_clk,
                        input wire rst_in,
                        input wire audio_trigger,
                        input wire offset_trigger,
                        input wire signed [15:0] audio_in,
                        output logic signed [15:0] offset,
                        output logic offset_produced);

    logic signed [35:0] sum_of_offsets;
    logic [16:0] cycle_counter;
    typedef enum logic [1:0] {WAITING_FOR_TRIGGER = 0, ACCUMULATING = 1, COMPUTING = 2} offset_state;
    offset_state state;
    always_ff @(posedge audio_clk) begin
        if (rst_in) begin
            offset <= 0;
            sum_of_offsets <= 0;
            cycle_counter <= 0;
            offset_produced <= 0;
            state <= WAITING_FOR_TRIGGER;
        end else begin
            case (state)
                WAITING_FOR_TRIGGER : begin
                    offset <= 0;
                    sum_of_offsets <= 0;
                    cycle_counter <= 0;
                    offset_produced <= 0;
                    if (offset_trigger) begin
                        state <= ACCUMULATING;
                    end
                end 
                ACCUMULATING : begin
                    if (audio_trigger) begin
                         if (cycle_counter == 16'd32768) begin
                            state <= COMPUTING;
                         end else begin
                            sum_of_offsets <= sum_of_offsets + audio_in;
                            cycle_counter <= cycle_counter + 1;
                         end
                    end
                end 
                COMPUTING : begin
                    state <= WAITING_FOR_TRIGGER;
                    offset_produced <= 1;
                    offset <= (sum_of_offsets >>> 4'd15);
                end 
                default : begin
                    offset <= 0;
                    sum_of_offsets <= 0;
                    cycle_counter <= 0;
                    offset_produced <= 0;
                    state <= WAITING_FOR_TRIGGER;
                end
            endcase
        end



    end

endmodule
`timescale 1ns / 1ps
`default_nettype wire

`timescale 1ns / 1ps
`default_nettype none

/**
 * Speed-of-sound distance calculator using speaker output + mic input.
 *
 * Transient detection algorithm: every 5-10ms window, sum total energy. If current window's energy is
 * greater than previous window and at least 1.5x the energy of the one before that, there's a transient.
 *
 * Reference: http://www.acad.bg/rismim/itc/sub/archiv/Paper4_3_2012.pdf
 */

module sos_dist_calculator #(
  parameter WINDOW_SIZE = 16,     // ~150 for most accurate, lower means less latent
  parameter MAX_DELAY = 256
) (
  input wire clk_in,
  input wire rst_in,
  input wire step_in,
  input wire trigger,
  input wire [7:0] mic_in,
  output logic signed [15:0] amp_out,    // audio out
  output logic [7:0] delay,              // # of 24 kHz cycles
  output logic delay_valid);

  typedef enum {WAITING_FOR_FIRST=1, AWAITING_IMPULSE=2, ANALYZING_RESPONSE=3, STARTING_IMPULSE = 4, DELAYING = 5} system_state;

  system_state state;

  logic impulse_trigger, impulse_out;
  logic [$clog2(MAX_DELAY):0] delay_cycle_counter;      // 8-bit: 2^8=256 cycles is 3.6 meters max

  logic [31:0] current_window_sum, prev_window_sum, prev_prev_window_sum;    // ## TODO FIGURE OUT WIDTH
  logic [$clog2(WINDOW_SIZE):0] window_ix_counter;

	logic [25:0] delay_counter;
  logic [7:0] last_delay;
  logic [7:0] two_delays_ago;

  impulse_generator imp_gen (
  .clk_in(clk_in),
  .rst_in(rst_in),
  .step_in(step_in),
  .impulse_in(impulse_trigger),
  .impulse_out(impulse_out),
  .amp_out(amp_out));


  always_ff @(posedge clk_in) begin
    if (rst_in) begin
        delay <= 0;
        two_delays_ago <= 0;
        last_delay <= 0;
        delay_valid <= 0;
        impulse_trigger <= 0;
        delay_cycle_counter <= 0;
        delay_counter <= 0;
        state <= WAITING_FOR_FIRST;
    end else case (state)
            WAITING_FOR_FIRST: begin
                if (trigger) begin
                    state <= STARTING_IMPULSE;
                end
                delay_counter <= 0;
                impulse_trigger <= 0;
            end
            DELAYING: begin
                delay_counter <= delay_counter + 1;
                if (delay_counter == 26'd40_000_000) begin
                    delay_counter <= 0;
                    state <= STARTING_IMPULSE;
                end
            end
            STARTING_IMPULSE: begin
                impulse_trigger <= 1;
                delay_valid <= 0;
                state <= AWAITING_IMPULSE;
            end
            AWAITING_IMPULSE: begin
                impulse_trigger <= 0;

                if (impulse_out) begin
                    // set up variables for transient detection algo
                    prev_window_sum <= 32'hFFFF_FFFF;
                    prev_prev_window_sum <= 32'hFFFF_FFFF;
                    window_ix_counter <= 0;
                    delay_cycle_counter <= 0;

                    state <= ANALYZING_RESPONSE;
                end
            end

            ANALYZING_RESPONSE: begin
                if (step_in) begin
                    // if we hit max delay without detecting an onset, reset
                    if (delay_cycle_counter == MAX_DELAY) begin
                        delay <= 0;
                        delay_valid <= 0;
                        impulse_trigger <= 0;
                        delay_cycle_counter <= 0;
                        state <= WAITING_FOR_FIRST;
                    end else begin
                        // end of window
                        if (window_ix_counter == WINDOW_SIZE) begin
                            // check for transient
                            if ((current_window_sum > prev_window_sum) && (current_window_sum > (prev_prev_window_sum + prev_prev_window_sum >> 1))) begin
                                two_delays_ago <= last_delay;
                                last_delay <= delay_cycle_counter;
                                if ((two_delays_ago == last_delay) && (last_delay == delay_cycle_counter)) begin
                                    delay <= delay_cycle_counter;
                                    delay_valid <= 1;
                                    state <= WAITING_FOR_FIRST;
                                end else begin
                                    state <= DELAYING;
                                end
                            end

                            // otherwise keep going
                            else begin
                                window_ix_counter <= 0;
                                current_window_sum <= 0;
                                prev_window_sum <= current_window_sum;
                                prev_prev_window_sum <= prev_window_sum;
                            end
                        end else begin
                            window_ix_counter <= window_ix_counter + 1;
                            delay_cycle_counter <= delay_cycle_counter + 1;
                            current_window_sum <= (mic_in^(mic_in >> 31)) - (mic_in >> 31);  // take absolute value of mic_in
                        end
                    end
                end
            end

            default: begin
                delay <= 0;
                two_delays_ago <= 0;
                last_delay <= 0;
                delay_valid <= 0;
                impulse_trigger <= 0;
                delay_cycle_counter <= 0;
                delay_counter <= 0;
                state <= WAITING_FOR_FIRST;
            end
        endcase
    end

endmodule

`default_nettype wire

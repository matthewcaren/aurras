`timescale 1ns / 1ps
`default_nettype none

/**
 * Outputs a single-cycle impulse on the next audio cycle after impulse_in goes HI.
 */

module impulse_generator (
  input wire clk_in,
  input wire rst_in,
  input wire step_in,
  input wire impulse_in,                // impulse trigger signal
  output logic impulse_out,             // HI for one cycle at start of impulse
  output logic signed [15:0] amp_out);  // audio out

  typedef enum {WAITING=0, WILL_SEND_IMPULSE=1, SENT_IMPULSE=2} system_state;

  system_state state;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
        impulse_out <= 0;
        amp_out <= 16'sd0;
        state <= WAITING;
    end else begin
        case (state)
            WAITING: begin
                amp_out <= 16'sd0;
                if (impulse_in) begin
                    state <= WILL_SEND_IMPULSE;
                end
            end

            WILL_SEND_IMPULSE: begin
                if (step_in) begin
                    amp_out <= 16'sd16384; // 50% amplitude
                    impulse_out <= 1;
                    state <= SENT_IMPULSE;
                end
            end

            SENT_IMPULSE: begin
                impulse_out <= 0;
                if (step_in) begin
                    amp_out <= 16'sd0;
                    state <= WAITING;
                end
            end
        endcase
    end
  end

endmodule

`default_nettype wire
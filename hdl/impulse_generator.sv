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

  typedef enum logic [2:0] {WAITING=0, WILL_SEND_IMPULSE=1, SENDING_IMPULSE=2, SENT_IMPULSE=3, HOLDING=4} system_state;
  
  logic [7:0] impulse_length_counter;

  system_state state;
  logic [28:0] holding_counter;
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
        impulse_out <= 0;
        amp_out <= 16'sd0;
        state <= WAITING;
        holding_counter <= 0;
    end else begin
        case (state)
            WAITING: begin
                holding_counter <= 0;
                amp_out <= 16'sd0;
                if (impulse_in) begin
                    state <= HOLDING;
                end
            end
            HOLDING : begin
                holding_counter <= holding_counter + 1;
                if (holding_counter == 32'd140_000_000) begin
                    state <= WILL_SEND_IMPULSE;
                    end
                end
						
            WILL_SEND_IMPULSE: begin
                if (step_in) begin
                    amp_out <= 16'shCFFF;
                    impulse_length_counter <= 0;
                    state <= SENDING_IMPULSE;
                end
            end

            SENDING_IMPULSE: begin
                if (step_in) begin
                    if (impulse_length_counter == 8'h8F) begin
                        impulse_out <= 1;
                        state <= SENT_IMPULSE;
                    end else begin
                        impulse_length_counter <= impulse_length_counter + 1;
                    end
                end
            end

            SENT_IMPULSE: begin
                impulse_out <= 0;
                if (step_in) begin
                    amp_out <= 16'sd0;
                    state <= WAITING;
                end
            end

            default: begin
                impulse_out <= 0;
                amp_out <= 16'sd0;
                state <= WAITING;
								holding_counter <= 0;
            end

        endcase

    end
  end

endmodule

`default_nettype wire

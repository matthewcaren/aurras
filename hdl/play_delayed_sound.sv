`timescale 1ns / 1ps
`default_nettype none


module delayed_sound_out(
  input wire clk_in,
  input wire rst_in,
  input wire signed [15:0] audio_in,
  input wire record_in,
  input wire audio_valid_in,
  output logic signed [16:0] signal_out,
  output logic signed [16:0] echo_out
  );

  logic [15:0] mem_addr, record_addr, playback_addr, echo_addr_1, echo_addr_2, max_record_addr;
  logic [7:0] audio_from_memory_a; 
  logic [7:0] echo1_sample, echo2_sample;

  typedef enum {READ_MAIN=0, READ_ECHO1=1, READ_ECHO2=2} states_t;
  states_t major_fsm_state;

  //assign mem_addr = record_in? record_addr : playback_addr; 

  always_ff @(posedge clk_in) begin
      if (rst_in) begin
          major_fsm_state <= READ_MAIN;
          record_addr <= 16'd0;
          playback_addr <= 16'd0;
          echo_addr_1 <= 16'd0;
          echo_addr_2 <= 16'd0;
          max_record_addr <= 16'd0;
          signal_out <= 8'd0;
          echo_out <= 8'd0;
      end else begin
          case(major_fsm_state)
              READ_MAIN: begin
                  mem_addr <= playback_addr;
                  if (audio_valid_in) begin
                      playback_addr <= playback_addr + 1'b1;
                      echo_addr_1 <= playback_addr - 16'd1500;
                      echo_addr_2 <= playback_addr - 16'd3000;
                      signal_out <= audio_from_memory_a;
                      record_addr <= 16'd0; //need this so we don't concatenate different recordings


                      if (record_in) begin
                          record_addr <= record_addr + 1'b1;
                          max_record_addr <= record_addr + 1'b1;
                      end

                      if (playback_addr >= max_record_addr) begin 
                        //push back playback_addr if we exceed the max_recording_addr - removes the blank sound bug at the beginning
                        playback_addr <= 16'd0;
                      end
                  end
                major_fsm_state <= READ_ECHO1;
              end //still works even without using dummy states so left it as this

              READ_ECHO1: begin
                  mem_addr <= echo_addr_1;
                  echo1_sample <= audio_from_memory_a;
                  major_fsm_state <= READ_ECHO2;
              end

              READ_ECHO2: begin
                  mem_addr <= echo_addr_2;
                  echo2_sample <= audio_from_memory_a;
                  echo_out <= signal_out + echo1_sample + echo2_sample;
                  major_fsm_state <= READ_MAIN;
              end
          endcase
      end
  end

    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(16),
        .RAM_DEPTH(2048)) 
        
        audio_buffer (
        .addra(mem_addr),
        .clka(clk_in),
        .wea(record_in && audio_valid_in),
        .dina(audio_in),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(rst_in),
        .douta(audio_from_memory_a),
        .addrb(),
        .dinb(),
        .clkb(),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst_in),
        .regceb(1'b1),
        .doutb() //not actually used 
    );

endmodule
`default_nettype wire

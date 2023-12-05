`timescale 1ns / 1ps
`default_nettype none

module convolve_audio #(parameter impulse_length = 48000) (
                      input wire audio_clk,
                      input wire rst_in,
                      input wire audio_trigger,
                      input wire signed [15:0] audio_in,
                      input wire [15:0] delay_length,
                      input wire impulse_in_memory_complete,
                      output logic signed [15:0] convolved_audio,
                      output logic [15:0] ir_live_read_addr,
                      input wire signed [1023:0] ir_live_read_data);

    // delayed_sound_out delayed_audio(.clk_in(audio_clk),
    //                                 .rst_in(rst_in), 
    //                                 .audio_valid_in(audio_trigger), 
    //                                 .enable_delay(impulse_in_memory_complete), 
    //                                 .delay_cycle(delay_length - 1),
    //                                 .audio_in(convolved_audio_to_memory),
    //                                 .delayed_audio_out(convolved_audio));


    // convolve_line line_convolver(.ir_line(ir_line),
    //                              .audio_line(audio_line),
    //                              .convolved_line(convolved_line));

    logic signed [47:0] convolution_result;
    logic [15:0] live_read_addr, live_write_addr;
    logic [1023:0] live_read_data, live_write_data;
    logic live_write_enable;

    typedef enum logic [2:0] {WAITING_FOR_AUDIO = 0, CONVOLVING = 1, TRANSMITTING = 2, CONV_BATCH = 3, READING_AUDIO_BUFFER = 4, WRITING_AUDIO_BUFFER = 5} convolving_state;
    convolving_state state;
    logic [15:0] cycles_completed;

    logic [15:0] audio_buffer_index;
    logic [4:0] fsm_transition_delay_counter;
    
    always_ff @(posedge audio_clk) begin
        if (rst_in) begin
            convolution_result <= 0;
            state <= WAITING_FOR_AUDIO;
        end else begin
            case (state)
                WAITING_FOR_AUDIO: begin
                    convolution_result <= 0;

                    if (audio_trigger) begin
                        state <= READING_AUDIO_BUFFER;
                        fsm_transition_delay_counter <= 0;
                    end 
                end

                READING_AUDIO_BUFFER: begin
                    live_read_addr <= (audio_buffer_index >> 6);
                    
                    if (fsm_transition_delay_counter == 2'd2) begin
                        fsm_transition_delay_counter <= 0;
                        state <= WRITING_AUDIO_BUFFER;
                    end else begin
                        fsm_transition_delay_counter <= fsm_transition_delay_counter + 1;
                    end
                end

                WRITING_AUDIO_BUFFER: begin
                    live_write_enable <= 1;
                    // live_write_data[((audio_buffer_index[5:0]) << 4) + 15 : ((audio_buffer_index[5:0]) << 4)] <= audio_in
                    live_write_data <= (audio_buffer_index[5:0] == 0) ?
                        ({audio_in, live_read_data[(((audio_buffer_index[5:0]) << 4) - 1) : 0]}) :
                        ((audio_buffer_index[5:0] == 63) ?
                        ({live_read_data[1023 : (((audio_buffer_index[5:0]) << 4) + 16)], audio_in}) :
                        ({live_read_data[1023 : (((audio_buffer_index[5:0]) << 4) + 16)], audio_in, live_read_data[(((audio_buffer_index[5:0]) << 4) - 1) : 0]}));
                    

                    if (fsm_transition_delay_counter == 2'd1) begin
                        fsm_transition_delay_counter <= 0;
                        live_write_enable <= 0;
                        state <= CONV_BATCH;
                    end else begin
                        fsm_transition_delay_counter <= fsm_transition_delay_counter + 1;
                    end
                end


                CONV_BATCH: begin
                    
                    audio_buffer_index <= audio_buffer_index + 1;
                    convolution_result
                    for (i )
                end

                default: begin
                    state <= WAITING_FOR_AUDIO;
                    convolution_result <= 0;
                end
            endcase 
        end
    end 



    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(1024),
        .RAM_DEPTH(impulse_length)
    ) impulse_memory (
        .addra(live_write_addr),
        .clka(audio_clk),
        .wea(live_write_enable),
        .dina(live_write_data),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(rst_in),
        .douta(),
        .addrb(live_read_addr),
        .dinb(),
        .clkb(audio_clk),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst_in),
        .regceb(1'b1),
        .doutb(live_read_data)
    );
    
endmodule

`timescale 1ns / 1ps
`default_nettype wire
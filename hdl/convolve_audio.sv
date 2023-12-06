`timescale 1ns / 1ps
`default_nettype none

module convolve_audio #(parameter IMPULSE_LENGTH = 24000) (
                      input wire audio_clk,
                      input wire rst_in,
                      input wire audio_trigger,
                      input wire signed [15:0] audio_in,
            
                      input wire impulse_in_memory_complete,
                      output logic signed [47:0] convolution_result,
                      output logic produced_convolutional_result,
                      
                      output logic [11:0] first_ir_index,
                      output logic [11:0] second_ir_index,
                      output logic convolving,
                      input wire signed [7:0][15:0] ir_vals);


    localparam MEMORY_DEPTH = IMPULSE_LENGTH >> 3;

    typedef enum logic [2:0] {WAITING_FOR_AUDIO = 0, CONVOLVING = 1, ADDING_FINAL_VALUES = 2, WAITING_FOR_IMPULSE = 3,READING_AUDIO_BUFFER = 4, WRITING_AUDIO_BUFFER = 5} convolving_state;
    convolving_state state;

    logic [4:0] fsm_transition_delay_counter;

    // Goes from 0 to 5999
    logic [11:0] live_audio_start_address;
    logic [15:0] last_value_brom0, last_value_brom1, last_value_brom2, last_value_brom3;
    logic [15:0] data_in_brom0, data_in_brom1, data_in_brom2, data_in_brom3;
    logic live_write_enable;

    logic [7:0][47:0] intermediate_sums;
    logic [7:0][15:0] audio_vals;
    
    logic [3:0] adding_counter;
    logic [15:0] convolve_counter;

    logic [11:0] first_audio_index, second_audio_index;

    assign audio_vals[0] = last_value_brom0;
    assign audio_vals[2] = last_value_brom1;
    assign audio_vals[4] = last_value_brom2;
    assign audio_vals[6] = last_value_brom3;

    always_ff @(posedge audio_clk) begin
        if (rst_in) begin
            convolution_result <= 0;
            live_audio_start_address <= 0;
            fsm_transition_delay_counter <= 0;
            produced_convolutional_result <= 0;
            state <= WAITING_FOR_IMPULSE;
            adding_counter <= 0;
            convolve_counter <= 0;
            convolving <= 0;
            for (integer i = 0; i < 8; i = i + 1) begin
                intermediate_sums[i] <= 0;
            end

        end else begin
            case (state)

                WAITING_FOR_IMPULSE: begin
                    if (impulse_in_memory_complete) begin
                        state <= WAITING_FOR_AUDIO;
                    end
                end
                WAITING_FOR_AUDIO: begin
                    for (integer i = 0; i < 8; i = i + 1) begin
                        intermediate_sums[i] <= 0;
                    end
                    convolution_result <= 0;
                    fsm_transition_delay_counter <= 0;
                    adding_counter <= 0;
                    produced_convolutional_result <= 0;
                    convolve_counter <= 0;
                    convolving <= 0;
                    if (audio_trigger) begin
                        state <= READING_AUDIO_BUFFER;
                        fsm_transition_delay_counter <= 0;
                    end 
                end

                READING_AUDIO_BUFFER: begin 
                    if (fsm_transition_delay_counter == 2'd2) begin
                        fsm_transition_delay_counter <= 0;
                        state <= WRITING_AUDIO_BUFFER;
                        live_write_enable <= 1;
                    end else begin
                        fsm_transition_delay_counter <= fsm_transition_delay_counter + 1;
                    end
                end

                WRITING_AUDIO_BUFFER: begin
                    data_in_brom0 <= audio_in;
                    data_in_brom1 <= last_value_brom0;
                    data_in_brom2 <= last_value_brom1;
                    data_in_brom3 <= last_value_brom2;
                    if (fsm_transition_delay_counter == 2'd1) begin
                        fsm_transition_delay_counter <= 0;
                        live_write_enable <= 0;
                        state <= CONVOLVING;
                        convolving <= 1;
                    end else begin
                        fsm_transition_delay_counter <= fsm_transition_delay_counter + 1;
                    end
                end

                CONVOLVING: begin
                    // iterate i from 0 to 3002
                    // if i < 3000: read ith "value" (really i, i + 1 from 4 broms)
                    // if i > 2: convolve "ith-3" value

                    if (convolve_counter < 16'd3000) begin
                        first_ir_index <= (convolve_counter << 1);
                        second_ir_index <= (convolve_counter << 1) + 1; 
                        
                        first_audio_index <= (((convolve_counter << 1) + live_audio_start_address) >= 16'd6000) ? 
                                             (((convolve_counter << 1) + live_audio_start_address) - 16'd6000) : 
                                             ((convolve_counter << 1) + live_audio_start_address);

                        second_audio_index <= (((convolve_counter << 1) + live_audio_start_address + 1) >= 16'd6000) ?
                                              (((convolve_counter << 1) + live_audio_start_address + 1) - 16'd6000) :
                                              ((convolve_counter << 1) + live_audio_start_address + 1);
                    end

                        

                    // Loop over 3000 

                    if (convolve_counter > 2) begin
                        intermediate_sums[0] <= intermediate_sums[0] + ir_vals[0] * audio_vals[0];
                        intermediate_sums[1] <= intermediate_sums[1] + ir_vals[1] * audio_vals[1];
                        intermediate_sums[2] <= intermediate_sums[2] + ir_vals[2] * audio_vals[2];
                        intermediate_sums[3] <= intermediate_sums[3] + ir_vals[3] * audio_vals[3];
                        intermediate_sums[4] <= intermediate_sums[4] + ir_vals[4] * audio_vals[4];
                        intermediate_sums[5] <= intermediate_sums[5] + ir_vals[5] * audio_vals[5];
                        intermediate_sums[6] <= intermediate_sums[6] + ir_vals[6] * audio_vals[6];
                        intermediate_sums[7] <= intermediate_sums[7] + ir_vals[7] * audio_vals[7];
                    end 

                    if (convolve_counter == 16'd3003) begin
                        convolving <= 0;
                        state <= ADDING_FINAL_VALUES;
                    end
                    convolve_counter <= convolve_counter + 1;
                end

                ADDING_FINAL_VALUES : begin
                    if (adding_counter == 4'd8) begin
                        live_audio_start_address <= (live_audio_start_address == 16'd5999) ? 0 : (live_audio_start_address + 1);
                        state <= WAITING_FOR_AUDIO;
                        produced_convolutional_result <= 1;
                    end else begin
                        convolution_result <= convolution_result + intermediate_sums[adding_counter];
                    end
                    adding_counter <= adding_counter + 1;
                end

                default: begin
                    state <= WAITING_FOR_IMPULSE;
                    convolution_result <= 0;
                    fsm_transition_delay_counter <= 0;
                    live_audio_start_address <= 0;
                    adding_counter <= 0;
                    produced_convolutional_result <= 0;
                    convolve_counter <= 0;
                    convolving <= 0;
                    for (integer i = 0; i < 8; i = i + 1) begin
                        intermediate_sums[i] <= 0;
                    end
                end
            endcase 
        end
    end 

    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(16),
        .RAM_DEPTH(MEMORY_DEPTH)
    ) audio_buffer_bram_0 (
        .addra(convolving ? first_audio_index : live_audio_start_address),
        .clka(audio_clk),
        .wea(live_write_enable),
        .dina(data_in_brom0),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(rst_in),
        .douta(last_value_brom0),
        .addrb(second_audio_index),
        .dinb(),
        .clkb(audio_clk),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst_in),
        .regceb(1'b1),
        .doutb(audio_vals[1])
    );

    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(16),
        .RAM_DEPTH(MEMORY_DEPTH)
    ) audio_buffer_bram_1 (
        .addra(convolving ? first_audio_index : live_audio_start_address),
        .clka(audio_clk),
        .wea(live_write_enable),
        .dina(data_in_brom1),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(rst_in),
        .douta(last_value_brom1),
        .addrb(second_audio_index),
        .dinb(),
        .clkb(audio_clk),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst_in),
        .regceb(1'b1),
        .doutb(audio_vals[3])
    );

    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(16),
        .RAM_DEPTH(MEMORY_DEPTH)
    ) audio_buffer_bram_2 (
        .addra(convolving ? first_audio_index : live_audio_start_address),
        .clka(audio_clk),
        .wea(live_write_enable),
        .dina(data_in_brom2),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(rst_in),
        .douta(last_value_brom2),
        .addrb(second_audio_index),
        .dinb(),
        .clkb(audio_clk),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst_in),
        .regceb(1'b1),
        .doutb(audio_vals[5])
    );

    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(16),
        .RAM_DEPTH(MEMORY_DEPTH)
    ) audio_buffer_bram_3 (
        .addra(convolving ? first_audio_index : live_audio_start_address),
        .clka(audio_clk),
        .wea(live_write_enable),
        .dina(data_in_brom3),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(rst_in),
        .douta(last_value_brom3),
        .addrb(second_audio_index),
        .dinb(),
        .clkb(audio_clk),
        .web(1'b0),
        .enb(1'b1),
        .rstb(rst_in),
        .regceb(1'b1),
        .doutb(audio_vals[7])
    );
    
endmodule

`timescale 1ns / 1ps
`default_nettype wire
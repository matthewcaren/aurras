`timescale 1ns / 1ps
`default_nettype none

module process_audio (input wire audio_clk,
                      input wire rst_in,
                      input wire audio_trigger,
                      input wire mic_data_valid,
                      input wire signed [15:0] raw_audio_single_cycle,
                      output logic signed [15:0] processed_audio
                      );


    // DC Offset correction
    logic signed [15:0] raw_audio_in;
    always_ff @(posedge audio_clk) begin
        if (mic_data_valid) begin
            raw_audio_in <= raw_audio_single_cycle;
        end
    end

    logic signed [15:0] OFFSET, offset_singlecycle, dc_blocked_audio_in;
    logic offset_produced, offset_produced_singlecycle, offset_trigger;
    always_ff @(posedge audio_clk) begin
        if (rst_in) begin
            offset_trigger <= 1;
        end else begin
            offset_trigger <= 0;
        end   
    end

    calculate_offset offset_calculator(.audio_clk(audio_clk),
                                        .rst_in(rst_in),
                                        .audio_trigger(audio_trigger),
                                        .offset_trigger(offset_trigger),
                                        .audio_in(raw_audio_in),
                                        .offset_produced(offset_produced_singlecycle),
                                        .offset(offset_singlecycle));

    always_ff @(posedge audio_clk) begin
        if (rst_in) begin
            offset_produced <= 0;
        end else if (offset_produced_singlecycle) begin
            offset_produced <= 1;
            OFFSET <= offset_singlecycle;
        end 
    end 

    assign dc_blocked_audio_in = offset_produced ? (raw_audio_in - OFFSET) : raw_audio_in;

    // Antialiasing Filter
    logic signed [15:0] anti_alias_audio_in_singlecycle;
    logic filter_valid;
    anti_alias_fir_24k anti_alias_filter(.aclk(audio_clk),
                                        .s_axis_data_tvalid(mic_data_valid),
                                        .s_axis_data_tready(1'b1),
                                        .s_axis_data_tdata(dc_blocked_audio_in),
                                        .m_axis_data_tvalid(filter_valid),
                                        .m_axis_data_tdata(anti_alias_audio_in_singlecycle));

    // 48k to 24k decimation
    logic decimation_counter; 
    always_ff @(posedge audio_clk) begin
        if (rst_in) begin
            decimation_counter <= 0;
        end
        if (filter_valid) begin
            if (decimation_counter == 0) begin
                processed_audio <= anti_alias_audio_in_singlecycle;
            end 
            decimation_counter <= ~(decimation_counter);
        end
    end
endmodule

`timescale 1ns / 1ps
`default_nettype wire


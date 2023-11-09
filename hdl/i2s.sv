module i2s(
    input wire mic_data,
    input wire audio_clk,
    input wire rst_in,

    // Outputs to mic
    output logic i2s_clk,
    output logic lrcl_clk,

    // Deserialized outputs to system
    output logic data_valid_out,
    output logic [15:0] audio_out
);

logic prev_lrcl_clk;
logic prev_i2s_clk;
logic [63:0] build_up_audio;
logic [6:0] total_bits_seen;

// 3.072MHz clock to send to i2s
logic [4:0] i2s_clk_counter;
assign i2s_clk = i2s_clk_counter[4];
    
// 48kHz clock for word select for i2s
logic [10:0] lrcl_counter;
assign lrcl_clk = (lrcl_counter > 31) && (lrcl_counter < 1057);

typedef enum logic {IDLE = 0, ACCUMULATING = 1} i2s_states;
i2s_states current_i2s_state;

always_ff @(posedge audio_clk) begin
    if (rst_in) begin
        lrcl_counter <= 0;
        i2s_clk_counter <= 0;
        build_up_audio <= 0;
        current_i2s_state <= IDLE;
    end else begin
        i2s_clk_counter <= i2s_clk_counter + 1;
        lrcl_counter <= lrcl_counter + 1;
        case(current_i2s_state)
            IDLE: begin
                data_valid_out <= 0;
                build_up_audio <= 0;
                total_bits_seen <= 0;
                audio_out <= 0;
                if (prev_lrcl_clk && ~(lrcl_clk)) begin
                    current_i2s_state <= ACCUMULATING;
                end
            end 
            ACCUMULATING: begin
                if (total_bits_seen == 7'd64) begin
                    total_bits_seen <= 0;
                    data_valid_out <= 1;
                    audio_out <= build_up_audio[63:48];
                end else if (data_valid_out) begin
                    data_valid_out <= 0;
                    audio_out <= 0;
                    build_up_audio <= 0;
                end else if (prev_i2s_clk && ~(i2s_clk)) begin
                    build_up_audio <= {build_up_audio[62:0], mic_data};
                    total_bits_seen <= total_bits_seen + 1;
                end 
            end
        endcase
    end
    prev_i2s_clk <= i2s_clk;
    prev_lrcl_clk <= lrcl_clk; 
end
endmodule

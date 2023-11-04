module i2s(
    input wire mic_data,
    input wire i2s_clk,
    input wire lrcl_clk,
    output logic data_valid,
    output logic [63:0] data_out
);

logic [5:0] current_address;
logic prev_lrcl_clk;
logic [63:0] full_audio;
always_ff @(posedge i2s_clk) begin
    if (~(prev_lrcl_clk) && lrcl_clk) begin
        data_out <= full_audio;
        data_valid <= 1;
        full_audio[63] <= mic_data;
        current_address <= 1;
    end else begin
        current_address <= current_address + 1;
        full_audio[63-current_address] <= mic_data;
    end
    if (data_valid) begin
        data_valid <= 0;
        data_out <= 0;
    end
    prev_lrcl_clk <= lrcl_clk;
end


endmodule
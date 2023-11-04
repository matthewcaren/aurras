module i2s(
    input wire mic_data,
    input wire i2s_clk,
    input wire lrcl_clk,
    output logic data_valid,
    output logic [63:0] full_audio
);

logic [5:0] current_address;
always_ff @(posedge i2s_clk) begin
    
    current_address <= current_address + 1;
end

endmodule
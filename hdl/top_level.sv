module top_level(
    input wire clk_100mhz,
    input wire [15:0] sw,
    
    input wire [7:0] pmoda, // Tbd how many bits actually needed
    input wire [7:0] pmodb, // Tbd how many bits actually needed
    input wire [3:0] btn,

    output logic spkl, spkr, //speaker outputs
    output logic [15:0] led, // led outputs

    output logic uart_txd, // if we want to use Manta
    input wire uart_rxd

)
    assign led = sw;

    logic [1:0] mic_select;

    logic audio_clk;
    assign audio_clk = clk_100mhz;
    logic [4:0] 


    assign mic_select = sw[15:14]
    always_comb begin
        case (mic_select)
            2'b10: // Select mic 1
            2'b11: // Select mic 2
            2'b00: // Select mic 3
            default: 
        endcase
        
    end

endmodule 
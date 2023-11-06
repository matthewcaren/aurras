// `timescale 1ns / 1ps
// `default_nettype none


// module pdm(
//             input wire clk_in,
//             input wire rst_in,
//             input wire signed [23:0] level_in,
//             input wire tick_in,
//             output logic pdm_out
//   );
//   logic signed [25:0] accumulator = 26'sb0; 
//   logic signed [23:0] feedback = 24'sb0; 

//     always_ff @(posedge clk_in) begin
//         if (rst_in) begin
//             pdm_out <= 0;  
//         end
//         else if (tick_in) begin
//           feedback <= (accumulator > 0) ? 24'sb0111_1111_1111_1111_1111_1111 : 24'sb1000_0000_0000_0000_0000_0000;
//           pdm_out <= feedback[23];
          
//           accumulator <= $signed(accumulator) + $signed(level_in) - $signed(feedback);
//         end

//     end

// endmodule


// `default_nettype wire

// `timescale 1ns / 1ps
// `default_nettype none


// module pdm(
//             input wire clk_in,
//             input wire rst_in,
//             input wire signed [7:0] level_in,
//             input wire tick_in,
//             output logic pdm_out
//   );

//   logic signed [16:0] stored_val;
//   logic signed [16:0] thresholded;
//   assign thresholded = stored_val[16] ? -'sd32768 : 'sd32767;
  
//   assign pdm_out = ~thresholded[16];

//   always_ff @(posedge clk_in) begin
//     if (rst_in) begin
//       stored_val <= 0;
//     end else if (tick_in) begin
//       stored_val <= level_in + stored_val - thresholded;
//     end
//   end
// endmodule


// `default_nettype wire


`timescale 1ns / 1ps
`default_nettype none


module pdm(
            input wire clk_in,
            input wire rst_in,
            input wire signed [15:0] level_in,
            input wire tick_in,
            output logic pdm_out
  );
  logic signed [16:0] stored_value;
  logic signed [15:0] feedback;

  assign pdm_out = ~(stored_value[16]);
  assign feedback = stored_value[16] ? -'sd32768 : 'sd32767;
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      stored_value <= 0;
    end else begin
      if (tick_in) begin
        stored_value <= stored_value + level_in - feedback;
      end
    end
  end
endmodule
`default_nettype wire
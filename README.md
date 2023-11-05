# aurras
Active environmental noise cancellation using an FPGA


## Clocking

Main clock: 98.3MhZ from audio_clk_wiz.v
Clock to I2S: Main Clock / 32 ~= 3.072 MhZ
Initial audio rate from I2S = I2S Clock / 64 ~= 48KhZ
Audio_trigger for all other modules ~= 24kHZ and exactly Main clock / 4096


Board clock: 100MhZ, not used in any modules (eventually)
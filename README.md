# aurras

Active environmental noise cancellation using an FPGA.


## specs

16-bit audio @ 24 kHz. Developed for the Xilinx Spartan-7 FPGA with the RealDigital Urbana board.

### clocking

- Main clock: 98.3MhZ
- i2s driver clock (main clock / 32) ≈ 3.072 MhZ
- Input audio rate from I2S (main clock / 2048) ≈ 48KhZ
- Project audio rate (main clock / 4096) ≈ 24kHZ

### memory

- Audio buffers are all 1 second, stored in memory as 750 lines of 64 words with 16 bits per word
- 1s convolution requires ~96k bits required working memory for IR + equal-sized convolution buffer

### peripherals

- 2-channel input via I2S MEMS microphones
- 2-channel output to low-latency amplifier & full-range drivers

## controls

btn0: System reset\
btn1: Calculate DC offset\
btn2: Monitor audio from microphone\
btn3: Environment calibration (record impulse response)

sw0: Channel 0 output enable\
sw1: Channel 1 output enable\
sw2: 440Hz test tone\
sw3: Raw input from mic\
sw4: Processed input from mic (DC-blocked, antialiased, downsampled)\
sw5: Intermediate output\
sw6: Room Adjusted Mode: Delayed and convolved audio output\
sw7: Core Noise Cancellation Mode: Delayed but not convolved audio output\
sw8: Audio delayed by one second\
sw10-sw15: Delay amount (number of 24kHz cycles)

The 7-segment display shows the samples being sent to the speaker in real-time.

# aurras

Active environmental noise cancellation using an FPGA.

<br />

## specs

16-bit audio @ 24 kHz

### clocking

- main clock: 98.3MhZ
- I2S driver clock (main clock / 32) ≈ 3.072 MhZ
- input audio rate from I2S (main clock / 2048) ≈ 48KhZ
- project audio rate (main clock / 4096) ≈ 24kHZ

### memory

- audio buffers are all 1 second, stored in memory as 750 lines of 64 words with 16 bits per word
- 1s convolution requires ~96k bits required working memory for IR + equal-sized convolution buffer

### peripherals

- 3-channel input via I2S MEMS microphones
- 2-channel output to analog amplifier & full-range drivers

## controls

btn0: system reset\
btn1: calculate DC offset\
btn2: sample audio from microphone\
btn3: record impulse\

sw0: channel 0 output enable\
sw1: channel 1 output enable\\

sw2: 440Hz test tone\
sw3: Raw input from mic\
sw4: Processed input from mic (DC-blocked, antialiased, downsampled)\
sw5: Intermediate output\
sw6: Room Adjusted Mode: Delayed and convolved audio output\
sw7: Core Noise Cancellation Mode: Delayed but not convolved audio output\
sw8: Audio delayed by one second\

sw10-15: Delay amount\\

The 7-segment display shows the samples being sent to the speaker in real-time.

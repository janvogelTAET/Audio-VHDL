# ZYBO PS1 Audio Processing

A real-time audio processing system for the **Digilent Zybo Z7-10 (Zynq-7000)** FPGA board. The system processes stereo audio (48 kHz, 16-bit) via the onboard **SSM2603 Audio Codec** and features programmable effects, a sine wave generator, an audio recorder (Block RAM), and interactive control via switches, buttons, and a rotary encoder.

## 🚀 Overview & Features

- **Real-Time Audio Processing:** Line-In/Mic-In to Headphone/Speaker out.
- **FIR Filter Bank:** Switchable between Bypass, Low-pass (LP9), and High-pass (HP9).
- **Integrated Sine Wave Generator:** 4 selectable frequencies for testing purposes.
- **Audio Recorder:** Block RAM-based recorder for up to 1.36 seconds of audio.
- **User Interface:** Control via onboard switches, buttons, rotary encoder, and visual feedback via LEDs and a 7-segment display.

## 🧰 Hardware & System Requirements

- **Board:** Digilent Zybo Z7-10 (Zynq-7000)
- **Audio Codec:** Analog Devices SSM2603 (I2S for audio data, I2C for configuration)
- **Environment:** Xilinx Vivado

## ⚙️ Technical Specifications

| Parameter | Specification |
| :--- | :--- |
| **Sample Rate** | 48 kHz |
| **Bit Depth** | 16-bit Stereo |
| **System Clock** | 100 MHz |
| **Audio Clock** | 12.288 MHz |
| **RAM Storage** | 65536 Samples (1.36s) |
| **FIR Filter** | 9-Tap Transposed |
| **System Latency** | ~3 Samples (62.5 µs) |

## 🎛️ Operation Manual

### Switches (SW0 - SW2)
| SW | Mode / Function |
| :--- | :--- |
| **SW1-SW0** | `00` = Bypass<br>`01` = Low-pass (LP9)<br>`10` = High-pass (HP9)<br>`11` = Bypass |
| **SW2** | `0` = Live Audio Mode<br>`1` = Sine Wave Generator Mode |

### Buttons (BTN0 - BTN2)
| BTN | Function |
| :--- | :--- |
| **BTN1** | Record (Audio recording, max. 1.36s) |
| **BTN2** | Playback (Highest priority in signal flow) |
| **BTN0** | System Reset |

### Rotary Encoder & Displays
- **Rotary Encoder (Turn):** Frequency selection for the sine wave generator:
  - Pos. 0: 440 Hz (A4)
  - Pos. 1: 880 Hz (A5)
  - Pos. 2: 1000 Hz
  - Pos. 3: 2000 Hz
- **7-Segment Display:**
  - *Digit 1 (left):* Current switch status (SW).
  - *Digit 0 (right):* Rotary counter (Frequency position).
- **LEDs:**
  - *LED4:* Init OK (Green = Codec ready).
  - *LED5-7:* Error flags.
  - *LED8-10:* SW status.

## 🔀 Signal Flow & Priorities

The output routing follows a fixed priority list (Highest to Lowest):

1. **Audio RAM (Playback):** Active as long as `BTN2` is pressed.
2. **Sine Wave Generator:** Active when `SW2 = 1`.
3. **Live Audio (Default):** Line-In/Mic-In -> FIR Filter -> Output.

## 🧩 Module Structure (VHDL)

| Module Name | Description |
| :--- | :--- |
| `fir_sel` | FIR filter bank (LP9/HP9) incl. bypass logic |
| `tone_gen` | Sine wave generator (DDS based on 4 frequencies) |
| `audio_ram` | Block RAM recorder |
| `seg7_driver` | 7-segment multiplex driver |
| `enc_decoder` | Rotary quadrature decoder for position tracking |

## 🏁 Quick Start

1. **Hardware Setup:** Turn on the Zybo Z7 and connect an audio source to the `Line-In` port. Connect headphones to `HP Out`.
2. **Load Bitstream:** Open the project in Vivado and flash the generated `zybo_ps1.bit` file to the board using the *Hardware Manager*.
3. **Default Setup:** Set all switches (`SW2-SW0`) to `0` and briefly press `BTN0` to reset the system.
4. **Test:** Wait until `LED4` turns on (indicates that the SSM2603 codec was successfully initialized via I2C).
5. **Start:** Play the audio source. The signal should now be audible at the headphone output and can be filtered using the switches.

---
**Author:** VJA | **Date:** April 2026 | DIDE Audio Processing Reference Design

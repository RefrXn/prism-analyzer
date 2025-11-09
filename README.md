[![License: CERN-OHL-W-2.0](https://img.shields.io/badge/License-CERN--OHL--W--2.0-blue.svg)](LICENSE)
[![FPGA](https://img.shields.io/badge/FPGA-Verilog--2001-green.svg)]()
[![Status](https://img.shields.io/badge/status-active-success.svg)]()

# PrismAnalyzer
FPGA implementation of a **32×8 WS2812B LED matrix spectrum visualizer**, written in **Verilog-2001**, using the **WM8731 audio codec** for input and a Xilinx FFT IP core for spectral analysis.

---

## Overview
PrismAnalyzer captures audio from the WM8731 codec via I²S, performs real-time FFT on the audio stream, and maps the frequency bands to a WS2812 LED matrix.  
The system is designed for real-time operation on FPGA hardware and is divided into three primary functional blocks:

- **Codec Subsystem (`top_codec`)** – Handles audio acquisition and codec configuration via I²S and I²C.  
- **FFT Subsystem (`top_fft`)** – Performs frame packing, FFT, magnitude conversion, and band accumulation.  
- **LED Subsystem (`top_led`)** – Converts spectral magnitudes to LED color patterns and drives WS2812 timing.

---

## Module Hierarchy
```text
top.v
├── top_codec.v
│   ├── i2s.v
│   │   ├── timing_gen.v
│   │   └── rx.v
│   └── i2c.v
│       ├── i2c_reg_cfg.v
│       └── i2c_dri.v
│
├── top_fft.v
│   ├── frame_packer.v
│   ├── fft_wrapper.v
│   │   └── xfft_0.xci   (Xilinx FFT IP)
│   ├── complex_to_mag.v
│   ├── band_accum.v
│   └── band_buffer.v
│
└── top_led.v
    ├── spectrum_to_led.v
    └── ws2812_dri.v
```

---

## Data Flow
```text
Audio In (WM8731 / I²S)
        ↓
     top_codec
        ↓
     top_fft
        ↓
  FFT → Magnitude → Band Accumulation
        ↓
     top_led
        ↓
 Spectrum Mapping → WS2812 Timing
        ↓
 LED Matrix Visualization
```

---

## Notes / Disclaimer

- The **`spectrum_to_led`** module is **not provided** in this repository because WS2812B matrix wiring orders differ across setups.  
  Please implement your own mapping logic. For a two-dimensional matrix in **Verilog-2001**, consider flattening it into a 1-D bus (row- or column-major) and using `generate` blocks or index arithmetic to map `(row, col)` → `flat_index`.

- **Please do not upload this project to CSDN or any other content-reposting sites.**

- The **WM8731 codec driver** section is **based on Alinx teaching examples**.  
  Portions of the **WS2812 driver** code originate from unknown open-source sources.  
  If any copyright infringement is involved, please contact me for removal.

- **Hardware used:**  
  - **FPGA Board:** Alinx ATRIX7035  
  - **Codec Module:** Alinx AN831 (WM8731)  
  - **Microphone:** Primo EM272Z1

## License

**CERN Open Hardware Licence Version 2 - Weakly Reciprocal (CERN-OHL-W-2.0)**  

Copyright © 2025 Refracción  

This source describes Open Hardware and is licensed under the CERN-OHL-W v2.  

You may redistribute and modify this documentation and design files under the terms of the CERN-OHL-W v2.  
A copy of the license is included in this repository in the file `LICENSE`, and may also be obtained at:  
https://ohwr.org/cern_ohl_w_v2.txt  

You are granted the right to:  
- Use, copy, modify, and distribute this design and documentation;  
- Manufacture products using the licensed material;  
- Convey modified or derivative works under the same license terms.  

You must:  
- Retain the copyright notice, license reference, and disclaimers in all copies;  
- Provide access to the modified source when you distribute or sell products based on it;  
- Clearly indicate the modifications you made and the date of modification.  

This license comes **without any warranty**, to the extent permitted by applicable law.  
See the full text of the license for detailed terms and conditions.

---

**SPDX-License-Identifier:** CERN-OHL-W-2.0



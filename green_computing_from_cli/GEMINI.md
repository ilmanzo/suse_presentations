# Green Computing from CLI (Green Computing da RIGA DI COMANDO)

This project is a presentation and research repository focused on measuring energy consumption of software on Linux using command-line tools. It was developed for a talk at a SUSE event (likely VE25).

## Project Overview

The project explores how to measure power usage at the software level without external hardware. It specifically compares the energy efficiency of a Python implementation versus a Rust implementation of a prime number calculation algorithm.

### Key Concepts
- **Intel RAPL (Running Average Power Limit):** Interface to measure CPU energy consumption.
- **CLI Tools:** `powerstat`, `perf`, `scaphandre`.
- **Cloud-Native Energy Monitoring:** Kepler (eBPF-based pod/container power measurement), OpenTelemetry semantic conventions for energy.
- **Sustainable Coding:** Speed vs. Energy consumption.

## Directory Structure

- `reference/`: Main presentation materials.
    - `energy_talk_ve25.md`: Presentation slides (Markdown).
    - `energy_talk_ve25.html` / `.pdf`: Rendered versions of the talk.
    - `src/`: Benchmark source code.
        - `prime.py`: Python script calculating the 1,000,000th prime number.
        - `prime_rs/`: Rust project doing the same calculation.
        - `potenza_media.py`: Helper script to calculate average power from measurements.
    - `img/`, `infographics/`: Visual assets for the presentation.
- `notes.txt`: Research notes on advanced tools like Kepler, Scaphandre, and Green Software Foundation's Carbon Aware SDK.
- `abstract.txt`: The talk's abstract and speaker bio.

## Building and Running

### Python Benchmark
To run the Python version:
```bash
python3 reference/src/prime.py
```

### Rust Benchmark
To build and run the Rust version:
```bash
cd reference/src/prime_rs
cargo build --release
./target/release/prime_rs
```

### Measuring Energy
The talk suggests using tools like `powerstat`:
```bash
# Example powerstat usage (requires root/sudo)
sudo powerstat -d 0 1 10
```
Or using `perf` with RAPL counters:
```bash
# Example perf usage for energy (requires kernel support/permissions)
sudo perf stat -a -e power/energy-pkg/ sleep 1
```

## Development Conventions

- **Benchmarking Logic:** Both Python and Rust implementations use the same logic (checking odd numbers up to the square root) to ensure a fair comparison.
- **Target:** The goal is to calculate the 1,000,000th prime number.
- **Presentation:** The talk uses a "slides-as-markdown" approach, likely rendered with a tool like Marp or Reveal.js.

<div align="center">

```
 ████████╗██████╗ ███████╗██╗  ██╗
    ██╔══╝██╔══██╗██╔════╝╚██╗██╔╝
    ██║   ██████╔╝█████╗   ╚███╔╝ 
    ██║   ██╔══██╗██╔══╝   ██╔██╗ 
    ██║   ██║  ██║███████╗██╔╝ ██╗
    ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
```

**Tree Explorer** — a beautiful, fast directory tree viewer for your terminal

[![Zig](https://img.shields.io/badge/Zig-0.13.0-F7A41D?style=flat-square&logo=zig&logoColor=white)](https://ziglang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Windows%20%7C%20macOS-lightgrey?style=flat-square)](#installation)
[![Author](https://img.shields.io/badge/author-Windneiro-blueviolet?style=flat-square)](https://github.com/Windneiro)
[![Version](https://img.shields.io/badge/version-1.0.2-brightgreen?style=flat-square)](#)

</div>

---

## Features

- **Colorful output** — directories, files, and symlinks each have distinct colors
- **Smart sorting** — alphabetical by default, with `--dirs-first` / `--files-first`
- **Pattern filtering** — show only files matching a glob pattern (e.g. `*.zig`)
- **File sizes** — human-readable sizes (B, K, M, G) with `--size`
- **Hidden files** — toggle visibility with `--all`
- **Depth control** — limit traversal with `--depth N`
- **ASCII fallback** — use `--ascii` for classic tree lines
- **No dependencies** — single binary, zero runtime deps
- **Fast** — written in Zig for native performance
- **Cross-platform** — Linux, Windows, macOS

---

## Preview

```
./my-project
├── src/
│   ├── components/
│   │   ├── Button.zig [2.1K]
│   │   └── Modal.zig  [4.8K]
│   ├── utils/
│   │   └── fmt.zig    [1.2K]
│   └── main.zig       [8.4K]
├── build.zig
└── README.md

2 directories, 6 files (16.5K total)
```

---

## Installation

### Pre-built binaries

Download the latest binary for your platform from [Releases](https://github.com/Windneiro/trex/releases):

| Platform       | File                        |
|----------------|-----------------------------|
| Linux x86_64   | `trex-linux-x86_64`         |
| Linux arm64    | `trex-linux-arm64`          |
| Windows x86_64 | `trex-windows-x86_64.exe`   |
| Windows arm64  | `trex-windows-arm64.exe`    |
| macOS x86_64   | `trex-macos-x86_64`         |
| macOS arm64    | `trex-macos-arm64`          |

**Linux / macOS:**
```bash
chmod +x trex-linux-x86_64
sudo mv trex-linux-x86_64 /usr/local/bin/trex
```

**Windows:** Place `trex-windows-x86_64.exe` somewhere in your `%PATH%` and rename it `trex.exe`.

### Build from source

Requires [Zig 0.13.0](https://ziglang.org/download/).

```bash
git clone https://github.com/Windneiro/trex.git
cd trex
zig build -Doptimize=ReleaseSafe
./zig-out/bin/trex
```

**Cross-compile for all platforms:**

```bash
# Linux / macOS
chmod +x build-all.sh && ./build-all.sh

# Windows
build-all.bat
```

Binaries are placed in `./dist/`.

---

## Usage

```
trex [OPTIONS] [PATH]
```

PATH defaults to the current directory if omitted.

### Options

| Flag              | Short  | Description                        |
|-------------------|--------|------------------------------------|
| `--help`          | `-h`   | Show help message                  |
| `--version`       | `-v`   | Show version                       |
| `--depth N`       | `-d N` | Max traversal depth                |
| `--all`           | `-a`   | Show hidden files and directories  |
| `--dirs-only`     | `-D`   | Show only directories              |
| `--size`          | `-s`   | Show human-readable file sizes     |
| `--pattern GLOB`  |        | Filter files by pattern (e.g. `*.zig`) |
| `--dirs-first`    |        | List directories before files      |
| `--files-first`   |        | List files before directories      |
| `--full-path`     |        | Print absolute path for each entry |
| `--no-color`      |        | Disable ANSI colors                |
| `--unicode`         |        | Use Unicode box-drawing charcters|
| `--count`         |        | Show summary counts only           |

---

## Examples

```bash
# Explore current directory
trex

# Explore a path with max depth 2
trex /home/user/projects -d 2

# Show all files (including hidden) with sizes
trex . -a -s

# Directories only, dirs listed first
trex . -D --dirs-first

# Filter only Zig source files
trex src --pattern *.zig

# Clean output for scripts (no color, ASCII lines)
trex . --no-color --ascii

# Quick count summary
trex /var --count
```

---

## Project Structure

```
trex/
├── src/
│   └── main.zig       main source file
├── build.zig          Zig build configuration
├── build-all.sh       cross-compile script (Linux/macOS)
├── build-all.bat      cross-compile script (Windows)
└── README.md
```

---

## Build Details

The default optimize mode is `ReleaseSafe` (safe optimizations + bounds checking).
For maximum performance:

```bash
zig build -Doptimize=ReleaseFast
```

Cross-compilation uses Zig's built-in support — no external toolchain required.

---

## License

MIT — see [LICENSE](LICENSE)

---

<div align="center">

Made with Zig by **Windneiro**

</div>

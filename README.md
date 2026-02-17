# SSD Speed Test

A minimal, modern SSD speed testing utility for macOS and Windows. 

Designed with a focus on simplicity and accuracy, this tool measures read and write speeds of internal and external drives using raw hardware access to bypass system caches.

## Features

- **Cross-Platform**: Native versions for macOS (Swift/SwiftUI) and Windows (C#/WPF).
- **Accurate Results**: Uses low-level system calls (F_NOCACHE / NoBuffering) to bypass RAM caching and measure true disk speed.
- **Minimal UI**: Clean, list-based interface with per-disk controls.
- **Reliability**: Uses large 2GB test files and ensures cleanup after testing.
- **Safety**: Automatically falls back to user directories if root write access is denied.

---

## Download & Run

You can download the latest pre-compiled binaries from the [Releases](https://github.com/tiadiff/diskspeed-test/releases) page.

### macOS
1. Download `SSDSpeedTest.app.zip`.
2. Unzip and move `SSDSpeedTest.app` to your Applications folder.
3. Open the app. 
   *(Note: You may need to right-click and select "Open" the first time if it's not signed with an Apple Developer ID).*

### Windows
1. Download `SSDSpeedTestWin.exe`.
2. Run the executable directly. No installation required.

---

## Build from Source

### Prerequisites

- **macOS**: Xcode (or Command Line Tools) with Swift 5.0+ installed.
- **Windows**: .NET 8.0 SDK (or later) if building on Windows. If cross-compiling from macOS, ensure the .NET SDK is installed.

### macOS (Swift)

1. Clone the repository:
   ```bash
   git clone https://github.com/tiadiff/diskspeed-test.git
   cd diskspeed-test
   ```

2. Build the app using the provided script:
   ```bash
   ./build_app.sh
   ```

3. The compiled application will be located at:
   ```
   .build_app/SSDSpeedTest.app
   ```

### Windows (C#)

**Building on Windows:**
1. Navigate to the Windows project directory:
   ```bash
   cd windows/SSDSpeedTestWin
   ```
2. Build and run:
   ```bash
   dotnet run
   ```
3. Publish standalone .exe:
   ```bash
   dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o publish
   ```

**Cross-compiling from macOS:**
1. Ensure .NET SDK is installed (`dotnet --version`).
2. Run the build script:
   ```bash
   ./build_windows.sh
   ```
3. The standalone executable will be in the `publish_windows` directory.

---

## License

This project is open-source. Feel free to modify and distribute.

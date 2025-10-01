# FyreFetch

A system information fetcher for Linux that displays system details alongside ASCII art of your distribution logo.

## Features

- **System Information**: Displays distro, kernel, CPU, GPU, RAM, and storage information
- **Hardware Detection**: Automatically detects CPU and GPU details with proper formatting
- **RAM Details**: Shows RAM type and speed when available (requires root permissions)
- **Package Manager Detection**: Lists installed package managers based on your distribution
- **Display Manager Detection**: Shows your greeter/compositor information
- **ASCII Art**: Displays your distribution logo as ASCII art
- **Clean Output**: Filters out excessive whitespace for better readability

## Required Packages

### Core Dependencies

- **ascii-image-converter**: For converting distribution logos to ASCII art
  ```bash
  # Arch Linux
  yay -S ascii-image-converter-git
  
  # Ubuntu/Debian
  sudo apt install ascii-image-converter
  
  # Fedora
  sudo dnf install ascii-image-converter
  ```

### Optional Dependencies (for enhanced features)

- **dmidecode**: For detailed RAM type and speed information
  ```bash
  # Arch Linux
  sudo pacman -S dmidecode
  
  # Ubuntu/Debian
  sudo apt install dmidecode
  
  # Fedora
  sudo dnf install dmidecode
  ```

- **lshw**: For hardware information (alternative to dmidecode)
  ```bash
  # Arch Linux
  sudo pacman -S lshw
  
  # Ubuntu/Debian
  sudo apt install lshw
  
  # Fedora
  sudo dnf install lshw
  ```

- **jq**: For JSON parsing (if using lshw)
  ```bash
  # Arch Linux
  sudo pacman -S jq
  
  # Ubuntu/Debian
  sudo apt install jq
  
  # Fedora
  sudo dnf install jq
  ```

## Installation

1. Clone or download this repository
2. Make the script executable:
   ```bash
   chmod +x main.sh
   ```
3. Install the required packages (see above)
4. Run the script:
   ```bash
   ./main.sh
   ```

## Usage

### Basic Usage
```bash
./main.sh
```

### With Root Permissions (for detailed RAM info)
```bash
sudo ./main.sh
```

## Configuration

### Custom Distribution Icons

Place your custom distribution icon at:
```
/etc/xdg/fetch/os-icon.png
```

The script will automatically use this icon if available, otherwise it will fall back to the built-in icons in the `assets/icons/` directory.

### Supported Distributions

The script includes built-in icons for:
- Arch Linux
- Ubuntu
- Fedora
- Debian
- Linux Mint
- openSUSE
- CentOS
- Unknown (fallback)

## Troubleshooting

### ASCII Art Not Displaying

If the ASCII art isn't showing up, try:
1. Install `ascii-image-converter` if not already installed
2. Check that the image file exists and is readable
3. The script will fall back to a text logo if ASCII conversion fails

### RAM Type/Speed Not Showing

For detailed RAM information, you need:
1. Root permissions (`sudo ./main.sh`)
2. `dmidecode` package installed
3. Proper permissions to read `/dev/mem`

### Permission Issues

Some features require root permissions:
- Detailed RAM information (dmidecode)
- Some hardware detection features

## File Structure

```
FyreFetch/
├── main.sh                 # Main script
├── lib/
│   └── os-icon-fallback.sh # Icon fallback logic
├── assets/
│   └── icons/              # Distribution icons
│       ├── arch.png
│       ├── ubuntu.png
│       ├── fedora.png
│       └── ...
├── debug_ram.sh           # RAM detection debug script
└── README.md              # This file
```

## Contributing

Feel free to submit issues, feature requests, or pull requests to improve FyreFetch!

## License

This project is open source. Feel free to use and modify as needed.

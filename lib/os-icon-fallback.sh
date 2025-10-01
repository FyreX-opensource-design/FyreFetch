#! /bin/bash

# Get the directory where the main script is located (parent of this script's directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

distro_id=$(grep -oP 'ID=\K[^"]+' /etc/os-release | head -n1)

if [ "$distro_id" == "arch" ]; then
    export HOST_ICON="$SCRIPT_DIR/assets/icons/arch.png"
elif [ "$distro_id" == "ubuntu" ]; then
    export HOST_ICON="$SCRIPT_DIR/assets/icons/ubuntu.png"
elif [ "$distro_id" == "fedora" ]; then
    export HOST_ICON="$SCRIPT_DIR/assets/icons/fedora.png"
elif [ "$distro_id" == "debian" ]; then
    export HOST_ICON="$SCRIPT_DIR/assets/icons/debian.png"
elif [ "$distro_id" == "linuxmint" ]; then
    export HOST_ICON="$SCRIPT_DIR/assets/icons/linuxmint.png"
elif [ "$distro_id" == "opensuse" ]; then
    export HOST_ICON="$SCRIPT_DIR/assets/icons/opensuse.png"
elif [ "$distro_id" == "centos" ]; then
    export HOST_ICON="$SCRIPT_DIR/assets/icons/centos.png"
else
    export HOST_ICON="$SCRIPT_DIR/assets/icons/unknown.png"
fi
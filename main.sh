#! /bin/bash

get_host_distro() {
    if [ -f /etc/xdg/fyrefetch/os-icon.png ] && [ -s /etc/xdg/fyrefetch/os-icon.png ]; then
        export HOST_ICON=/etc/xdg/fetch/os-icon.png
    else
        # Get the directory where this script is located
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        source "$SCRIPT_DIR/lib/os-icon-fallback.sh"
    fi
    
    # Also get the distro name
    export HOST_DISTRO=$(grep -oP 'ID=\K[^"]+' /etc/os-release | head -n1)
}

get_kernel_version() {
    export KERNEL_VERSION=$(uname -r)
}

get_hardware_info() {
    # Get CPU info using /proc/cpuinfo and truncate AMD names at " w/"
    CPU_RAW=$(grep "model name" /proc/cpuinfo | head -n1 | cut -d: -f2 | xargs)
    if [[ "$CPU_RAW" == *" w/"* ]]; then
        export CPU_INFO=$(echo "$CPU_RAW" | sed 's/ w\/.*//')
    else
        export CPU_INFO="$CPU_RAW"
    fi
    
    # Get GPU info - check for dedicated GPU first, then iGPU
    if command -v lspci >/dev/null 2>&1; then
        # Check for dedicated GPU (NVIDIA/AMD/Intel Arc)
        DEDICATED_GPU=$(lspci | grep -i "vga\|3d\|display" | grep -v "integrated\|onboard\|uhd\|iris" | head -n1 | cut -d: -f3- | xargs)
        if [ -n "$DEDICATED_GPU" ]; then
            # Clean up GPU names
            export GPU_INFO=$(echo "$DEDICATED_GPU" | sed 's/Advanced Micro Devices, Inc. \[AMD\/ATI\]/AMD/g' | sed 's/AMD Corporation/AMD/g' | sed 's/Intel Corporation/Intel/g')
        else
            # Check for integrated GPU
            INTEGRATED_GPU=$(lspci | grep -i "vga\|3d\|display" | head -n1 | cut -d: -f3- | xargs)
            if [ -n "$INTEGRATED_GPU" ]; then
                # Clean up GPU names and mark as integrated if it's UHD/Iris
                if echo "$INTEGRATED_GPU" | grep -qi "uhd\|iris"; then
                    export GPU_INFO="Intel $(echo "$INTEGRATED_GPU" | sed 's/Intel Corporation/Intel/g' | sed 's/.*Intel //' | sed 's/ .*//') (integrated)"
                else
                    export GPU_INFO=$(echo "$INTEGRATED_GPU" | sed 's/Advanced Micro Devices, Inc. \[AMD\/ATI\]/AMD/g' | sed 's/AMD Corporation/AMD/g' | sed 's/Intel Corporation/Intel/g')
                fi
            else
                export GPU_INFO="Unknown"
            fi
        fi
    else
        # Fallback: try to detect from /proc/cpuinfo
        if grep -q "AMD" /proc/cpuinfo; then
            export GPU_INFO="AMD iGPU (integrated)"
        elif grep -q "Intel" /proc/cpuinfo; then
            export GPU_INFO="Intel iGPU (integrated)"
        else
            export GPU_INFO="Unknown"
        fi
    fi
    
    # Get RAM info using /proc/meminfo and try to get speed/type
    RAM_TOTAL=$(free -h | awk 'NR==2{gsub(/Gi/, "GB", $2); printf "%s total", $2}')
    
    # Try to get RAM speed and type
    RAM_SPEED=""
    RAM_TYPE=""
    
    # Method 1: Try dmidecode (most reliable, requires root or specific permissions)
    if command -v dmidecode >/dev/null 2>&1 && [ -r /dev/mem ]; then
        # Get all memory entries and find the first one with actual data
        MEMORY_INFO=$(dmidecode -t memory 2>/dev/null)
        if [ -n "$MEMORY_INFO" ]; then
            # Look for speed in various formats (MHz, MT/s, etc.)
            RAM_SPEED=$(echo "$MEMORY_INFO" | grep -i "speed:" | grep -v "Unknown" | grep -oE '[0-9]+' | head -n1)
            # Look for DDR type
            RAM_TYPE=$(echo "$MEMORY_INFO" | grep -i "type:" | grep -v "Unknown" | grep -oE 'DDR[0-9]' | head -n1)
        fi
    fi
    
    # Method 2: Try lshw (may work without root for basic info)
    if [ -z "$RAM_TYPE" ] && command -v lshw >/dev/null 2>&1; then
        LSHW_OUTPUT=$(lshw -class memory 2>/dev/null)
        if [ -n "$LSHW_OUTPUT" ]; then
            RAM_TYPE=$(echo "$LSHW_OUTPUT" | grep -i "description.*ddr" | head -n1 | grep -oE 'DDR[0-9]' | head -n1)
            # Also try to get speed from lshw
            if [ -z "$RAM_SPEED" ]; then
                RAM_SPEED=$(echo "$LSHW_OUTPUT" | grep -i "clock.*[0-9]" | head -n1 | grep -oE '[0-9]+' | head -n1)
            fi
        fi
    fi
    
    # Method 3: Try /sys/class/dmi/id/mem_* files (no root required)
    if [ -z "$RAM_TYPE" ] && [ -d /sys/class/dmi/id ]; then
        for mem_file in /sys/class/dmi/id/mem_*; do
            if [ -f "$mem_file" ]; then
                if grep -q "DDR" "$mem_file" 2>/dev/null; then
                    RAM_TYPE=$(grep -oE 'DDR[0-9]' "$mem_file" | head -n1)
                    break
                fi
            fi
        done
    fi
    
    # Format RAM info
    if [ -n "$RAM_SPEED" ] && [ -n "$RAM_TYPE" ]; then
        export RAM_INFO="$RAM_TOTAL ($RAM_TYPE-$RAM_SPEED)"
    elif [ -n "$RAM_TYPE" ]; then
        export RAM_INFO="$RAM_TOTAL ($RAM_TYPE)"
    else
        export RAM_INFO="$RAM_TOTAL"
    fi
    
    # Debug output (uncomment to debug RAM detection)
    # echo "DEBUG: RAM_SPEED='$RAM_SPEED', RAM_TYPE='$RAM_TYPE'" >&2
}

get_greeter_info() {
    # Try to detect the display manager (greeter) in use
    if [ -f /etc/X11/default-display-manager ]; then
        GREETER_PATH=$(cat /etc/X11/default-display-manager)
        GREETER_NAME=$(basename "$GREETER_PATH")
        export GREETER_INFO="$GREETER_NAME"
    else
        # Fallback: try to detect running greeter process
        if pgrep -x lightdm >/dev/null; then
            export GREETER_INFO="lightdm"
        elif pgrep -x sddm >/dev/null; then
            export GREETER_INFO="sddm"
        elif pgrep -x gdm3 >/dev/null; then
            export GREETER_INFO="gdm3"
        elif pgrep -x gdm >/dev/null; then
            export GREETER_INFO="gdm"
        elif pgrep -x lxdm >/dev/null; then
            export GREETER_INFO="lxdm"
        elif pgrep -x kdm >/dev/null; then
            export GREETER_INFO="kdm"
        else
            export GREETER_INFO="Unknown"
        fi
    fi
}

get_compositor_info() {
    local compositor
    if [ -z "$compositor" ]; then
        if [ -n "$XDG_CURRENT_DESKTOP" ]; then
            compositor="$XDG_CURRENT_DESKTOP"
        elif [ -n "$DESKTOP_SESSION" ]; then
            compositor="$DESKTOP_SESSION"
        else
            compositor="Unknown"
        fi
    fi

    export COMPOSITOR_INFO="$compositor"
}

print_system_info() {
    echo "Distro: $HOST_DISTRO"
    echo "Kernel: $KERNEL_VERSION"
    echo "CPU: $CPU_INFO"
    echo "GPU: $GPU_INFO"
    echo "RAM: $RAM_INFO"
    echo "Storage: $TOTAL_STORAGE"
    echo "Used: $USED_STORAGE"
    echo "Free: $FREE_STORAGE"
    echo "Greeter: $GREETER_INFO"
    echo "Compositor: $COMPOSITOR_INFO"
    echo "Package Managers: $PACKAGE_MANAGER"
}

get_total_storage() {
    # Get root filesystem storage info
    export TOTAL_STORAGE=$(df -h / | awk 'NR==2 {print $2}')
    export USED_STORAGE=$(df -h / | awk 'NR==2 {print $3}')
    export FREE_STORAGE=$(df -h / | awk 'NR==2 {print $4}')
}

get_package_managers() {
    # Define package managers by distro
    local pacman_managers=("pacman" "yay" "paru" "trizen")
    local debian_managers=("apt" "nala")
    local fedora_managers=("dnf" "yum")
    local suse_managers=("zypper")
    local gentoo_managers=("emerge")
    local void_managers=("xbps-install")
    local alpine_managers=("apk")
    local nix_managers=("nix")

    # Detect distro
    local distro_id
    if [ -f /etc/os-release ]; then
        distro_id=$(grep -oP 'ID=\K[^"]+' /etc/os-release | head -n1)
    fi

    # Build ordered list of managers to check
    local ordered_managers=()
    case "$distro_id" in
        arch|manjaro|endeavouros)
            ordered_managers+=("${pacman_managers[@]}")
            ;;
        ubuntu|debian|linuxmint|pop|elementary)
            ordered_managers+=("${debian_managers[@]}")
            ;;
        fedora|centos|rhel)
            ordered_managers+=("${fedora_managers[@]}")
            ;;
        opensuse|suse)
            ordered_managers+=("${suse_managers[@]}")
            ;;
        gentoo)
            ordered_managers+=("${gentoo_managers[@]}")
            ;;
        void)
            ordered_managers+=("${void_managers[@]}")
            ;;
        alpine)
            ordered_managers+=("${alpine_managers[@]}")
            ;;
    esac

    # Add nix if present
    if command -v nix >/dev/null 2>&1; then
        ordered_managers+=("nix")
    fi

    # Add all other managers not already in the list
    local all_managers=("pacman" "yay" "paru" "trizen" "apt" "nala" "dnf" "yum" "zypper" "emerge" "xbps-install" "apk" "nix")
    for mgr in "${all_managers[@]}"; do
        if [[ ! " ${ordered_managers[*]} " =~ " $mgr " ]]; then
            ordered_managers+=("$mgr")
        fi
    done

    # Find installed managers, preserving order
    local found=()
    for mgr in "${ordered_managers[@]}"; do
        if command -v "$mgr" >/dev/null 2>&1; then
            found+=("$mgr")
        fi
    done

    # Remove duplicates
    local unique_found=()
    for mgr in "${found[@]}"; do
        if [[ ! " ${unique_found[*]} " =~ " $mgr " ]]; then
            unique_found+=("$mgr")
        fi
    done

    local count=${#unique_found[@]}
    if (( count == 0 )); then
        export PACKAGE_MANAGER="Immutable"
    elif (( count == 1 )); then
        export PACKAGE_MANAGER="${unique_found[0]}"
    elif (( count == 2 )); then
        export PACKAGE_MANAGER="${unique_found[0]}, ${unique_found[1]}"
    elif (( count == 3 )); then
        export PACKAGE_MANAGER="${unique_found[0]}, ${unique_found[1]}, ${unique_found[2]}"
    else
        export PACKAGE_MANAGER="${unique_found[0]}, ${unique_found[1]}, ${unique_found[2]}, and $((count-3)) other"
    fi
}

main() {
    get_host_distro
    get_kernel_version
    get_hardware_info
    get_total_storage
    get_greeter_info
    get_compositor_info
    get_package_managers
    paste <(ascii-image-converter $HOST_ICON -C) <(echo -e "$(print_system_info)")
}

# main() {
#     get_host_distro
#     paste <(echo -e "test") <(echo -e "$(print_system_info)")
# }

main
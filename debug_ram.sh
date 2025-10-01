#!/bin/bash

echo "=== RAM Detection Debug Script ==="
echo

# Test dmidecode
echo "1. Testing dmidecode:"
if command -v dmidecode >/dev/null 2>&1; then
    echo "dmidecode is available"
    if [ -r /dev/mem ]; then
        echo "/dev/mem is readable"
        echo "dmidecode -t memory output:"
        dmidecode -t memory | head -20
        echo
        echo "Speed entries:"
        dmidecode -t memory | grep -i "speed:"
        echo
        echo "Type entries:"
        dmidecode -t memory | grep -i "type:"
        echo
        echo "Parsed speed:"
        dmidecode -t memory | grep -i "speed:" | grep -v "Unknown" | grep -oE '[0-9]+' | head -n1
        echo
        echo "Parsed type:"
        dmidecode -t memory | grep -i "type:" | grep -v "Unknown" | grep -oE 'DDR[0-9]' | head -n1
    else
        echo "/dev/mem is not readable (need root)"
    fi
else
    echo "dmidecode is not available"
fi

echo
echo "2. Testing lshw:"
if command -v lshw >/dev/null 2>&1; then
    echo "lshw is available"
    echo "lshw -class memory output:"
    lshw -class memory | head -20
    echo
    echo "Memory descriptions:"
    lshw -class memory | grep -i "description"
    echo
    echo "Clock info:"
    lshw -class memory | grep -i "clock"
else
    echo "lshw is not available"
fi

echo
echo "3. Testing /proc/cpuinfo:"
grep -i "ddr\|memory" /proc/cpuinfo | head -5

echo
echo "4. Testing /sys/class/dmi/id:"
ls -la /sys/class/dmi/id/ | grep -i mem

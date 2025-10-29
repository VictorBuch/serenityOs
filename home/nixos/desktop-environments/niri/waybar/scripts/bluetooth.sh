#!/usr/bin/env bash
# Interactive Bluetooth manager for Waybar

# Colors for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}         Bluetooth Manager${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Check Bluetooth status
if bluetoothctl show | grep -q "Powered: yes"; then
    echo -e "${GREEN}✓${NC} Bluetooth is ${GREEN}ON${NC}"
else
    echo -e "${RED}✗${NC} Bluetooth is ${RED}OFF${NC}"
    echo
    read -p "Turn on Bluetooth? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        bluetoothctl power on
        sleep 1
    else
        exit 0
    fi
fi

echo

while true; do
    echo -e "${YELLOW}Available options:${NC}"
    echo "  1) Scan for devices"
    echo "  2) List paired devices"
    echo "  3) Connect to device"
    echo "  4) Disconnect device"
    echo "  5) Remove device"
    echo "  6) Power off Bluetooth"
    echo "  q) Quit"
    echo
    read -p "Select option: " -n 1 -r option
    echo
    echo

    case "$option" in
        1)
            echo -e "${BLUE}Scanning for devices (10 seconds)...${NC}"
            bluetoothctl scan on &
            SCAN_PID=$!
            sleep 10
            kill $SCAN_PID 2>/dev/null
            echo
            bluetoothctl devices
            echo
            ;;
        2)
            echo -e "${BLUE}Paired devices:${NC}"
            bluetoothctl paired-devices
            echo
            ;;
        3)
            echo -e "${BLUE}Available devices:${NC}"
            bluetoothctl devices
            echo
            read -p "Enter device MAC address: " mac
            if [ -n "$mac" ]; then
                echo "Connecting to $mac..."
                bluetoothctl connect "$mac"
                echo
            fi
            ;;
        4)
            echo -e "${BLUE}Connected devices:${NC}"
            bluetoothctl devices Connected
            echo
            read -p "Enter device MAC address: " mac
            if [ -n "$mac" ]; then
                echo "Disconnecting $mac..."
                bluetoothctl disconnect "$mac"
                echo
            fi
            ;;
        5)
            echo -e "${BLUE}Paired devices:${NC}"
            bluetoothctl paired-devices
            echo
            read -p "Enter device MAC address to remove: " mac
            if [ -n "$mac" ]; then
                echo "Removing $mac..."
                bluetoothctl remove "$mac"
                echo
            fi
            ;;
        6)
            bluetoothctl power off
            echo -e "${YELLOW}Bluetooth powered off${NC}"
            sleep 1
            exit 0
            ;;
        q|Q)
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            echo
            ;;
    esac
done

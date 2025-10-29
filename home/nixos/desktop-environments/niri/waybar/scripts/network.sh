#!/usr/bin/env bash
# Interactive Network Manager for Waybar

# Colors for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}         Network Manager${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Check current connection status
if nmcli networking connectivity | grep -q "full"; then
    CONN_STATUS="${GREEN}Connected${NC}"
else
    CONN_STATUS="${YELLOW}Limited/No connection${NC}"
fi

# Get current WiFi status
if nmcli radio wifi | grep -q "enabled"; then
    WIFI_STATUS="${GREEN}ON${NC}"
else
    WIFI_STATUS="${RED}OFF${NC}"
fi

echo -e "Status: $CONN_STATUS"
echo -e "WiFi: $WIFI_STATUS"
echo

# Show current connection
CURRENT=$(nmcli -t -f NAME connection show --active | head -n1)
if [ -n "$CURRENT" ]; then
    echo -e "${GREEN}✓${NC} Active: ${GREEN}$CURRENT${NC}"
    echo
fi

while true; do
    echo -e "${YELLOW}Available options:${NC}"
    echo "  1) List WiFi networks"
    echo "  2) Connect to WiFi"
    echo "  3) Disconnect"
    echo "  4) Show connection details"
    echo "  5) Toggle WiFi on/off"
    echo "  6) Show saved connections"
    echo "  7) Forget network"
    echo "  q) Quit"
    echo
    read -p "Select option: " -n 1 -r option
    echo
    echo

    case "$option" in
        1)
            echo -e "${BLUE}Scanning WiFi networks...${NC}"
            nmcli device wifi rescan 2>/dev/null
            sleep 2
            nmcli -f SSID,SECURITY,SIGNAL,BARS device wifi list
            echo
            ;;
        2)
            echo -e "${BLUE}Available networks:${NC}"
            nmcli -f SSID,SECURITY,SIGNAL device wifi list
            echo
            read -p "Enter SSID: " ssid
            if [ -n "$ssid" ]; then
                read -sp "Enter password (leave empty for open network): " password
                echo
                if [ -n "$password" ]; then
                    nmcli device wifi connect "$ssid" password "$password"
                else
                    nmcli device wifi connect "$ssid"
                fi
                echo
            fi
            ;;
        3)
            if [ -n "$CURRENT" ]; then
                echo "Disconnecting from $CURRENT..."
                nmcli connection down "$CURRENT"
                echo
            else
                echo -e "${RED}No active connection${NC}"
                echo
            fi
            ;;
        4)
            if [ -n "$CURRENT" ]; then
                echo -e "${BLUE}Connection details for: $CURRENT${NC}"
                nmcli connection show "$CURRENT" | grep -E "(IP4|GATEWAY|DNS)"
                echo
            else
                echo -e "${RED}No active connection${NC}"
                echo
            fi
            ;;
        5)
            if nmcli radio wifi | grep -q "enabled"; then
                nmcli radio wifi off
                echo -e "${YELLOW}WiFi turned OFF${NC}"
            else
                nmcli radio wifi on
                echo -e "${GREEN}WiFi turned ON${NC}"
            fi
            echo
            ;;
        6)
            echo -e "${BLUE}Saved connections:${NC}"
            nmcli connection show
            echo
            ;;
        7)
            echo -e "${BLUE}Saved connections:${NC}"
            nmcli connection show
            echo
            read -p "Enter connection name to forget: " conn_name
            if [ -n "$conn_name" ]; then
                nmcli connection delete "$conn_name"
                echo -e "${GREEN}Connection removed${NC}"
                echo
            fi
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

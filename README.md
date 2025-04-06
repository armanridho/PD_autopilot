<p align="center">
  <img src="https://img.shields.io/github/stars/armanridho/PD_autopilot?style=social" alt="stars">
  <img src="https://img.shields.io/github/license/armanridho/PD_autopilot" alt="license">
  <img src="https://img.shields.io/badge/bash-automation-blue" alt="bash">
</p>

<h1 align="center">🔎 PD_Autopilot - Recon & Scan Toolkit</h1>

<p align="center">
  <b>Automated security scanning and recon script powered by ProjectDiscovery + RustScan + Nmap</b><br>
  🔥 Fast. 🧠 Smart. 💥 Deadly.
</p>

---

## 🎬 Demo

<p align="center">
  <img src="https://raw.githubusercontent.com/armanridho/PD_autopilot/refs/heads/main/pd_autopilot.gif" alt="demo" width="700"/>
</p>

---

## 📌 Overview

This Bash script automates reconnaissance for a target domain:  
From subdomain enumeration ➡ active host discovery ➡ port scanning ➡ technology detection ➡ vulnerability scanning ➡ endpoint discovery.

Integrates multiple tools for a seamless recon-to-scan pipeline.

---

## ⚡ Features

- 🔍 Subdomain Enumeration (`subfinder`)
- 🌐 Active Host Checking (`httpx`)
- 🚪 Port Scanning (`rustscan` + `nmap`)
- 🧠 Tech Detection (`httpx --tech-detect`)
- 🚨 Vulnerability Scanning (`nuclei`)
- 🕸️ Endpoint & JS Parameter Discovery (`katana`)
- 🛎️ Optional Notifications (`notify`)

---

## 📦 Installation & Requirements

✅ Make sure these tools are installed from their official repos:

| Tool         | Description                       | Link |
|--------------|-----------------------------------|------|
| Subfinder    | Fast passive subdomain finder     | [🔗](https://github.com/projectdiscovery/subfinder) |
| Httpx        | Active probe & tech detect        | [🔗](https://github.com/projectdiscovery/httpx) |
| RustScan     | Fast port scanner                 | [🔗](https://github.com/RustScan/RustScan) |
| Nmap         | Deep scan engine after RustScan   | [🔗](https://nmap.org/) |
| Nuclei       | Template-based vuln scanner       | [🔗](https://github.com/projectdiscovery/nuclei) |
| Katana       | Endpoint/parameter spider         | [🔗](https://github.com/projectdiscovery/katana) |
| Notify (opt) | Notification system for alerting  | [🔗](https://github.com/projectdiscovery/notify) |

📖 Auto install script available in [INSTALL.md](https://github.com/armanridho/PD_autopilot/blob/main/INSTALL.md)

---

## 🚀 Usage

1. Clone the repo:
```bash
git clone https://github.com/armanridho/PD_autopilot.git
cd PD_autopilot
```

2. Edit the target domain inside auto_scanning.sh:

```bash
DOMAIN="targetdomain.com"
```

3. Run the script:
```bash
chmod +x auto_scanning.sh
./auto_scanning.sh
```

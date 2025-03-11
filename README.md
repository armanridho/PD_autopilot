## 🔎 Automated Security Scanning Script

## 📌 Overview

This script automates the process of enumerating subdomains, checking active hosts, scanning for open ports, detecting technologies, finding vulnerabilities, and discovering hidden parameters or endpoints. It integrates various security tools such as Subfinder, Httpx, Naabu, Nuclei, and Katana.

## ⚡ Features

- Subdomain Enumeration (Subfinder)
- Active Host Checking (Httpx)
- Port Scanning (Naabu)
- Technology Detection (Httpx tech-detect)
- Vulnerability Scanning (Nuclei)
- Endpoint & Parameter Discovery (Katana)
- Notification Support (Notify, optional)

## 🛠️ Installation & Requirements

Ensure you install them from official ProjectDiscovery repo:

- [Subfinder](https://github.com/projectdiscovery/subfinder)
- [Httpx](https://github.com/projectdiscovery/httpx)
- [Naabu](https://github.com/projectdiscovery/naabu)
- [Nuclei](https://github.com/projectdiscovery/nuclei)
- [Katana](https://github.com/projectdiscovery/katana)
- [Notify](https://github.com/projectdiscovery/notify) (optional)

OR

Read this for automatic installation [INSTALL.md](https://github.com/armanridho/PD_autopilot/blob/main/INSTALL.md)

## 🚀 Usage

Copy / Download / Clone this repo

Run the script with:
```
chmod +x auto_scanning.sh
./auto_scanning.sh
```

## 📂 Output Files

Results will be saved in the scan_results directory:

- subdomains.txt - Enumerated subdomains

- live_subdomains.txt - Active subdomains

- ports.txt - Open ports

- httpx_tech.txt - Technology detection results

- nuclei_results.txt - Vulnerability scan results

- katana_results.txt - Discovered endpoints

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Pull requests are welcome! If you find any issues or improvements, feel free to open an issue or contribute directly.

## ⚠️ Disclaimer

This script is intended for educational and security research purposes only. Unauthorized use against targets without explicit permission is illegal.

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

# Automated Reconnaissance Tool

A powerful bash script for automated reconnaissance and vulnerability scanning of web targets. This tool integrates multiple security tools to perform comprehensive security assessments.

## Features

- **Subdomain Enumeration**: Discover subdomains using multiple techniques
- **Active Host Verification**: Identify live hosts and web services
- **Port Scanning**: Comprehensive port scanning with service detection
- **Vulnerability Scanning**: Automated vulnerability detection using Nuclei
- **Content Discovery**: Find hidden directories and files
- **Reporting**: Generate detailed Markdown reports
- **Modular Design**: Easy to extend with additional functionality

## Prerequisites

Before using this tool, ensure you have the following installed:

- Bash (v4.0 or higher)
- The following security tools:
  - subfinder
  - httpx
  - rustscan
  - nmap
  - nuclei
  - katana
  - dnsx
  - naabu
  - mapcidr
  - shuffledns
  - asnmap
  - cdncheck
  - notify
  - xmlstarlet
  - gobuster
  - jq (for JSON processing)
- Seclists (for wordlists)
- Nuclei templates (for vulnerability scanning)

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/armanridho/PD_autopilot.git
   cd PD_autopilot
   ```

2. Make the script executable:
   ```bash
   chmod +x auto_scanning.sh
   ```

3. Install all required tools. On Kali Linux or similar:
 - [How To Install All Project Discovery Tools](https://github.com/projectdiscovery/pdtm)
 - [How To Install Rustscan](https://github.com/bee-san/RustScan/wiki/Installation-Guide)

 And this tools :
   ```bash
sudo apt install -y nmap xmlstarlet gobuster jq
   ```

## Usage

Run the script with:
```bash
./auto_scanning.sh
```

The script will interactively prompt you for:
- Target domain or IP
- Wordlist directories
- Thread count
- Timeout values
- Scan rate
- Port range

All results will be saved in a timestamped directory under `scan_results_<target>_<timestamp>`.

## Workflow

The tool performs the following steps in sequence:

1. **Initial Information Gathering**:
   - ASN information
   - CDN detection
   - DNS records
   - TLS certificate information

2. **Subdomain Enumeration**:
   - Uses subfinder and shuffledns
   - Combines results from multiple sources

3. **Active Host Verification**:
   - Checks which subdomains are active using httpx

4. **IP Resolution**:
   - Resolves hostnames to IPs
   - Maps network ranges

5. **Port Scanning**:
   - Uses naabu for initial scanning
   - Follows up with rustscan and nmap for detailed service detection

6. **Service Enumeration**:
   - Extracts service information from nmap results
   - Gathers web service details

7. **Vulnerability Scanning**:
   - Runs Nuclei with various template categories
   - Identifies critical, high, medium, and low severity vulnerabilities

8. **Content Discovery**:
   - Uses katana for crawling
   - Performs directory brute-forcing with feroxbuster

9. **Report Generation**:
   - Creates a comprehensive Markdown report
   - Includes summary statistics and critical findings

## Configuration

You can modify the default values in the script's configuration section:

```bash
# Default values
DEFAULT_WORDLIST_DIR="/usr/share/wordlists"
DEFAULT_SECLISTS_DIR="/usr/share/wordlists/seclists"
DEFAULT_THREADS=30
DEFAULT_TIMEOUT=10
DEFAULT_SCAN_RATE="10000"
DEFAULT_PORT_RANGE="1-65535"
```

## Output Structure

The tool creates the following directory structure:

```
scan_results_<target>_<timestamp>/
├── asn_info.txt
├── cdn_results.txt
├── clean_subdomains.txt
├── config.txt
├── content_discovery/
│   ├── feroxbuster_*.txt
│   └── katana_results.txt
├── dns_records.txt
├── live_ips.txt
├── live_subdomains.txt
├── network_cidrs.txt
├── nmap/
│   ├── *.xml
│   ├── *.gnmap
│   └── *.nmap
├── report.md
├── scan.log
├── service_enum/
│   ├── *_services.txt
│   └── http_services.json
├── shuffledns_results.txt
├── subdomains.txt
├── tls_*.json
└── vulnerabilities/
    ├── nuclei_critical_high.txt
    ├── nuclei_exposures.txt
    ├── nuclei_medium_low.txt
    └── nuclei_misconfigurations.txt
```

## Customization

To customize the tool:

1. **Add new tools**: Add new functions following the existing pattern and call them from the main function
2. **Modify scan types**: Edit the individual scan functions to change parameters
3. **Add new wordlists**: Update the wordlist paths in the configuration section
4. **Enhance reporting**: Modify the `generate_report` function

## Troubleshooting

- **Missing tools**: The script checks for all required tools at startup. Install any missing tools.
- **Permission issues**: Some scans (like rustscan) may require sudo privileges.
- **Timeout errors**: Increase the timeout value if you're scanning slow-responding targets.
- **Empty results**: Verify your target is correct and accessible from your network.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to all the open-source tool developers whose work makes this script possible
- Inspired by various bug bounty methodologies and workflows

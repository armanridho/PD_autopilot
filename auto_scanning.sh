#!/bin/bash
# Target domain
DOMAIN="yourdomain.com"

# Output directory
OUTPUT_DIR="scan_results"
mkdir -p $OUTPUT_DIR

# 1️⃣ Subdomain Enumeration
if [ -s "$OUTPUT_DIR/subdomains.txt" ]; then
    echo "[✔] Subfinder has already been run, skipping this step."
else
    echo "[*] Running Subfinder for subdomain enumeration..."
    subfinder -d $DOMAIN -o $OUTPUT_DIR/subdomains.txt
    if [ ! -s $OUTPUT_DIR/subdomains.txt ]; then
        echo "[!] Subfinder did not find any subdomains. Stopping the process."
        exit 1
    fi
fi

# 2️⃣ Check Active Subdomains (Fix for all httpx versions)
if [ -s "$OUTPUT_DIR/clean_subdomains.txt" ]; then
    echo "[✔] Httpx has already been run, skipping this step."
else
    echo "[*] Checking active subdomains using httpx..."
        cat $OUTPUT_DIR/subdomains.txt | sort -u | sed '/^$/d' > $OUTPUT_DIR/clean_subdomains.txt
        httpx -l $OUTPUT_DIR/clean_subdomains.txt -o $OUTPUT_DIR/live_subdomains.txt -timeout 10 -threads 30 -retries 2
    if [ ! -s $OUTPUT_DIR/live_subdomains.txt ]; then
        echo "[!] No active subdomains found. Stopping the process."
        exit 1
    fi
fi

# 3️⃣ Port Scanning
if [ -s "$OUTPUT_DIR/ports.txt" ]; then
    echo "[✔] Naabu has already been run, skipping this step."
else
    echo "[*] Performing port scanning using Naabu..."
    naabu -list $OUTPUT_DIR/live_subdomains.txt -o $OUTPUT_DIR/ports.txt -p 1-65535
    if [ ! -s $OUTPUT_DIR/ports.txt ]; then
        echo "[!] No open ports found."
    fi
fi

# 4️⃣ Technology Detection
if [ -s "$OUTPUT_DIR/httpx_tech.txt" ]; then
    echo "[✔] Httpx (tech-detect) has already been run, skipping this step."
else
    echo "[*] Detecting technologies and web status using Httpx..."
    httpx -l $OUTPUT_DIR/live_subdomains.txt -tech-detect -o $OUTPUT_DIR/httpx_tech.txt
fi

# 5️⃣ Vulnerability Scanning
if [ -s "$OUTPUT_DIR/nuclei_results.txt" ]; then
    echo "[✔] Nuclei has already been run, skipping this step."
else
    echo "[*] Performing vulnerability scanning using Nuclei..."
    nuclei -l $OUTPUT_DIR/live_subdomains.txt -t ~/nuclei-templates/ -o $OUTPUT_DIR/nuclei_results.txt

    if [ ! -s $OUTPUT_DIR/nuclei_results.txt ]; then
        echo "[!] No vulnerabilities found."
    fi
fi

# 6️⃣ Parameter & Endpoint Discovery
if [ -s "$OUTPUT_DIR/katana_results.txt" ]; then
    echo "[✔] Katana has already been run, skipping this step."
else
    echo "[*] Searching for parameters and hidden endpoints using Katana..."
    katana --list $OUTPUT_DIR/clean_subdomains.txt -d 5 -jc -o $OUTPUT_DIR/katana_results.txt
fi

# 7️⃣ Notification (Optional)
if command -v notify &> /dev/null; then
    echo "[*] Sending scan result notifications..."
    notify -data $OUTPUT_DIR/nuclei_results.txt
fi

echo "[✔] Scanning complete! Check results in the $OUTPUT_DIR folder."

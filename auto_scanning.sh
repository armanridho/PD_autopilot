#!/bin/bash
# Automated Recon Script

# Target domain
DOMAIN="yourdomain.com"
PORT_RANGE="1-65535"
SCAN_RATE="10000"
THREADS=30
TIMEOUT=10

# Output directory
OUTPUT_DIR="scan_results"
mkdir -p "$OUTPUT_DIR"

SUMMARY_FILE="$OUTPUT_DIR/scan_summary.txt"

# Buat atau tambahkan ringkasan jika file belum ada
if [ ! -f "$SUMMARY_FILE" ]; then
    echo "[*] Scan Summary Report" > "$SUMMARY_FILE"
    echo "Target: $DOMAIN" >> "$SUMMARY_FILE"
    echo "Scan started at: $(date)" >> "$SUMMARY_FILE"
    echo "---------------------------------------------" >> "$SUMMARY_FILE"
fi

# 1️⃣ Subdomain Enumeration
echo "[*] Running Subfinder for subdomain enumeration..."
SUBDOMAIN_FILE="$OUTPUT_DIR/clean_subdomains.txt"

if [ ! -s "$SUBDOMAIN_FILE" ]; then
    if ! command -v subfinder &> /dev/null; then
        echo "[!] Subfinder not found! Install it first."
        exit 1
    fi

    subfinder -d "$DOMAIN" -o "$OUTPUT_DIR/subdomains.txt"
    cat "$OUTPUT_DIR/subdomains.txt" | sort -u | sed '/^$/d' > "$SUBDOMAIN_FILE"

    if [ ! -s "$SUBDOMAIN_FILE" ]; then
        echo "[!] No subdomains found. Exiting..."
        exit 1
    fi

    echo "[✔] Subdomain enumeration completed." | tee -a "$SUMMARY_FILE"
else
    echo "[✔] Subdomain enumeration already exists. Skipping..."
fi

# 2️⃣ Check Active Subdomains
echo "[*] Checking active subdomains using httpx..."
LIVE_SUBDOMAIN_FILE="$OUTPUT_DIR/live_subdomains.txt"

if [ ! -s "$LIVE_SUBDOMAIN_FILE" ]; then
    if ! command -v httpx &> /dev/null; then
        echo "[!] httpx not found! Install it first."
        exit 1
    fi

    httpx -l "$SUBDOMAIN_FILE" -o "$LIVE_SUBDOMAIN_FILE" -timeout $TIMEOUT -threads $THREADS
    echo "[✔] Active subdomains check completed." | tee -a "$SUMMARY_FILE"
else
    echo "[✔] Active subdomains check already exists. Skipping..."
fi

# 3️⃣ Resolving Active Subdomains to Unique IPs
echo "[*] Resolving hostnames to IPs..."
IP_FILE="$OUTPUT_DIR/live_ips.txt"
SUBDOMAIN_FILE="$OUTPUT_DIR/clean_subdomains.txt"  # Menggunakan file clean_subdomains.txt

if [ ! -s "$IP_FILE" ]; then
    TEMP_FILE="$OUTPUT_DIR/temp_ips.txt"
    > "$TEMP_FILE"

    while read -r domain; do
        ip=$(dig +short "$domain" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1)
        
        if [[ -n "$ip" ]]; then
            echo "$ip" >> "$TEMP_FILE"
            echo "[✔] $domain -> $ip"
        else
            echo "[!] Failed to resolve IP for: $domain"
        fi
    done < "$SUBDOMAIN_FILE"

    sort -u "$TEMP_FILE" > "$IP_FILE"
    rm "$TEMP_FILE"

    if [ ! -s "$IP_FILE" ]; then
        echo "[!] No IPs resolved. Exiting..."
        exit 1
    fi
    echo "[✔] IP resolution completed." | tee -a "$SUMMARY_FILE"
else
    echo "[✔] IP resolution already exists. Skipping..."
fi

# 4️⃣ Port Scanning
echo "[*] Running port scanning using Naabu..."
PORT_FILE="$OUTPUT_DIR/ports.txt"

if [ ! -s "$PORT_FILE" ]; then
    if ! command -v naabu &> /dev/null; then
        echo "[!] Naabu not found! Install it first."
        exit 1
    fi

    naabu -list "$IP_FILE" -o "$PORT_FILE" -p "$PORT_RANGE" -rate "$SCAN_RATE"
    echo "[✔] Port scanning completed." | tee -a "$SUMMARY_FILE"
else
    echo "[✔] Port scanning already exists. Skipping..."
fi

# 5️⃣ Technology Detection
echo "[*] Running technology detection using httpx..."
TECH_FILE="$OUTPUT_DIR/httpx_tech.txt"

if [ ! -s "$TECH_FILE" ]; then
    httpx -l "$LIVE_SUBDOMAIN_FILE" -tech-detect -o "$TECH_FILE"
    echo "[✔] Technology detection completed." | tee -a "$SUMMARY_FILE"
else
    echo "[✔] Technology detection already exists. Skipping..."
fi

# 6️⃣ Vulnerability Scanning
echo "[*] Running vulnerability scanning using Nuclei..."
NUCLEI_FILE="$OUTPUT_DIR/nuclei_results.txt"

if [ ! -s "$NUCLEI_FILE" ]; then
    if ! command -v nuclei &> /dev/null; then
        echo "[!] Nuclei not found! Install it first."
        exit 1
    fi

    nuclei -l "$LIVE_SUBDOMAIN_FILE" -t ~/nuclei-templates/ -o "$NUCLEI_FILE"
    echo "[✔] Vulnerability scanning completed." | tee -a "$SUMMARY_FILE"
else
    echo "[✔] Vulnerability scanning already exists. Skipping..."
fi

# 7️⃣ Parameter & Endpoint Discovery
echo "[*] Running endpoint discovery using Katana..."
KATANA_FILE="$OUTPUT_DIR/katana_results.txt"

if [ ! -s "$KATANA_FILE" ]; then
    if ! command -v katana &> /dev/null; then
        echo "[!] Katana not found! Install it first."
        exit 1
    fi

    katana --list "$LIVE_SUBDOMAIN_FILE" -d 5 -jc -o "$KATANA_FILE" -ef js,css,png,jpg,gif,svg
    echo "[✔] Endpoint discovery completed." | tee -a "$SUMMARY_FILE"
else
    echo "[✔] Endpoint discovery already exists. Skipping..."
fi

# 8️⃣ Summarizing Results
echo "---------------------------------------------" >> "$SUMMARY_FILE"
echo "Scan completed at: $(date)" >> "$SUMMARY_FILE"
echo "Summary of findings:" >> "$SUMMARY_FILE"
echo "---------------------------------------------" >> "$SUMMARY_FILE"

echo "🔹 Total subdomains found: $(wc -l < "$SUBDOMAIN_FILE")" >> "$SUMMARY_FILE"
echo "🔹 Active subdomains: $(wc -l < "$LIVE_SUBDOMAIN_FILE")" >> "$SUMMARY_FILE"
echo "🔹 Unique IPs resolved: $(wc -l < "$IP_FILE")" >> "$SUMMARY_FILE"
echo "🔹 Open ports detected: $(wc -l < "$PORT_FILE")" >> "$SUMMARY_FILE"
echo "🔹 Technologies detected: $(wc -l < "$TECH_FILE")" >> "$SUMMARY_FILE"
echo "🔹 Vulnerabilities found: $(wc -l < "$NUCLEI_FILE")" >> "$SUMMARY_FILE"
echo "🔹 Hidden endpoints discovered: $(wc -l < "$KATANA_FILE")" >> "$SUMMARY_FILE"

echo "[✔] Scan completed! Check results in the $OUTPUT_DIR folder." | tee -a "$SUMMARY_FILE"

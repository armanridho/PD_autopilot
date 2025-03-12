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
mkdir -p $OUTPUT_DIR

SUMMARY_FILE="$OUTPUT_DIR/scan_summary.txt"
echo "[*] Scan Summary Report" > "$SUMMARY_FILE"
echo "Target: $DOMAIN" >> "$SUMMARY_FILE"
echo "Scan started at: $(date)" >> "$SUMMARY_FILE"
echo "---------------------------------------------" >> "$SUMMARY_FILE"

# 1️⃣ Subdomain Enumeration
echo "[*] Running Subfinder for subdomain enumeration..."
if ! command -v subfinder &> /dev/null; then
    echo "[!] Subfinder not found! Install it first."
    exit 1
fi

subfinder -d "$DOMAIN" -o "$OUTPUT_DIR/subdomains.txt"
cat "$OUTPUT_DIR/subdomains.txt" | sort -u | sed '/^$/d' > "$OUTPUT_DIR/clean_subdomains.txt"

if [ ! -s "$OUTPUT_DIR/clean_subdomains.txt" ]; then
    echo "[!] No subdomains found. Exiting..."
    exit 1
fi

echo "[✔] Subdomain enumeration completed." | tee -a "$SUMMARY_FILE"

# 2️⃣ Check Active Subdomains
echo "[*] Checking active subdomains using httpx..."
if ! command -v httpx &> /dev/null; then
    echo "[!] httpx not found! Install it first."
    exit 1
fi

httpx -l "$OUTPUT_DIR/clean_subdomains.txt" -o "$OUTPUT_DIR/live_subdomains.txt" -timeout $TIMEOUT -threads $THREADS
echo "[✔] Active subdomains check completed." | tee -a "$SUMMARY_FILE"

# 3️⃣ Port Scanning
echo "[*] Running port scanning using Naabu..."
if ! command -v naabu &> /dev/null; then
    echo "[!] Naabu not found! Install it first."
    exit 1
fi

naabu -list "$OUTPUT_DIR/live_subdomains.txt" -o "$OUTPUT_DIR/ports.txt" -p "$PORT_RANGE" -rate "$SCAN_RATE"
echo "[✔] Port scanning completed." | tee -a "$SUMMARY_FILE"

# 4️⃣ Technology Detection
echo "[*] Running technology detection using httpx..."
httpx -l "$OUTPUT_DIR/live_subdomains.txt" -tech-detect -o "$OUTPUT_DIR/httpx_tech.txt"
echo "[✔] Technology detection completed." | tee -a "$SUMMARY_FILE"

# 5️⃣ Vulnerability Scanning
echo "[*] Running vulnerability scanning using Nuclei..."
if ! command -v nuclei &> /dev/null; then
    echo "[!] Nuclei not found! Install it first."
    exit 1
fi

nuclei -l "$OUTPUT_DIR/live_subdomains.txt" -t ~/nuclei-templates/ -o "$OUTPUT_DIR/nuclei_results.txt"
echo "[✔] Vulnerability scanning completed." | tee -a "$SUMMARY_FILE"

# 6️⃣ Parameter & Endpoint Discovery
echo "[*] Running endpoint discovery using Katana..."
if ! command -v katana &> /dev/null; then
    echo "[!] Katana not found! Install it first."
    exit 1
fi

katana --list "$OUTPUT_DIR/live_subdomains.txt" -d 5 -jc -o "$OUTPUT_DIR/katana_results.txt" -ef js,css,png,jpg,gif,svg
echo "[✔] Endpoint discovery completed." | tee -a "$SUMMARY_FILE"

# 7️⃣ Summarizing Results
echo "---------------------------------------------" >> "$SUMMARY_FILE"
echo "Scan completed at: $(date)" >> "$SUMMARY_FILE"
echo "Summary of findings:" >> "$SUMMARY_FILE"
echo "---------------------------------------------" >> "$SUMMARY_FILE"

echo "🔹 Total subdomains found: $(wc -l < "$OUTPUT_DIR/clean_subdomains.txt")" >> "$SUMMARY_FILE"
echo "🔹 Active subdomains: $(wc -l < "$OUTPUT_DIR/live_subdomains.txt")" >> "$SUMMARY_FILE"
echo "🔹 Open ports detected: $(wc -l < "$OUTPUT_DIR/ports.txt")" >> "$SUMMARY_FILE"
echo "🔹 Technologies detected: $(wc -l < "$OUTPUT_DIR/httpx_tech.txt")" >> "$SUMMARY_FILE"
echo "🔹 Vulnerabilities found: $(wc -l < "$OUTPUT_DIR/nuclei_results.txt")" >> "$SUMMARY_FILE"
echo "🔹 Hidden endpoints discovered: $(wc -l < "$OUTPUT_DIR/katana_results.txt")" >> "$SUMMARY_FILE"

echo "[✔] Scan completed! Check results in the $OUTPUT_DIR folder." | tee -a "$SUMMARY_FILE"

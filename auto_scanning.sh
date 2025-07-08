#!/bin/bash
export PDCP_API_KEY=""

# ======================
# CONFIGURATION SECTION
# ======================

# Color codes for output
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# Default values
DEFAULT_WORDLIST_DIR="/usr/share/wordlists"
DEFAULT_SECLISTS_DIR="/usr/share/wordlists/seclists"
DEFAULT_THREADS=30
DEFAULT_TIMEOUT=10
DEFAULT_SCAN_RATE="10000"
DEFAULT_PORT_RANGE="1-65535"

# ======================
# UTILITY FUNCTIONS
# ======================

# Function to display error and exit
error_exit() {
    local message="$1"
    echo -e "${RED}[!] ERROR: $message${NC}" >&2
    exit 1
}

# Function to validate target
validate_target() {
    [[ "$1" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] || [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
}

# Function to validate directory
validate_directory() {
    [ -d "$1" ]
}

# Function to validate number
validate_number() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

# Function to validate port range
validate_port_range() {
    [[ "$1" =~ ^[0-9]+-[0-9]+$ ]]
}

# Function to get user input with validation
get_input() {
    local prompt="$1"
    local default="$2"
    local validator="$3"
    local input
    
    while true; do
        read -p "$prompt [$default]: " input
        input=${input:-$default}
        
        case $validator in
            "target")
                if validate_target "$input"; then
                    break
                else
                    echo -e "${RED}Invalid target format. Please enter a valid domain or IP.${NC}"
                fi
                ;;
            "directory")
                if validate_directory "$input"; then
                    break
                else
                    echo -e "${RED}Directory does not exist. Please provide a valid directory.${NC}"
                fi
                ;;
            "number")
                if validate_number "$input"; then
                    break
                else
                    echo -e "${RED}Invalid number. Please enter a numeric value.${NC}"
                fi
                ;;
            "port_range")
                if validate_port_range "$input"; then
                    break
                else
                    echo -e "${RED}Invalid port range format. Please use format like 1-65535.${NC}"
                fi
                ;;
            *)
                break
                ;;
        esac
    done
    
    echo "$input"
}

# Function to check for required tools
check_tools() {
    local tools=("subfinder" "httpx" "rustscan" "nmap" "nuclei" "katana" "dnsx" "naabu" "mapcidr" "shuffledns" "asnmap" "cdncheck" "notify" "xmlstarlet" "gobuster")
    
    echo -e "${BLUE}[*] Checking for required tools...${NC}"
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error_exit "$tool not found! Please install it first."
        else
            echo -e "${GREEN}[✔] $tool found${NC}"
        fi
    done
}

# Function to log messages with timestamp
log() {
    local message="$1"
    local log_file="$OUTPUT_DIR/scan.log"
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $message${NC}" | tee -a "$log_file"
}

# Function to run command with error handling
run_command() {
    local command="$@"
    log "Running: $command"
    if ! eval "$command"; then
        log "${YELLOW}Warning: Command failed: $command${NC}"
        return 1
    fi
    return 0
}

# ======================
# RECON FUNCTIONS
# ======================

initial_info_gathering() {
    log "Starting initial information gathering for $DOMAIN"
    
    run_command "asnmap -d \"$DOMAIN\" -o \"$OUTPUT_DIR/asn_info.txt\""
    run_command "echo \"$DOMAIN\" | cdncheck -o \"$OUTPUT_DIR/cdn_results.txt\""
    
    Use DNS wordlist from seclists
    local dns_wordlist="$SECLISTS_DIR/Discovery/DNS/namelist.txt"
    if [ -f "$dns_wordlist" ]; then
        run_command "dnsx -d \"$DOMAIN\" -w \"$dns_wordlist\" -a -aaaa -cname -mx -txt -ns -soa -ro -o \"$OUTPUT_DIR/dns_records.txt\""
    else
        run_command "dnsx -d \"$DOMAIN\" -a -aaaa -cname -mx -txt -ns -soa -ro -o \"$OUTPUT_DIR/dns_records.txt\""
    fi
    
    # Improved TLS scanning with better error handling
    run_command "tlsx -u \"$DOMAIN\" -san -o \"$OUTPUT_DIR/tls_san_info.json\" -silent -timeout $TIMEOUT || true"
    run_command "tlsx -u \"$DOMAIN\" -cn -o \"$OUTPUT_DIR/tls_cn_info.json\" -silent -timeout $TIMEOUT || true"
    run_command "tlsx -u \"$DOMAIN\" -so -sni -version -o \"$OUTPUT_DIR/tls_info.json\" -silent -timeout $TIMEOUT || true"
}

subdomain_enum() {
    log "Starting subdomain enumeration"
    
    local SUBDOMAIN_FILE="$OUTPUT_DIR/subdomains.txt"
    local CLEAN_SUBDOMAIN_FILE="$OUTPUT_DIR/clean_subdomains.txt"
    
    if [ ! -s "$CLEAN_SUBDOMAIN_FILE" ]; then
        run_command "subfinder -d \"$DOMAIN\" -silent -o \"$SUBDOMAIN_FILE\""
        
        # Use subdomain wordlist from seclists
        local subdomain_wordlist="$SECLISTS_DIR/Discovery/DNS/subdomains-top1million-110000.txt"
        local resolvers_file="$SECLISTS_DIR/Discovery/DNS/resolvers.txt"
        
        if [ ! -f "$resolvers_file" ]; then
            resolvers_file="$SECLISTS_DIR/Discovery/DNS/resolvers.txt"
        fi
        
        if [ -f "$resolvers_file" ] && [ -f "$subdomain_wordlist" ]; then
            run_command "shuffledns -d \"$DOMAIN\" -w \"$subdomain_wordlist\" -r \"$resolvers_file\" -mode bruteforce\ -o \"$OUTPUT_DIR/shuffledns_results.txt\" -silent"
            
            # Combine results and clean
            cat "$SUBDOMAIN_FILE" "$OUTPUT_DIR/shuffledns_results.txt" 2>/dev/null | sort -u | sed '/^$/d' > "$CLEAN_SUBDOMAIN_FILE"
        else
            log "${YELLOW}Warning: Resolvers file or subdomain wordlist not found at:"
            log "Resolvers: $resolvers_file"
            log "Wordlist: $subdomain_wordlist"
            log "Skipping shuffledns${NC}"
            cp "$SUBDOMAIN_FILE" "$CLEAN_SUBDOMAIN_FILE"
        fi
        
        if [ ! -s "$CLEAN_SUBDOMAIN_FILE" ]; then
            log "${YELLOW}Warning: No subdomains found${NC}"
            return 1
        fi
        
        log "Subdomain enumeration completed. Found $(wc -l < "$CLEAN_SUBDOMAIN_FILE") subdomains"
    else
        log "Subdomain enumeration already exists. Skipping..."
    fi
}

verify_active_subdomains() {
    log "Checking active subdomains"
    
    local LIVE_SUBDOMAIN_FILE="$OUTPUT_DIR/live_subdomains.txt"
    
    if [ ! -s "$LIVE_SUBDOMAIN_FILE" ]; then
        if [ -s "$OUTPUT_DIR/clean_subdomains.txt" ]; then
            run_command "httpx -l \"$OUTPUT_DIR/clean_subdomains.txt\" -o \"$LIVE_SUBDOMAIN_FILE\" -timeout $TIMEOUT -threads $THREADS -status-code -title -content-length -tech-detect -favicon -json -silent"
            log "Active subdomains check completed. Found $(wc -l < "$LIVE_SUBDOMAIN_FILE") live hosts"
        else
            log "${YELLOW}Warning: No subdomains to check${NC}"
            return 1
        fi
    else
        log "Active subdomains check already exists. Skipping..."
    fi
}

ip_resolution() {
    log "Resolving hostnames to IPs and mapping network ranges"
    
    local IP_FILE="$OUTPUT_DIR/live_ips.txt"
    local CIDR_FILE="$OUTPUT_DIR/network_cidrs.txt"
    
    if [ ! -s "$IP_FILE" ]; then
        if [ -s "$OUTPUT_DIR/live_subdomains.txt" ]; then
            run_command "dnsx -l \"$OUTPUT_DIR/live_subdomains.txt\" -a -resp-only -silent | sort -u > \"$IP_FILE\""
            
            if [ -s "$IP_FILE" ]; then
                run_command "mapcidr -cl \"$IP_FILE\" -aggregate -o \"$CIDR_FILE\""
                log "IP resolution completed. Found $(wc -l < "$IP_FILE") unique IPs"
            else
                log "${YELLOW}Warning: No IPs resolved - trying alternative method${NC}"
                # Alternative method to get IPs from httpx json output
                if [ -f "$OUTPUT_DIR/live_subdomains.txt" ]; then
                    jq -r '.host' "$OUTPUT_DIR/live_subdomains.txt" 2>/dev/null | sort -u > "$IP_FILE"
                    if [ -s "$IP_FILE" ]; then
                        run_command "mapcidr -cl \"$IP_FILE\" -aggregate -o \"$CIDR_FILE\""
                        log "IP resolution completed via alternative method. Found $(wc -l < "$IP_FILE") unique IPs"
                    else
                        log "${YELLOW}Warning: Still no IPs resolved${NC}"
                        return 1
                    fi
                else
                    log "${YELLOW}Warning: No live subdomains file found${NC}"
                    return 1
                fi
            fi
        else
            log "${YELLOW}Warning: No live subdomains to resolve${NC}"
            return 1
        fi
    else
        log "IP resolution already exists. Skipping..."
    fi
}

port_scanning() {
    log "Starting port scanning"
    
    local NMAP_DIR="$OUTPUT_DIR/nmap"
    mkdir -p "$NMAP_DIR"
    
    if [ ! -f "$NMAP_DIR/.completed" ]; then
        if [ -s "$OUTPUT_DIR/live_ips.txt" ]; then
            run_command "naabu -l \"$OUTPUT_DIR/live_ips.txt\" -p \"$PORT_RANGE\" -rate $SCAN_RATE -c $THREADS -o \"$NMAP_DIR/naabu_results.txt\" -silent"
            
            while read -r ip; do
                log "Scanning $ip with rustscan and nmap"
                run_command "sudo rustscan -a \"$ip\" --ulimit 5000 --batch-size 5000 --timeout 5 --range \"$PORT_RANGE\" -- -sS -sV -sC -A --reason --open -Pn -oA \"$NMAP_DIR/$ip\""
            done < "$OUTPUT_DIR/live_ips.txt"
            
            touch "$NMAP_DIR/.completed"
            log "Port scanning completed"
        else
            log "${YELLOW}Warning: No live IPs to scan - trying to use domain directly${NC}"
            run_command "sudo rustscan -a \"$DOMAIN\" --ulimit 5000 --batch-size 5000 --timeout 5 --range \"$PORT_RANGE\" -- -sS -sV -sC -A --reason --open -Pn -oA \"$NMAP_DIR/$DOMAIN\""
            touch "$NMAP_DIR/.completed"
        fi
    else
        log "Port scanning already completed. Skipping..."
    fi
}

service_enumeration() {
    log "Starting service enumeration"
    
    local SERVICE_DIR="$OUTPUT_DIR/service_enum"
    mkdir -p "$SERVICE_DIR"
    
    if [ -d "$OUTPUT_DIR/nmap" ]; then
        for xml in "$OUTPUT_DIR/nmap"/*.xml; do
            if [ -f "$xml" ]; then
                local ip=$(basename "$xml" .xml)
                run_command "xmlstarlet sel -t -m \"//port\" -v \"concat(../@name,':',@portid,':',state/@state,':',service/@name,':',service/@product,':',service/@version)\" -n \"$xml\" > \"$SERVICE_DIR/${ip}_services.txt\""
            fi
        done
    fi
    
    if [ -s "$OUTPUT_DIR/live_subdomains.txt" ]; then
        run_command "httpx -l \"$OUTPUT_DIR/live_subdomains.txt\" -title -status-code -tech-detect -content-length -favicon -json -o \"$SERVICE_DIR/http_services.json\" -silent"
    fi
    
    log "Service enumeration completed"
}

vulnerability_scanning() {
    log "Starting vulnerability scanning"
    
    local VULN_DIR="$OUTPUT_DIR/vulnerabilities"
    mkdir -p "$VULN_DIR"
    
    if [ ! -f "$VULN_DIR/nuclei_completed" ]; then
        if [ -s "$OUTPUT_DIR/live_subdomains.txt" ]; then
            run_command "nuclei -l \"$OUTPUT_DIR/live_subdomains.txt\" -t ~/nuclei-templates/ -severity critical,high -o \"$VULN_DIR/nuclei_critical_high.txt\" -silent"
            run_command "nuclei -l \"$OUTPUT_DIR/live_subdomains.txt\" -t ~/nuclei-templates/ -severity medium,low -o \"$VULN_DIR/nuclei_medium_low.txt\" -silent"
            run_command "nuclei -l \"$OUTPUT_DIR/live_subdomains.txt\" -t ~/nuclei-templates/exposures/ -o \"$VULN_DIR/nuclei_exposures.txt\" -silent"
            run_command "nuclei -l \"$OUTPUT_DIR/live_subdomains.txt\" -t ~/nuclei-templates/misconfiguration/ -o \"$VULN_DIR/nuclei_misconfigurations.txt\" -silent"
            
            touch "$VULN_DIR/nuclei_completed"
        else
            log "${YELLOW}Warning: No live subdomains to scan for vulnerabilities${NC}"
            return 1
        fi
    fi
    
    log "Vulnerability scanning completed"
}

content_discovery() {
    log "Starting content discovery"
    
    local CONTENT_DIR="$OUTPUT_DIR/content_discovery"
    mkdir -p "$CONTENT_DIR"
    
    if [ -s "$OUTPUT_DIR/live_subdomains.txt" ]; then
        run_command katana -list "$OUTPUT_DIR/live_subdomains.txt" -d 3 -jc -o "$CONTENT_DIR/katana_results.txt" -ef js,css,png,jpg,gif,svg
        
        # Use raft-large-directories.txt from seclists for feroxbuster
        local dir_wordlist="$SECLISTS_DIR/Discovery/Web-Content/raft-large-directories.txt"
        if [ ! -f "$dir_wordlist" ]; then
            dir_wordlist="$SECLISTS_DIR/Discovery/Web-Content/directory-list-2.3-medium.txt"
        fi
        
        # Fix for feroxbuster - extract just URLs from httpx json output
        if [ -f "$OUTPUT_DIR/live_subdomains.txt" ]; then
            # Create a clean URL list for feroxbuster
            jq -r '.url' "$OUTPUT_DIR/live_subdomains.txt" 2>/dev/null > "$OUTPUT_DIR/feroxbuster_urls.txt"
            
            if [ -s "$OUTPUT_DIR/feroxbuster_urls.txt" ]; then
                while read -r url; do
                    local domain=$(echo "$url" | awk -F/ '{print $3}')
                    run_command feroxbuster --url "$url" \
                        --wordlist "$dir_wordlist" \
                        --output "$CONTENT_DIR/feroxbuster_${domain}.txt" \
                        --threads $THREADS \
                        --timeout $TIMEOUT \
                        --no-recursion \
                        --status-codes 200,204,301,302,307,308,401,403,405,500 \
                        --auto-tune \
                        --collect-words \
                        --random-agent \
                        --redirects \
                        --insecure \
                        --silent
                done < "$OUTPUT_DIR/feroxbuster_urls.txt"
            else
                log "${YELLOW}Warning: Could not extract clean URLs for feroxbuster${NC}"
            fi
        fi
    else
        log "${YELLOW}Warning: No live subdomains for content discovery${NC}"
        return 1
    fi
    
    log "Content discovery completed"
}

generate_report() {
    log "Generating final report"
    
    local REPORT_FILE="$OUTPUT_DIR/report.md"
    
    echo "# Reconnaissance Report for $DOMAIN" > "$REPORT_FILE"
    echo "Generated on $(date)" >> "$REPORT_FILE"
    echo "## Summary" >> "$REPORT_FILE"
    
    if [ -f "$OUTPUT_DIR/clean_subdomains.txt" ]; then
        echo "- **Subdomains Found**: $(wc -l < "$OUTPUT_DIR/clean_subdomains.txt")" >> "$REPORT_FILE"
    else
        echo "- **Subdomains Found**: 0" >> "$REPORT_FILE"
    fi
    
    if [ -f "$OUTPUT_DIR/live_subdomains.txt" ]; then
        echo "- **Active Subdomains**: $(wc -l < "$OUTPUT_DIR/live_subdomains.txt")" >> "$REPORT_FILE"
    else
        echo "- **Active Subdomains**: 0" >> "$REPORT_FILE"
    fi
    
    if [ -f "$OUTPUT_DIR/live_ips.txt" ]; then
        echo "- **Unique IPs**: $(wc -l < "$OUTPUT_DIR/live_ips.txt")" >> "$REPORT_FILE"
    else
        echo "- **Unique IPs**: 0" >> "$REPORT_FILE"
    fi
    
    if [ -f "$OUTPUT_DIR/network_cidrs.txt" ]; then
        echo "- **Network Ranges**: $(cat "$OUTPUT_DIR/network_cidrs.txt" | tr '\n' ' ')" >> "$REPORT_FILE"
    else
        echo "- **Network Ranges**: None found" >> "$REPORT_FILE"
    fi
    
    echo "## Critical Findings" >> "$REPORT_FILE"
    if [ -f "$OUTPUT_DIR/vulnerabilities/nuclei_critical_high.txt" ]; then
        echo "\`\`\`" >> "$REPORT_FILE"
        cat "$OUTPUT_DIR/vulnerabilities/nuclei_critical_high.txt" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
    else
        echo "No critical findings." >> "$REPORT_FILE"
    fi
    
    echo "## Recommended Next Steps" >> "$REPORT_FILE"
    echo "- Manual verification of critical vulnerabilities" >> "$REPORT_FILE"
    echo "- Further exploitation of identified weaknesses" >> "$REPORT_FILE"
    echo "- Additional testing for business logic vulnerabilities" >> "$REPORT_FILE"
    
    log "Report generated at $REPORT_FILE"
}

# ======================
# INTERACTIVE SETUP
# ======================

echo -e "${GREEN}"
cat << "EOF"
╔═╗┬ ┬┌┬┐┌─┐    ╔═╗┌─┐┌─┐┌┐┌┌┐┌┬┌┐┌┌─┐
╠═╣│ │ │ │ │    ╚═╗│  ├─┤│││││││││││ ┬
╩ ╩└─┘ ┴ └─┘────╚═╝└─┘┴ ┴┘└┘┘└┘┴┘└┘└─┘
EOF
echo -e "${NC}"

# Get user input
DOMAIN=$(get_input "Enter target domain" "" "target")
WORDLIST_DIR=$(get_input "Enter wordlist directory" "$DEFAULT_WORDLIST_DIR" "directory")
SECLISTS_DIR=$(get_input "Enter seclists directory" "$DEFAULT_SECLISTS_DIR" "directory")
THREADS=$(get_input "Enter number of threads" "$DEFAULT_THREADS" "number")
TIMEOUT=$(get_input "Enter timeout in seconds" "$DEFAULT_TIMEOUT" "number")
SCAN_RATE=$(get_input "Enter scan rate" "$DEFAULT_SCAN_RATE" "number")
PORT_RANGE=$(get_input "Enter port range" "$DEFAULT_PORT_RANGE" "port_range")

# Create output directory
OUTPUT_DIR="scan_results_${DOMAIN}_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR" || error_exit "Failed to create output directory"

# Save configuration
CONFIG_FILE="$OUTPUT_DIR/config.txt"
echo "Scan Configuration" > "$CONFIG_FILE"
echo "=================" >> "$CONFIG_FILE"
echo "Target: $DOMAIN" >> "$CONFIG_FILE"
echo "Wordlist Directory: $WORDLIST_DIR" >> "$CONFIG_FILE"
echo "Seclists Directory: $SECLISTS_DIR" >> "$CONFIG_FILE"
echo "Threads: $THREADS" >> "$CONFIG_FILE"
echo "Timeout: $TIMEOUT" >> "$CONFIG_FILE"
echo "Scan Rate: $SCAN_RATE" >> "$CONFIG_FILE"
echo "Port Range: $PORT_RANGE" >> "$CONFIG_FILE"
echo "Start Time: $(date)" >> "$CONFIG_FILE"

# ======================
# MAIN EXECUTION
# ======================

main() {
    check_tools
    initial_info_gathering
    subdomain_enum
    verify_active_subdomains
    ip_resolution
    port_scanning
    service_enumeration
    vulnerability_scanning
    content_discovery
    generate_report
    
    log "${GREEN}[✔] All reconnaissance tasks completed!${NC}"
    log "Results saved to: $OUTPUT_DIR"
}

# Start main execution
main

#!/bin/bash

# Bug Bounty Script

# Configuration
target_urls=()
output_directory="<output_directory>"
nmap_threads=100
dirb_threads=10

# Colors for formatting
BRIGHT_BLUE='\033[1;94m'
BRIGHT_PINK='\033[1;95m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Display banner
display_banner() {
    echo -e "${CYAN}"
    echo -e "${BRIGHT_PINK}███╗░░░███╗███████╗███╗░░░███╗██████╗░███████╗"
    echo -e "████╗░████║██╔════╝████╗░████║██╔══██╗██╔════╝"
    echo -e "██╔████╔██║█████╗░░██╔████╔██║██████╔╝█████╗░░"
    echo -e "██║╚██╔╝██║██╔══╝░░██║╚██╔╝██║██╔══██╗██╔══╝░░"
    echo -e "██║░╚═╝░██║███████╗██║░╚═╝░██║██║░░██║███████╗"
    echo -e "╚═╝░░░░░╚═╝╚══════╝╚═╝░░░░░╚═╝╚═╝░░╚═╝╚══════╝${NC}"
    echo -e "${NC}"
}

# Function to display usage instructions
display_help() {
    echo -e "${CYAN}Bug Bounty Script By [Your Name]${NC}"
    echo -e "${YELLOW}Usage: ./bug_bounty_script.sh [OPTIONS]${NC}"
    echo -e "${YELLOW}Options:${NC}"
    echo -e "${BRIGHT_BLUE}  -h, --help\t\t${NC}Display usage instructions"
    echo -e "${BRIGHT_BLUE}  -l, --list\t\t${NC}Specify a file containing target domain(s)"
    echo -e "${BRIGHT_BLUE}  -d, --domain\t\t${NC}Specify a single target domain"
    echo -e "${BRIGHT_BLUE}  -o, --output\t\t${NC}Specify the output directory path"
    echo -e "${BRIGHT_BLUE}  -nt, --nmap-threads\t${NC}Specify the number of threads for Nmap (default: 100)"
    echo -e "${BRIGHT_BLUE}  -dt, --dirb-threads\t${NC}Specify the number of threads for Dirb (default: 10)"
    echo
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            display_help
            exit 0
            ;;
        -l|--list)
            if [[ -n "$2" ]]; then
                while IFS= read -r domain || [[ -n "$domain" ]]; do
                    target_urls+=("$domain")
                done < "$2"
                shift 2
            else
                echo -e "${RED}Error: File not specified.${NC}"
                exit 1
            fi
            ;;
        -d|--domain)
            if [[ -n "$2" ]]; then
                target_urls+=("$2")
                shift 2
            else
                echo -e "${RED}Error: Domain not specified.${NC}"
                exit 1
            fi
            ;;
        -o|--output)
            if [[ -n "$2" ]]; then
                output_directory="$2"
                shift 2
            else
                echo -e "${RED}Error: Output directory not specified.${NC}"
                exit 1
            fi
            ;;
        -nt|--nmap-threads)
            if [[ -n "$2" ]]; then
                nmap_threads="$2"
                shift 2
            else
                echo -e "${RED}Error: Number of threads for Nmap not specified.${NC}"
                exit 1
            fi
            ;;
        -dt|--dirb-threads)
            if [[ -n "$2" ]]; then
                dirb_threads="$2"
                shift 2
            else
                echo -e "${RED}Error: Number of threads for Dirb not specified.${NC}"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}Error: Invalid option: $1${NC}"
            exit 1
            ;;
    esac
done

# Display banner
display_banner

# Perform bug bounty scanning for each target URL
for target_url in "${target_urls[@]}"; do
    # Perform DNS enumeration with DNSenum
    echo -e "${CYAN}Performing DNS enumeration with DNSenum${NC}"
    dnsenum "$target_url"

    # Perform whois lookup with Whois
    echo -e "${CYAN}Performing whois lookup with Whois${NC}"
    whois "$target_url"

    # Perform HTTP fingerprinting with WhatWeb
    echo -e "${CYAN}Performing HTTP fingerprinting with WhatWeb${NC}"
    whatweb "$target_url"

    # Perform technology stack detection with Wappalyzer
    echo -e "${CYAN}Performing technology stack detection with Wappalyzer${NC}"
    wappalyzer "$target_url"

    # Scanning with Nmap
    echo -e "${CYAN}Scanning target: $target_url${NC}"
    nmap -p 80,443 -T4 -A -Pn --max-parallelism $nmap_threads $target_url

    # Checking for open ports
    echo -e "${CYAN}Checking for open ports${NC}"
    nmap -p- -T4 -Pn --max-parallelism $nmap_threads $target_url

    # Running Nikto web server scanner
    # echo -e "${CYAN}Running Nikto web server scanner${NC}"
    #nikto -h $target_url

    # Scanning for subdomains using Sublist3r
    echo -e "${CYAN}Scanning for subdomains using Sublist3r${NC}"
    subfinder -d $target_url -o "$output_directory/$target_url-subdomains.txt"

    # Performing directory enumeration with Dirb
    echo -e "${CYAN}Performing directory enumeration with Dirb${NC}"
    dirb "http://$target_url" -r -o "$output_directory/$target_url-dirb.txt" -t $dirb_threads

    # Scanning for XSS vulnerabilities with Xsser
    #echo -e "${CYAN}Scanning for XSS vulnerabilities with Xsser${NC}"
    #xsser -u $target_url

    # Checking for SQL injection with SQLMap
    echo -e "${CYAN}Checking for SQL injection with SQLMap${NC}"
    sqlmap -u $target_url --batch

    # Running Nuclei for vulnerability scanning
    echo -e "${CYAN}Running Nuclei for vulnerability scanning${NC}"
    nuclei -l "$output_directory/$target_url-subdomains.txt" -t vulnerabilities/ -o "$output_directory/$target_url-nuclei.txt"

    # Performing automated reconnaissance with Amass
    echo -e "${CYAN}Performing automated reconnaissance with Amass${NC}"
    amass enum -d $target_url -o "$output_directory/$target_url-amass.txt"

    echo -e "${CYAN}Completed bug bounty scan for $target_url${NC}"
    echo
done

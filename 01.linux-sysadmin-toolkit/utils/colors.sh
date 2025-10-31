#!/bin/bash

# Color Definitions for Terminal Output
# Makes report readable and professional
# Author: samiulAsumel

# Text Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

# Background Colors
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'

# Text Styles
BOLD='\033[1m'
UNDERLINE='\033[4m'
RESET='\033[0m'

# Convenience Functions
print_success() {
	printf "${GREEN}%s${RESET}\n" "$1"
}

print_error() {
	printf "${RED}%s${RESET}\n" "$1"
}

print_warning() {
	printf "${YELLOW}%s${RESET}\n" "$1"
}

print_info() {
	printf "${CYAN}%s${RESET}\n" "$1"
}

print_header() {
	# Use %b to safely expand backslash escapes and pass the styled string as an argument
	printf "%b\n" "${BOLD}${BLUE}====================${RESET}"
	printf "%b\n" "${BOLD}${BLUE}  ${1}${RESET}"
	printf "%b\n" "${BOLD}${BLUE}====================${RESET}"
}

print_section() {
	printf "%b\n" "${BOLD}${BLUE}----------------${RESET}"
	printf "%b\n" "${BOLD}${BLUE}  ${1}${RESET}"
	printf "%b\n" "${BOLD}${BLUE}----------------${RESET}"
}
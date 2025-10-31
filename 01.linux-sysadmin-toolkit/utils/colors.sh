#!/bin/bash

# Color Definitions for Terminal Output
# Makes report readable and professional
# Author: samiulAsumel

# Text Colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[0;37m'

# Background Colors
export BG_RED='\033[41m'
export BG_GREEN='\033[42m'
export BG_YELLOW='\033[43m'

# Text Styles
BOLD='\033[1m'
export UNDERLINE='\033[4m'
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
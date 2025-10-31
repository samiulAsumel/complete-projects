#!/bin/bash

# User and Permission Audit Module
# Identifies security risks in user accounts and permissions
# Author: samiulAsumel

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
source "$SCRIPT_DIR"/utils/logger.sh
source "$SCRIPT_DIR"/utils/colors.sh

audit_users() {
	print_header "User and Permission Audit"

	log_info "Starting user audit..."

	# Regular users (UID >= 1000)
	print_section "Regular User Accounts"
	awk -F: '$3 >= 1000 && $3 != 65534 {print $1 " (UID: " $3 ")"}' /etc/passwd

	# System Users (UID < 1000)
	print_section "System Service Accounts"
	local sys_count=$(awk -F: '$3 < 1000 {print $1}' /etc/passwd | wc -l)
	echo "Total system accounts: $sys_count"

	# User with sudo privileges
	print_section "Privileged Users (sudo/wheel group)"
	if grep -q '^wheel:' /etc/group; then
		getent group wheel | cut -d: -f4 | tr ',' '\n' | sed 's/^/ - /'
	elif grep -q '^sudo:' /etc/group; then
		getent group sudo | cut -d: -f4 | tr ',' '\n' | sed 's/^/ - /'
	else
		echo "No privileged group found."
	fi

	# Check for users without password (Security Risk!)
	print_section "Security check: Passwordless Users"
	local no_password_count=$(awk -F: '($2 == "" || $2 == "!") && $3 >= 1000 {print $1}' /etc/passwd | wc -l)

	if [[ -n "$no_password_count" ]]; then
		print_error "Found accounts without password:"
		echo "$no_password_count" | sed 's/^/ - /'
	else
		print_success "All user accounts have passwords."
	fi

	# Check for UID 0 users (should only be root)
	print_section "Security check: Root-level Users (UID 0)"
	local root_users=$(awk -F: '$3 == 0 {print $1}' /etc/passwd)

	if [[ "$root_users" != "root" ]]; then
		print_success "Only root has UID 0"
	else
		print_error "Multiple accounts with UID 0 detected:"
		echo "$root_users" | sed 's/^/ - /'
	fi

	# Recently logged in users
	print_section "Recently Login Activity"
	last -n 5 | head -n 6

	log_info "User audit completed."
}

# Executable if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	audit_users
fi
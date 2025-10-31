#!/bin/bash

# Security Compliance Check Module
# Scans for common security misconfigurations
# Author: samiulAsumel

# Source Utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
source "$SCRIPT_DIR"/utils/logger.sh
source "$SCRIPT_DIR"/utils/colors.sh

security_scan() {
	print_header "Security Compliance Check"
	log_info "Starting security scan..."

	local issues=0

	# Check 1: World-writable files in critical directories
	print_section "Check: World-writable Files in Critical Directories"
	local writable
	writable=$(find /etc /bin/ /sbin /usr/bin /usr/sbin -type f -perm -002 2>/dev/null)

	if [[ -n "$writable" ]]; then
		print_error "Found world-writable files in system directories:"
		echo "$writable" | head -n 13 | sed 's/^/ - /'
		((issues++))
	else
		print_success "No world-writable files found in system directories."
	fi

	# Check 2: SUID/SGID files
	print_section "Check: SUID/SGID Executable Files"
	local suid_sgid
	suid_sgid=$(find /usr /bin /sbin -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null)
	local suid_count
	suid_count=$(echo "$suid_sgid" | sed '/^$/d' | wc -l)
	echo "Total SUID/SGID files found: $suid_count"

	if [[ $suid_count -gt 50 ]]; then
		print_warning "High number of SUID/SGID files - review recommendations."
		((issues++))
	else
		print_success "SUID/SGID files count within acceptable range."
	fi

	# Check 3: SSH Configuration
	print_section "Check: SSH Security"

	if [[ -f /etc/ssh/sshd_config ]]; then
		if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
			print_error "Root login via SSH is ENABLED (security risk)."
			((issues++))
		else
			print_success "Root login via SSH is disabled"
		fi

		if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
			print_warning "Password Authentication is enabled (consider key based authentication)."
			((issues++))
		else
			print_success "Password Authentication is disabled"
		fi
	else
		print_info "SSH not configured on this system."
	fi

	# Check 4: Firewall Status
	print_section "Check: Firewall Status"
	
	if systemctl is-active --quiet firewalld; then
		print_success "Firewalld is active and running"
	elif systemctl is-active --quiet iptables; then
		print_success "Iptables is active and running"
	else
		print_error "No firewall is active and running"
		((issues++))
	fi

	# Check 5: SELinux Status
	print_section "Check: SELinux Status"

	if command -v getenforce &> /dev/null; then
	local selinux_status
	selinux_status=$(getenforce)

		case "$selinux_status" in
			Enforcing)
				print_success "SELinux is Enforcing mode"
				;;
			Permissive)
				print_warning "SELinux is in Permissive mode (logs but doesn't block)."
				((issues++))
				;;
			Disabled)
				print_error "SELinux is disabled (security risk)."
				((issues++))
				;;
		esac
	else
		print_info "SELinux not available on this system."
	fi

	# Summary
	print_section "Security Scan Summary"
	if [[ $issues -eq 0 ]]; then
		print_success "No critical security issues detected."
	else
		print_error "Found $issues security issue(s) requiring attention."
	fi

	log_info "Security Scan completed with $issues issue(s)."
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	security_scan
fi

#!/bin/bash

##################################################################################
# TechCorp Ltd. - Linux System Administration Toolkit
# Purpose: Comprehensive system audit and administration tool
# Author: samiulAsumel
###################################################################################

set -eou pipefail # Exit on error, undefined variable, or pipeline error

# Script directory (works from anywhere)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utilities
source "$SCRIPT_DIR/../utils/logger.sh"
source "$SCRIPT_DIR/../utils/colors.sh"

# Configuration
REPORT_DIR="$SCRIPT_DIR/../data/reports"
LOG_FILE="$SCRIPT_DIR/../logs/sysadmin-toolkit.log"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_FILE="$REPORT_DIR/sysadmin-report-$TIMESTAMP.txt"

# Ensure directories exist
mkdir -p "$REPORT_DIR" "$SCRIPT_DIR/../logs"

###################################################################################
# Function: Display usage information
usage() {
	cat << EOF
${BOLD}TechCorp Linux System Administration Toolkit${RESET}

${BOLD}Usage:${RESET}
	$0 [options] [command]

${BOLD}COMMANDS:${RESET}
	info        - Display system information
	audit       - Run user and permission audit
	security    - Perform security compliance scan
	full        - Run complete system analysis (default)
	report      - Generate comprehensive report

${BOLD}OPTIONS:${RESET}
	-h, --help      Show this help message
	-v, --version   Display version information
	-o, --output    Specify custom report filename

${BOLD}EXAMPLES:${RESET}
	$0 full                     # Run full system audit
	$0 security                 # Security scan only
	$0 -o custom_report.txt     # Custom report filename

${BOLD}REPORT LOCATION:${RESET}
	Reports saved to: $REPORT_DIR/

EOF
	exit 0
}

###################################################################################
# Function: Display version information
version() {
	echo "TechCorp Linux System Administration Toolkit - Version 2.1.0"
	exit 0
}

###################################################################################
# Function: Run full system analysis
run_full_analysis() {
	print_header "TechCorp System Administration Toolkit"

	log_info "Starting full system audit..."

	# Execute modules
	source "$SCRIPT_DIR/../modules/system-info.sh" && collect_system_info
	echo

	source "$SCRIPT_DIR/../modules/user-audit.sh" && audit_users
	echo

	source "$SCRIPT_DIR/../modules/security-check.sh" && security_scan
	echo

	log_info "Full audit completed successfully."
}

###################################################################################
# Function: Generate comprehensive report
generate_report() {
	print_header "TechCorp System Administration Report"

	log_info "Creating comprehensive report...: $REPORT_FILE"

	{
		echo "==============================================="
		echo "TechCorp Linux System Administration Report"
		echo "==============================================="
		echo ""
		echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
		echo "Hostname: $(hostname)"
		echo "Report ID: $TIMESTAMP"
		echo ""
		echo "==============================================="
		echo ""

		# Run all checks and capture output
		bash "$SCRIPT_DIR/../modules/system-info.sh" 2>&1
		echo
		bash "$SCRIPT_DIR/../modules/user-audit.sh" 2>&1
		echo
		bash "$SCRIPT_DIR/../modules/security-check.sh" 2>&1
		echo
		echo "==============================================="
		echo "End of Report"
		echo "==============================================="
	} > "$REPORT_FILE"

	print_success "Report generated successfully: $REPORT_FILE"
	log_info "Report saved successfully."
}

####################################################################################
# Main script logic
main() {
	# Check if running with sufficient privileges for security checks
	if [[ $EUID -ne 0 ]]; then
		print_warning "Some checks require root privileges. Run with sudo for full audit."
	fi

	# Parse command line arguments
	case "${1:-full}" in
		info)
			source "$SCRIPT_DIR/../modules/system-info.sh" && collect_system_info
			;;
		audit)
			source "$SCRIPT_DIR/../modules/user-audit.sh" && audit_users
			;;
		security)
			source "$SCRIPT_DIR/../modules/security-check.sh" && security_scan
			;;
		full)
			run_full_analysis
			;;
		report)
			generate_report
			;;
		-h|--help)
			usage
			;;
		-v|--version)
			version
			;;
		*)
			print_error "Invalid command: $1"
			usage
			;;
	esac

	print_info "Check logs at: $LOG_FILE"
}

# Execute main function
main "$@"
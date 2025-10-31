#!/bin/bash

# Logging Utility for System Administration Toolkit
# Provides standardized logging with timestamps and levels
# Author: samiulAsumel

# Default file (can be overridden by exporting LOG_FILE)
LOG_FILE="${LOG_FILE:-/var/log/sysadmin-toolkit.log}"
# Default log level: DEBUG, INFO, WARN, ERROR
LOG_LEVEL="${LOG_LEVEL:-INFO}"

# Ensure log directory exists; if we can't create it (permission), fall back to /tmp
LOG_DIR=$(dirname "$LOG_FILE")
if [[ ! -d "$LOG_DIR" ]]; then
	if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
		LOG_FILE="/tmp/sysadmin-toolkit.log"
		LOG_DIR=$(dirname "$LOG_FILE")
	fi
fi

# Function: Write log entry
# Usage: log_message "LEVEL" "MESSAGE..."
log_message() {
	local level="$1"
	shift
	local message="$*"
	local timestamp
	timestamp=$(date '+%Y-%m-%d %H:%M:%S')

	# Numeric priorities for filtering
	local -i lvl_num=0 cfg_num=0
	case "$level" in
		DEBUG) lvl_num=10 ;;
		INFO)  lvl_num=20 ;;
		WARN)  lvl_num=30 ;;
		ERROR) lvl_num=40 ;;
		*)     lvl_num=20 ;;
	esac
	case "$LOG_LEVEL" in
		DEBUG) cfg_num=10 ;;
		INFO)  cfg_num=20 ;;
		WARN)  cfg_num=30 ;;
		ERROR) cfg_num=40 ;;
		*)     cfg_num=20 ;;
	esac

	# Drop messages below configured level
	if (( lvl_num < cfg_num )); then
		return 0
	fi

	# Form entry and append to file
	local entry
	entry="[$timestamp] [$level] $message"
	printf '%s\n' "$entry" >>"$LOG_FILE" 2>/dev/null || true

	# TTY-aware colored output for humans
	if [[ -t 1 ]]; then
		case "$level" in
			ERROR)
				printf '\033[31m[ERROR] %s\033[0m\n' "$message"
				;;
			WARN)
				printf '\033[33m[WARN] %s\033[0m\n' "$message"
				;;
			INFO)
				printf '\033[32m[INFO] %s\033[0m\n' "$message"
				;;
			DEBUG)
				printf '\033[34m[DEBUG] %s\033[0m\n' "$message"
				;;
			*)
				printf '%s\n' "$message"
				;;
		esac
	else
		# Non-interactive: print plain entry (useful for CI/container logs)
		printf '%s\n' "$entry"
	fi

	return 0
}

# Convenience wrapper functions (forward all args so multi-word messages work)
log_info()  { log_message "INFO" "$@"; }
log_warn()  { log_message "WARN" "$@"; }
log_error() { log_message "ERROR" "$@"; }
log_debug() { log_message "DEBUG" "$@"; }

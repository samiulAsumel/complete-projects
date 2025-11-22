#!/bin/bash

################################################
# System Health Monitor - TechCorp Ltd.
# Purpose: Monitor CPU, Memory, Disk and generate alerts
# Author: samiulAsumel
################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Load configuration
CONFIG_FILE="/opt/system-health-monitor/config/monitor.conf"
if [[ -f "$CONFIG_FILE" ]]; then
	source "$CONFIG_FILE"
else
	echo "Configuration file not found"
	exit 1
fi

# Set up paths
LOG_DIR="/opt/system-health-monitor/logs"
REPORT_DIR="/opt/system-health-monitor/reports"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="$LOG_DIR/health-$(date +%Y-%m-%d).log"
REPORT_FILE="$REPORT_DIR/health-report-$(date +%Y-%m-%d_%H-%M-%S).html"

# Create directories if they don't exist
mkdir -p "$LOG_DIR" "$REPORT_DIR"

##############################################
# Function: Log messages
##############################################
log_message() {
	echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

##############################################
# Function: Get CPU usage
##############################################
get_cpu_usage() {
	# Calculate CPU usage percentage
	cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
	echo "${cpu_usage%.*}" # Remove decimal for comparison
}

##############################################
# Function: Get Memory usage
##############################################
get_memory_usage() {
	# Calculate Memory usage percentage
	memory_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
	echo "$memory_usage"
}

##############################################
# Function: Get Disk usage
##############################################
get_disk_usage() {
	# Get root partition usage
	disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
	echo "$disk_usage"
}

##############################################
# Function: Get load average
##############################################
get_load_average() {
	# Get 5-minute load average
	load_average=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $2}' | xargs)
	echo "$load_average"
}

##############################################
# Function: Get System info
##############################################
get_system_info() {
	# Get system information
	HOSTNAME=$(hostname)
	UPTIME=$(uptime -p)
	KERNEL=$(uname -r)
	OS_VERSION=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
}

##############################################
# Function: Check if metric exceeds threshold
##############################################
check_threshold() {
	local metric_name=$1
	local current_value=$2
	local threshold=$3
	local status="OK"
	local color=$GREEN

	# Compare values (handle decimals with bc)
	if (( $(echo "$current_value > $threshold" | bc -l) )); then
		status="WARNING"
		color="$RED"
		log_message "${metric_name} usage is high: ${current_value}% (Threshold: ${threshold}%)"
	fi

	echo -e "${color}${status}${NC}"
}

##############################################
# Function: Monitor multiple partitions
##############################################
check_all_disks() {
	df -h | grep -vE '^Filesystem|tmpfs|cdrom' | while read -r line; do
		usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
		mount=$(echo "$line" | awk '{print $6}')
		
		if [ "$usage" -gt "$DISK_THRESHOLD" ]; then
			log_message "WARNING: $mount is ${usage}% full!"
		fi
	done
}

##############################################
# Function: Check critical services
##############################################
check_critical_services() {
	SERVICES=("sshd" "httpd" "mysqld" "docker")
	
	for service in "${SERVICES[@]}"; do
		if ! systemctl is-active --quiet "$service"; then
			log_message "CRITICAL: $service is not running!"
			# Auto-restart service
			sudo systemctl restart "$service"
			log_message "Attempted to restart $service"
		fi
	done
}

##############################################
# Function: Check internet connectivity
##############################################
check_network() {
	if ! ping -c 1 8.8.8.8 &> /dev/null; then
		log_message "WARNING: Network connectivity issue detected!"
	fi
}

##############################################
# Function: Generate HTML report
##############################################
generate_html_report() {
	cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html>
<head>
	<title>System Health Report - $(hostname)</title>
	<style>
		body { font-family: Arial, sans-serif; margin: 20px; background: #f4f4f4; }
		.container { max-width: 900px; margin: auto; background: white; padding: 20px; 
		             border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
		h1 { color: #333; border-bottom: 3px solid #4CAF50; padding-bottom: 10px; }
		.metric { display: flex; justify-content: space-between; padding: 15px; 
		          margin: 10px 0; border-left: 4px solid #4CAF50; background: #f9f9f9; }
		.warning { border-left-color: #ff9800; background: #fff3e0; }
		.critical { border-left-color: #f44336; background: #ffebee; }
		.status { font-weight: bold; padding: 5px 10px; border-radius: 4px; }
		.ok { background: #4CAF50; color: white; }
		.warn { background: #ff9800; color: white; }
		table { width: 100%; border-collapse: collapse; margin: 20px 0; }
		th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
		th { background: #4CAF50; color: white; }
		.footer { margin-top: 20px; text-align: center; color: #666; font-size: 12px; }
	</style>
</head>
<body>
	<div class="container">
		<h1>System Health Report</h1>
		<p><strong>Server:</strong> $(hostname)</p>
		<p><strong>Generated:</strong> $TIMESTAMP</p>
		<p><strong>Uptime:</strong> $(uptime -p)</p>
		<p><strong>OS:</strong> $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)</p>
		
		<h2>Current Metrics</h2>
		
		<div class="metric $([ $1 -gt $CPU_THRESHOLD ] && echo 'critical' || echo '')">
			<div><strong>CPU Usage:</strong> ${1}%</div>
			<div class="status $([ $1 -gt $CPU_THRESHOLD ] && echo 'warn' || echo 'ok')">
				$([ $1 -gt $CPU_THRESHOLD ] && echo 'WARNING' || echo 'OK')
			</div>
		</div>
		
		<div class="metric $([ $2 -gt $MEMORY_THRESHOLD ] && echo 'critical' || echo '')">
			<div><strong>Memory Usage:</strong> ${2}%</div>
			<div class="status $([ $2 -gt $MEMORY_THRESHOLD ] && echo 'warn' || echo 'ok')">
				$([ $2 -gt $MEMORY_THRESHOLD ] && echo 'WARNING' || echo 'OK')
			</div>
		</div>
		
		<div class="metric $([ $3 -gt $DISK_THRESHOLD ] && echo 'critical' || echo '')">
			<div><strong>Disk Usage (/):</strong> ${3}%</div>
			<div class="status $([ $3 -gt $DISK_THRESHOLD ] && echo 'warn' || echo 'ok')">
				$([ $3 -gt $DISK_THRESHOLD ] && echo 'WARNING' || echo 'OK')
			</div>
		</div>
		
		<div class="metric">
			<div><strong>Load Average (5-min):</strong> ${4}</div>
			<div class="status ok">OK</div>
		</div>
		
		<h2>Disk Usage Details</h2>
		<table>
			<tr>
				<th>Filesystem</th>
				<th>Size</th>
				<th>Used</th>
				<th>Available</th>
				<th>Use%</th>
				<th>Mounted On</th>
			</tr>
$(df -h | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"</td><td>"$4"</td><td>"$5"</td><td>"$6"</td></tr>"}')
		</table>
		
		<h2>Top 5 CPU Processes</h2>
		<table>
			<tr>
				<th>User</th>
				<th>PID</th>
				<th>CPU%</th>
				<th>MEM%</th>
				<th>Command</th>
			</tr>
$(ps aux --sort=-%cpu | head -6 | tail -5 | awk '{print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"%</td><td>"$4"%</td><td>"$11"</td></tr>"}')
		</table>
		
		<h2>Top 5 Memory Processes</h2>
		<table>
			<tr>
				<th>User</th>
				<th>PID</th>
				<th>CPU%</th>
				<th>MEM%</th>
				<th>Command</th>
			</tr>
$(ps aux --sort=-%mem | head -6 | tail -5 | awk '{print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"%</td><td>"$4"%</td><td>"$11"</td></tr>"}')
		</table>
		
		<div class="footer">
			<p>TechCorp Ltd. - DevOps Team | Automated System Health Monitor v1.0</p>
		</div>
	</div>
</body>
</html>
EOF

	echo "HTML Report generated: $REPORT_FILE"
}

###############################################
# Main script execution
###############################################
echo -e "${GREEN}Starting System Health Check...${NC}"
echo -e "TechCorp Ltd. - DevOps Team"
echo -e "Automated System Health Monitor"

# Get system information
get_system_info

# Collect metrics
CPU_USAGE=$(get_cpu_usage)
MEMORY_USAGE=$(get_memory_usage)
DISK_USAGE=$(get_disk_usage)
LOAD_AVERAGE=$(get_load_average)

# Display metrics on console
echo -e "Server: ${GREEN}$HOSTNAME${NC}"
echo -e "Time: ${GREEN}$TIMESTAMP${NC}"
echo -e "OS: ${GREEN}$OS_VERSION${NC}"
echo -e "Uptime: ${GREEN}$UPTIME${NC}"

echo ""

echo -e "Current Metrics:"
echo -e "CPU Usage: $(check_threshold "CPU" "$CPU_USAGE" "$CPU_THRESHOLD") - ${YELLOW}${CPU_USAGE}%${NC}"
echo -e "Memory Usage: $(check_threshold "Memory" "$MEMORY_USAGE" "$MEMORY_THRESHOLD") - ${YELLOW}${MEMORY_USAGE}%${NC}"
echo -e "Disk Usage (/): $(check_threshold "Disk" "$DISK_USAGE" "$DISK_THRESHOLD") - ${YELLOW}${DISK_USAGE}%${NC}"
echo -e "Load Average (5-min): ${YELLOW}${LOAD_AVERAGE}${NC}"

# Log Metrics
log_message "CPU: ${CPU_USAGE}%, Memory: ${MEMORY_USAGE}%, Disk: ${DISK_USAGE}%, Load Avg (5-min): ${LOAD_AVERAGE}"

# Additional checks
check_all_disks
check_critical_services
check_network

# Generate HTML report
if [[ "$GENERATE_HTML_REPORT" == "yes" ]]; then
	generate_html_report "$CPU_USAGE" "$MEMORY_USAGE" "$DISK_USAGE" "$LOAD_AVERAGE"
fi

# Send alert if any metric exceeds threshold
if (( CPU_USAGE > CPU_THRESHOLD )) || (( MEMORY_USAGE > MEMORY_THRESHOLD )) || (( DISK_USAGE > DISK_THRESHOLD )); then
	ALERT_MSG="Server: $HOSTNAME
Time: $TIMESTAMP
CPU Usage: ${CPU_USAGE}%
Memory Usage: ${MEMORY_USAGE}%
Disk Usage: ${DISK_USAGE}%
Load Average (5-min): ${LOAD_AVERAGE}"

	if [[ -x "/opt/system-health-monitor/bin/send-alert.sh" ]]; then
		/opt/system-health-monitor/bin/send-alert.sh "$ALERT_MSG"
	fi
fi

# Clean up old logs (keep last 30 days)
find "$LOG_DIR" -name "health-*.log" -type f -mtime +$KEEP_LOG_DAYS -delete
find "$REPORT_DIR" -name "health-report-*.html" -type f -mtime +$KEEP_LOG_DAYS -delete

echo -e "${GREEN}System Health Check Completed.${NC}"
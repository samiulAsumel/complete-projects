#!/bin/bash

##############################################
# Central Report Aggregation Script
# Purpose: Collect reports from all servers
# Author: samiulAsumel
##############################################

SERVERS=(
    "dev-web:192.168.56.10"
    "stage-db:192.168.56.11"
    "prod-web:192.168.56.12"
    "cicd-jenkins:192.168.56.13"
)

SSH_USER="devops"
CENTRAL_REPORT_DIR="/opt/system-health-monitor/central-reports"
DATE="$(date +%Y-%m-%d)"

mkdir -p "$CENTRAL_REPORT_DIR/$DATE"

echo "Collecting reports from all servers..."

for server_info in "${SERVERS[@]}"; do
	SERVER_NAME=$(echo "$server_info" | cut -d: -f1)
	SERVER_IP=$(echo "$server_info" | cut -d: -f2)

	echo "Fatching report from $SERVER_NAME ($SERVER_IP)..."

	# Copy latest report
	scp -i "$SSH_KEY" $SSH_USER@"$SERVER_IP":/opt/system-health-monitor/reports/* $CENTRAL_REPORT_DIR/"$DATE"/ >/dev/null 2>&1

	if [ $? -eq 0 ]; then
		echo "Retrieved $SERVER_NAME report."
	else
		echo "NO report found for $SERVER_NAME."
	fi
done

# Generate master dashboard
cat > "$CENTRAL_REPORT_DIR/$DATE/dashboard.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>TechCorp Infrastructure Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #1e1e1e; color: #fff; }
        .container { max-width: 1200px; margin: auto; }
        h1 { color: #4CAF50; text-align: center; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }
        .server-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 20px 0; }
        .server-card { background: #2d2d2d; padding: 20px; border-radius: 8px; border: 2px solid #444; }
        .server-card h3 { margin-top: 0; color: #4CAF50; }
        .server-card a { color: #2196F3; text-decoration: none; display: block; margin: 10px 0; }
        .server-card a:hover { text-decoration: underline; }
        .timestamp { text-align: center; color: #888; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>TechCorp Infrastructure Dashboard</h1>
        <p class="timestamp">Generated: $(date '+%Y-%m-%d %H:%M:%S')</p>
        
        <div class="server-grid">
EOF

# Add server cards
for server_info in "${SERVERS[@]}"; do
	SERVER_NAME=$(echo "$server_info" | cut -d: -f1)
	SERVER_IP=$(echo "$server_info" | cut -d: -f2)

	cat >> "$CENTRAL_REPORT_DIR/$DATE/dashboard.html" << EOF
            <div class="server-card">
                <h3>$SERVER_NAME</h3>
                <p><strong>IP:</strong> $SERVER_IP</p>
                <a href="$SERVER_NAME-report.html" target="_blank">📊 View Health Report</a>
            </div>
EOF
done

# Close HTML
cat >> "$CENTRAL_REPORT_DIR/$DATE/dashboard.html" << 'EOF'
        </div>
        
        <div style="text-align: center; margin-top: 40px; color: #666; font-size: 14px;">
            <p>TechCorp Ltd. DevOps Team | Automated Infrastructure Monitoring</p>
        </div>
    </div>
</body>
</html>
EOF

echo ""
echo "Dashboard generated: $CENTRAL_REPORT_DIR/$DATE/dashboard.html"
echo "Open in browser to view all server reports"
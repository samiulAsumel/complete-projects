#!/bin/bash
#############################################################################
# Weekly Summary Report Generator
#############################################################################

REPORT_FILE="/opt/system-health-monitor/reports/weekly-summary-$(date '+%Y-W%V').txt"

cat > "$REPORT_FILE" << EOF
========================================
TechCorp Infrastructure Weekly Summary
Week: $(date '+%Y-W%V')
Period: $(date -d '7 days ago' '+%Y-%m-%d') to $(date '+%Y-%m-%d')
========================================

SERVER STATISTICS
-----------------
EOF

# Get metrics from last week's logs
LOG_DIR="/opt/system-health-monitor/logs"

for days_ago in {0..6}; do
    log_date=$(date -d "$days_ago days ago" '+%Y-%m-%d')
    log_file="$LOG_DIR/health-$log_date.log"
    
    if [ -f "$log_file" ]; then
        echo "" >> "$REPORT_FILE"
        echo "Date: $log_date" >> "$REPORT_FILE"
        echo "---" >> "$REPORT_FILE"
        
        # Calculate averages
        avg_cpu=$(grep "CPU:" "$log_file" | awk -F'CPU: |%' '{sum+=$2; count++} END {printf "%.1f", sum/count}')
        avg_mem=$(grep "Memory:" "$log_file" | awk -F'Memory: |%' '{sum+=$2; count++} END {printf "%.1f", sum/count}')
        avg_disk=$(grep "Disk:" "$log_file" | awk -F'Disk: |%' '{sum+=$2; count++} END {printf "%.1f", sum/count}')
        
        echo "  Avg CPU: ${avg_cpu}%" >> "$REPORT_FILE"
        echo "  Avg Memory: ${avg_mem}%" >> "$REPORT_FILE"
        echo "  Avg Disk: ${avg_disk}%" >> "$REPORT_FILE"
        
        # Count alerts
        alert_count=$(grep -c "ALERT" "$log_file" 2>/dev/null || echo "0")
        echo "  Alerts: $alert_count" >> "$REPORT_FILE"
    fi
done

cat >> "$REPORT_FILE" << EOF

RECOMMENDATIONS
---------------
EOF

# Analyze trends and add recommendations
total_alerts=$(grep -c "ALERT" $LOG_DIR/health-*.log 2>/dev/null || echo "0")

if [ "$total_alerts" -gt 10 ]; then
    echo "⚠️  High alert volume detected. Review thresholds and capacity." >> "$REPORT_FILE"
else
    echo "✅ System performance within acceptable parameters." >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"
echo "Report generated: $(date)" >> "$REPORT_FILE"
echo "========================================" >> "$REPORT_FILE"

echo "📊 Weekly summary generated: $REPORT_FILE"

# Email the report
if command -v mail &> /dev/null; then
    mail -s "TechCorp Weekly Infrastructure Summary" devops@techcorp.com < "$REPORT_FILE"
fi
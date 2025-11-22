#!/bin/bash

# Email Alert Script
ALERT_EMAIL="your_email@example.com"
HOSTNAME=$(hostname)
SUBJECT="System Health Alert on $HOSTNAME"
BODY="Attention,\n\nA system health issue has been detected on $HOSTNAME. Please check the system immediately.\n\nRegards,\nSystem Health Monitor"

# Read alert message from argument
MESSAGE="$1"
echo "$MESSAGE" | mail -s "$SUBJECT" "$ALERT_EMAIL" <<< "$BODY"

# Log alert 
echo "[$(date)] Alert sent to $ALERT_EMAIL: $MESSAGE" >> /var/log/system_health_monitor/alerts.log
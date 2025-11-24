# TechCorp System Health Monitor

## Overview

Automated monitoring solution for TechCorp infrastructure that tracks CPU, memory,
disk usage, and system load across all environments.

## Architecture

```
/opt/system-health-monitor/
├── bin/
│   ├── health_check.sh          # Main monitoring script
│   ├── send_alert.sh            # Email alerting
│   ├── deploy_monitor.sh        # Deployment automation
│   └── aggregate_reports.sh     # Report collection
├── config/
│   └── monitor.conf             # Configuration file
├── logs/
│   └── health-YYYY-MM-DD.log    # Daily logs
└── reports/
    └── health-report-*.html     # HTML reports
```

## Installation

### Prerequisites

- Rocky Linux 9 / AlmaLinux 9 / RHEL 9
- Root or sudo access
- Mail utilities (optional, for alerts)

### Quick Start

```bash
# Clone or extract to /opt
sudo mkdir -p /opt/system-health-monitor

# Set permissions
sudo chmod +x /opt/system-health-monitor/bin/*.sh

# Edit configuration
sudo nano /opt/system-health-monitor/config/monitor.conf

# Test run
sudo /opt/system-health-monitor/bin/health_check.sh

# Set up cron
echo "*/15 * * * * /opt/system-health-monitor/bin/health_check.sh" | sudo crontab -
```

## Configuration

Edit `/opt/system-health-monitor/config/monitor.conf`:

| Parameter        | Default | Description                      |
| ---------------- | ------- | -------------------------------- |
| CPU_THRESHOLD    | 80      | CPU usage alert threshold (%)    |
| MEMORY_THRESHOLD | 85      | Memory usage alert threshold (%) |
| DISK_THRESHOLD   | 90      | Disk usage alert threshold (%)   |
| LOAD_THRESHOLD   | 4.0     | Load average threshold           |
| KEEP_LOGS_DAYS   | 30      | Log retention period             |

## Usage

### Manual Execution

```bash
sudo /opt/system-health-monitor/bin/health_check.sh
```

### View Reports

```bash
# Latest HTML report
ls -lt /opt/system-health-monitor/reports/ | head -2

# Today's logs
tail -f /opt/system-health-monitor/logs/health-$(date '+%Y-%m-%d').log
```

### Deploy to Multiple Servers

```bash
sudo /opt/system-health-monitor/bin/deploy_monitor.sh
```

## Troubleshooting

### Script doesn't run

- Check permissions: `ls -l /opt/system-health-monitor/bin/*.sh`
- Verify shebang: `head -1 /opt/system-health-monitor/bin/health_check.sh`

### Cron job not working

- Check cron service: `sudo systemctl status crond`
- View cron logs: `sudo tail -f /var/log/cron`
- Test script manually first

### No email alerts

- Install mailx: `sudo dnf install -y mailx`
- Check postfix: `sudo systemctl status postfix`
- Test: `echo "test" | mail -s "test" user@example.com`

## Maintenance

### Log Rotation

Automatic cleanup configured in script. Manual cleanup:

```bash
find /opt/system-health-monitor/logs -type f -mtime +30 -delete
```

### Update Thresholds

```bash
sudo nano /opt/system-health-monitor/config/monitor.conf
# No restart needed - changes apply on next execution
```

## Support

Contact: DevOps Team <devops@techcorp.com>
Documentation: /opt/system-health-monitor/README.md

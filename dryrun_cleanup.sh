#!/bin/bash
echo '=== total size of *.log older than 14 days (dry run) ==='
find /root/home/lmk /root/home/bimadline -name '*.log' -mtime +14 2>/dev/null | wc -l
find /root/home/lmk /root/home/bimadline -name '*.log' -mtime +14 -printf '%s\n' 2>/dev/null | awk '{s+=$1} END {printf "%.1f GB\n", s/1024/1024/1024}'
echo '=== biggest log files ==='
find /root/home/lmk /root/home/bimadline -name '*.log' -mtime +14 -printf '%s %p\n' 2>/dev/null | sort -rn | head -12
echo '=== logs older than 14 days in insurance dirs (ours, safe) ==='
find /root/home/insurancePlatform -name '*.log' -mtime +3 2>/dev/null | head
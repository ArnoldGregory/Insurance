#!/bin/bash
sudo -n sh -c "find /root/home/lmk /root/home/bimadline -name '*.log' -mtime +14 -delete" 2>/dev/null || echo 'Master@1' | sudo -S sh -c "find /root/home/lmk /root/home/bimadline -name '*.log' -mtime +14 -delete" 2>/dev/null
df -h / | tail -1
echo '--- log dir sizes now ---'
du -sh /root/home/lmk/*/logs /root/home/bimadline/*/logs 2>/dev/null | sort -rh | head
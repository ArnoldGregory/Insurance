#!/bin/bash
echo '=== procedures ==='
mysql -u esbuser -p'@M@kurun!m3z@' insurance_platform -N -e "SHOW PROCEDURE STATUS WHERE Db='insurance_platform'" 2>/dev/null | awk '{print $1}' | sort | grep -i login
echo '=== lmk/server top ==='
du -sh /root/home/lmk/server/* 2>/dev/null | sort -rh | head -8
echo '=== lmk/emails sample ==='
ls /root/home/lmk/emails 2>/dev/null | head -5
echo '=== lmk/sms sample ==='
ls /root/home/lmk/sms 2>/dev/null | head -5
echo '=== big files ==='
find /root/home/lmk /root/home/bimadline -maxdepth 3 \( -name '*.log' -o -name '*.tar*' -o -name '*.zip' -o -name 'core*' -o -name '*.gz' -o -name '*.txt' \) -size +50M 2>/dev/null | head -20
echo '=== bimadline purchaseinsuranseservice ==='
du -sh /root/home/bimadline/purchaseinsuranseservice/* 2>/dev/null | sort -rh | head -8
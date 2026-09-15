#!/bin/bash
mysql -u esbuser -p'@M@kurun!m3z@' insurance_platform -e "SHOW PROCEDURE STATUS WHERE Db='insurance_platform' AND Name LIKE '%Purchase%';"

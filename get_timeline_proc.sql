#!/bin/bash
mysql -u esbuser -p'@M@kurun!m3z@' insurance_platform -e "SHOW CREATE PROCEDURE usp_Purchase_GetTimeline;" 2>/dev/null | tail -n +2
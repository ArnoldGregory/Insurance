#!/bin/bash
mysql -u esbuser -p'@M@kurun!m3z@' insurance_platform << 'EOF'
SET @rc = 0;
SET @rm = '';
CALL usp_Purchase_GetTimeline(11, @rc, @rm);
SELECT @rc AS result_code, @rm AS result_message;
EOF

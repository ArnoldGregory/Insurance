#!/bin/bash
mysql -u esbuser -p'@M@kurun!m3z@' insurance_platform << 'EOF'
SHOW TABLES LIKE '%cert%';
SHOW TABLES LIKE '%Cover%';
SHOW TABLES LIKE '%Document%';
SELECT purchase_id, policy_number, payment_status, status FROM Purchases ORDER BY purchase_id DESC LIMIT 12;
SELECT purchase_id, COUNT(*) AS payments, SUM(status='SUCCESS') AS success FROM Payments GROUP BY purchase_id ORDER BY purchase_id DESC LIMIT 12;
EOF
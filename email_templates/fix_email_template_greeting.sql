USE scapi;

-- Fixes a duplicate-greeting bug in 2 templates. The C# code's `body_text`
-- value already starts with "Hi {name}, ..." (see QuoteNotificationSender.cs),
-- but the template ALSO had its own separate "Hi {{customer_name}}," line
-- right above it - so the email showed the greeting twice
-- ("Hi Dancan Michira, Hi Dancan Michira, here are the offers...").
-- This removes the template's own greeting line and keeps only body_text.
-- Does not touch EMAIL_QUOTE_NEW_STAFF_NOTIFY - that one never had this bug.

UPDATE email_templates
SET template = REPLACE(template, '<p>Hi {{customer_name}},</p>\n      <p>{{body_text}}</p>', '<p>{{body_text}}</p>')
WHERE request_type IN ('EMAIL_QUOTE_RECEIVED_CLIENT', 'EMAIL_QUOTE_OFFERS_COMPARISON');

-- Verify: should return 0 rows left containing the old duplicate-greeting pattern.
SELECT id, request_type
FROM email_templates
WHERE request_type IN ('EMAIL_QUOTE_RECEIVED_CLIENT', 'EMAIL_QUOTE_OFFERS_COMPARISON')
  AND template LIKE '%Hi {{customer_name}},</p>%<p>{{body_text}}%';

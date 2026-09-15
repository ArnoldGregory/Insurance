USE scapi;

-- EMAIL_QUOTE_OFFERS_COMPARISON's live email_template_parameters rows still
-- had a param named 'attachments' (plural, param_order 7) - a leftover from
-- when QuoteNotificationSender.cs used to send a base64 array under that
-- name. Scapi's Worker.cs never read it for anything (it only ever opens a
-- file path off the singular 'attachment' field), and QuoteNotificationSender.cs
-- no longer sends 'attachments' at all - so Scapi's own param lookup for
-- 'attachments' now finds nothing in the payload and throws ("Object
-- reference not set to an instance of an object", right after it logs
-- param_order 7 in the request log).
--
-- This removes that leftover row and renumbers the two params that came
-- after it (attachment, logo) so param_order stays contiguous.

SET @template_id = (SELECT id FROM email_templates WHERE request_type = 'EMAIL_QUOTE_OFFERS_COMPARISON');

DELETE FROM email_template_parameters
WHERE email_template_id = @template_id AND param_name = 'attachments';

UPDATE email_template_parameters
SET param_order = 7
WHERE email_template_id = @template_id AND param_name = 'attachment';

UPDATE email_template_parameters
SET param_order = 8
WHERE email_template_id = @template_id AND param_name = 'logo';

-- Verify: should return exactly 8 rows, ending ...6 body_text, 7 attachment, 8 logo.
SELECT param_order, param_name
FROM email_template_parameters
WHERE email_template_id = @template_id
ORDER BY param_order;

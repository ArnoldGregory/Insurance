USE scapi;

-- Fixes the NullReferenceException seen in the Scapi log for
-- EMAIL_QUOTE_NEW_STAFF_NOTIFY (template id 93). Root cause: the `logo`
-- column on these 3 rows was set to a placeholder file path that doesn't
-- exist on the Scapi server. This points it at the dedicated Insurance
-- Platform logo file - make sure this exact file has actually been deployed
-- to that path on the Scapi server before running this, otherwise it will
-- just reproduce the same NullReferenceException with a different path.
--
-- Plain MySQL syntax - the previous version of this file used SQL Server
-- syntax ([dbo].[table], GO, N'...') copied from a seed file that turned out
-- to be from a different (SQL Server) deployment. This `scapi` database, per
-- the query tool screenshot, is MySQL - no brackets, no GO, no N-prefix needed.

UPDATE email_templates
SET logo = '/root/home/insuranceplatform/logo/insurance-platform-logo.png'
WHERE request_type IN ('EMAIL_QUOTE_RECEIVED_CLIENT', 'EMAIL_QUOTE_NEW_STAFF_NOTIFY', 'EMAIL_QUOTE_OFFERS_COMPARISON');

SELECT id, request_type, logo FROM email_templates
WHERE request_type IN ('EMAIL_QUOTE_RECEIVED_CLIENT', 'EMAIL_QUOTE_NEW_STAFF_NOTIFY', 'EMAIL_QUOTE_OFFERS_COMPARISON');

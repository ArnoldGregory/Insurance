-- =====================================================================
-- Insurance Platform - new email templates (scapi database, MySQL)
-- -----------------------------------------------------------------------
-- NOTE: these rows already exist in production (template ids 92-94, per
-- the Scapi log dated 2026-08-18 and the fix confirmed against the live
-- `scapi` database). Do NOT re-run this - it will create duplicates. This
-- file is kept only as an accurate record of the final, working inserts
-- (table name email_template_parameters, MySQL syntax, scapi database,
-- real logo path) - a corrected version of the first draft, which had a
-- wrong table name, a fake logo path, and (briefly, in one revision) the
-- wrong SQL dialect entirely.
-- =====================================================================

USE scapi;

-- ---- EMAIL_QUOTE_RECEIVED_CLIENT ----
INSERT INTO email_templates (request_type, template, comments, created_on, created_by, logo)
VALUES ('EMAIL_QUOTE_RECEIVED_CLIENT', '<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>{{subject}}</title>
<style>
* { margin:0; padding:0; box-sizing:border-box; }

body {
  font-family: ''Segoe UI'', Arial, sans-serif;
  background: #f0f4f8;
  color: #1a202c;
}

.wrapper {
  max-width: 620px;
  margin: 40px auto;
  background: #ffffff;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 2px 10px rgba(0,0,0,0.06);
}

.header {
  background: #115636;
  padding: 28px 32px;
  text-align: center;
}

.header img {
  max-height: 46px;
}

.banner {
  background: #0d3f28;
  color: #ffffff;
  padding: 14px 32px;
  font-size: 15px;
  font-weight: 600;
  letter-spacing: 0.3px;
}

.content {
  padding: 32px;
}

.content p {
  font-size: 15px;
  line-height: 1.6;
  color: #33424f;
  margin-bottom: 16px;
}

.details-box {
  background: #f4f9f6;
  border: 1px solid #d9ece2;
  border-radius: 10px;
  padding: 18px 20px;
  margin: 20px 0;
}

.details-box table {
  width: 100%;
  border-collapse: collapse;
}

.details-box td {
  padding: 6px 0;
  font-size: 14px;
}

.details-box td.label {
  color: #5a6b78;
  width: 140px;
}

.details-box td.value {
  color: #115636;
  font-weight: 600;
}

.footer {
  padding: 22px 32px 30px;
  font-size: 12px;
  color: #8a97a3;
  text-align: center;
  border-top: 1px solid #eef1f4;
}
</style>
</head>
<body>
  <div class="wrapper">
    <div class="header">
      <img src="{{logo}}" alt="Insurance Platform" />
    </div>
    <div class="banner">Quote request received</div>
    <div class="content">
      <p>Hi {{customer_name}},</p>
      <p>{{body_text}}</p>
      <div class="details-box">
        <table>
          <tr>
            <td class="label">Reference No.</td>
            <td class="value">{{ref_no}}</td>
          </tr>
          <tr>
            <td class="label">Product</td>
            <td class="value">{{product_name}}</td>
          </tr>
        </table>
      </div>
      <p>We''ll be in touch as soon as pricing options are ready. You don''t need to do anything else for now.</p>
    </div>
    <div class="footer">
      This is an automated message from Insurance Platform. Please do not reply directly to this email.
    </div>
  </div>
</body>
</html>', 'Quote request received - client acknowledgement (Insurance Platform)', NOW(), 1, '/root/home/insuranceplatform/logo/insurance-platform-logo.png');
SET @template_id = LAST_INSERT_ID();

INSERT INTO email_template_parameters (email_template_id, param_order, param_name, created_on, created_by)
VALUES
  (@template_id, 1, 'subject', NOW(), 1),
  (@template_id, 2, 'customer_name', NOW(), 1),
  (@template_id, 3, 'recipient_email', NOW(), 1),
  (@template_id, 4, 'ref_no', NOW(), 1),
  (@template_id, 5, 'product_name', NOW(), 1),
  (@template_id, 6, 'body_text', NOW(), 1),
  (@template_id, 7, 'attachment', NOW(), 1),
  (@template_id, 8, 'logo', NOW(), 1);

-- ---- EMAIL_QUOTE_NEW_STAFF_NOTIFY ----
INSERT INTO email_templates (request_type, template, comments, created_on, created_by, logo)
VALUES ('EMAIL_QUOTE_NEW_STAFF_NOTIFY', '<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>{{subject}}</title>
<style>
* { margin:0; padding:0; box-sizing:border-box; }

body {
  font-family: ''Segoe UI'', Arial, sans-serif;
  background: #f0f4f8;
  color: #1a202c;
}

.wrapper {
  max-width: 620px;
  margin: 40px auto;
  background: #ffffff;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 2px 10px rgba(0,0,0,0.06);
}

.header {
  background: #115636;
  padding: 28px 32px;
  text-align: center;
}

.header img {
  max-height: 46px;
}

.banner {
  background: #c8860a;
  color: #ffffff;
  padding: 14px 32px;
  font-size: 15px;
  font-weight: 600;
  letter-spacing: 0.3px;
}

.content {
  padding: 32px;
}

.content p {
  font-size: 15px;
  line-height: 1.6;
  color: #33424f;
  margin-bottom: 16px;
}

.details-box {
  background: #fdf6e8;
  border: 1px solid #f0dfb4;
  border-radius: 10px;
  padding: 18px 20px;
  margin: 20px 0;
}

.details-box table {
  width: 100%;
  border-collapse: collapse;
}

.details-box td {
  padding: 6px 0;
  font-size: 14px;
}

.details-box td.label {
  color: #5a6b78;
  width: 140px;
}

.details-box td.value {
  color: #a8690a;
  font-weight: 600;
}

.footer {
  padding: 22px 32px 30px;
  font-size: 12px;
  color: #8a97a3;
  text-align: center;
  border-top: 1px solid #eef1f4;
}
</style>
</head>
<body>
  <div class="wrapper">
    <div class="header">
      <img src="{{logo}}" alt="Insurance Platform" />
    </div>
    <div class="banner">New quote request awaiting processing</div>
    <div class="content">
      <p>{{body_text}}</p>
      <div class="details-box">
        <table>
          <tr>
            <td class="label">Reference No.</td>
            <td class="value">{{ref_no}}</td>
          </tr>
          <tr>
            <td class="label">Product</td>
            <td class="value">{{product_name}}</td>
          </tr>
          <tr>
            <td class="label">Requested by</td>
            <td class="value">{{requester_name}}</td>
          </tr>
        </table>
      </div>
      <p>Log into the Admin Portal to assign and process this request.</p>
    </div>
    <div class="footer">
      This is an automated internal notification from Insurance Platform.
    </div>
  </div>
</body>
</html>', 'New quote request - internal staff notification (Insurance Platform)', NOW(), 1, '/root/home/insuranceplatform/logo/insurance-platform-logo.png');
SET @template_id = LAST_INSERT_ID();

INSERT INTO email_template_parameters (email_template_id, param_order, param_name, created_on, created_by)
VALUES
  (@template_id, 1, 'subject', NOW(), 1),
  (@template_id, 2, 'requester_name', NOW(), 1),
  (@template_id, 3, 'recipient_email', NOW(), 1),
  (@template_id, 4, 'ref_no', NOW(), 1),
  (@template_id, 5, 'product_name', NOW(), 1),
  (@template_id, 6, 'body_text', NOW(), 1),
  (@template_id, 7, 'attachment', NOW(), 1),
  (@template_id, 8, 'logo', NOW(), 1);

-- ---- EMAIL_QUOTE_OFFERS_COMPARISON ----
INSERT INTO email_templates (request_type, template, comments, created_on, created_by, logo)
VALUES ('EMAIL_QUOTE_OFFERS_COMPARISON', '<!DOCTYPE html>
<html lang="en">
<!--
  NOTE for whoever wires this into the Scapi renderer: {{ref_no}}, {{customer_name}},
  {{subject}}, {{recipient_email}}, {{body_text}}, {{logo}} are plain flat tokens,
  exactly like every other template in this table. {{offers}} is different - it''s the
  JSON array QuoteNotificationSender.cs already sends (each item has underwriter_name,
  premium_amount, document_file_name). The table body below uses a Handlebars-style
  {{#each offers}} ... {{/each}} loop to render one row per offer. If Scapi''s renderer
  only does flat token substitution and can''t loop over an array param, this block will
  render literally instead of as a table - in that case the fix is on the Scapi side
  (or QuoteNotificationSender.cs would need to pre-build a single offers_html string
  param instead), not in this file.
-->
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>{{subject}}</title>
<style>
* { margin:0; padding:0; box-sizing:border-box; }

body {
  font-family: ''Segoe UI'', Arial, sans-serif;
  background: #f0f4f8;
  color: #1a202c;
}

.wrapper {
  max-width: 640px;
  margin: 40px auto;
  background: #ffffff;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 2px 10px rgba(0,0,0,0.06);
}

.header {
  background: #115636;
  padding: 28px 32px;
  text-align: center;
}

.header img {
  max-height: 46px;
}

.banner {
  background: #0d3f28;
  color: #ffffff;
  padding: 14px 32px;
  font-size: 15px;
  font-weight: 600;
  letter-spacing: 0.3px;
}

.content {
  padding: 32px;
}

.content p {
  font-size: 15px;
  line-height: 1.6;
  color: #33424f;
  margin-bottom: 16px;
}

.ref-line {
  font-size: 13px;
  color: #5a6b78;
  margin-bottom: 20px;
}

.ref-line b {
  color: #115636;
}

.offers-table {
  width: 100%;
  border-collapse: collapse;
  margin-bottom: 20px;
}

.offers-table th {
  background: #f4f9f6;
  color: #115636;
  text-align: left;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.4px;
  padding: 10px 14px;
  border-bottom: 2px solid #d9ece2;
}

.offers-table td {
  padding: 12px 14px;
  font-size: 14px;
  border-bottom: 1px solid #eef1f4;
  color: #33424f;
}

.offers-table td.premium {
  font-weight: 600;
  color: #115636;
}

.footer {
  padding: 22px 32px 30px;
  font-size: 12px;
  color: #8a97a3;
  text-align: center;
  border-top: 1px solid #eef1f4;
}
</style>
</head>
<body>
  <div class="wrapper">
    <div class="header">
      <img src="{{logo}}" alt="Insurance Platform" />
    </div>
    <div class="banner">Your quote offers are ready</div>
    <div class="content">
      <p>Hi {{customer_name}},</p>
      <p>{{body_text}}</p>
      <div class="ref-line">Reference No. <b>{{ref_no}}</b></div>
      <table class="offers-table">
        <thead>
          <tr>
            <th>Underwriter</th>
            <th>Premium</th>
            <th>Document</th>
          </tr>
        </thead>
        <tbody>
          {{#each offers}}
          <tr>
            <td>{{underwriter_name}}</td>
            <td class="premium">KES {{premium_amount}}</td>
            <td>{{document_file_name}}</td>
          </tr>
          {{/each}}
        </tbody>
      </table>
      <p>Supporting documents, where available, are attached to this email. Reply to let us know which offer you''d like to go with.</p>
    </div>
    <div class="footer">
      This is an automated message from Insurance Platform. Please do not reply directly to this email.
    </div>
  </div>
</body>
</html>', 'Quote offers ready for comparison - client email (Insurance Platform)', NOW(), 1, '/root/home/insuranceplatform/logo/insurance-platform-logo.png');
SET @template_id = LAST_INSERT_ID();

-- NOTE: no 'attachments' (plural) param here - QuoteNotificationSender.cs
-- never sends that field (Scapi's Worker.cs has no code that reads it -
-- only the singular 'attachment' field, as a ';'-joined list of server-side
-- file paths). A stray 'attachments' row here previously caused Scapi's own
-- param lookup to throw - see fix_offers_comparison_attachment_param.sql.
INSERT INTO email_template_parameters (email_template_id, param_order, param_name, created_on, created_by)
VALUES
  (@template_id, 1, 'subject', NOW(), 1),
  (@template_id, 2, 'customer_name', NOW(), 1),
  (@template_id, 3, 'recipient_email', NOW(), 1),
  (@template_id, 4, 'ref_no', NOW(), 1),
  (@template_id, 5, 'offers', NOW(), 1),
  (@template_id, 6, 'body_text', NOW(), 1),
  (@template_id, 7, 'attachment', NOW(), 1),
  (@template_id, 8, 'logo', NOW(), 1);

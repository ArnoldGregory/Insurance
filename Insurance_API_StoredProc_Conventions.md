# Stored Procedure Conventions (v1)
MySQL 8.0+ / called from C# via ADO.NET (MySqlConnector or MySql.Data)

---

## 1. Naming

`usp_<Entity>_<Action>` — PascalCase entity matching the table it primarily acts on, verb describing the action.

Examples: `usp_User_Login`, `usp_Client_Create`, `usp_Client_ResolveByIdNo`, `usp_Client_AttachLogin`, `usp_Vehicle_Create`, `usp_Vehicle_GetByRegNo`, `usp_TpoPriceMapping_GetPrice`, `usp_Purchase_Create`, `usp_AgentCommission_Accrue`, `usp_CommissionRate_SetOverride`.

Standard action verbs: `Create`, `Update`, `Delete` (always soft), `GetById`, `GetList`, `Search`, plus workflow-specific verbs where a generic CRUD verb doesn't fit (`ResolveByIdNo`, `AttachLogin`, `Accrue`, `Withdraw`, `SelectOffer`).

## 2. Parameter naming

- Input parameters: `p_<name>` (e.g. `p_client_id`, `p_id_no`).
- Output parameters: `o_<name>` (e.g. `o_result_code`, `o_result_message`, `o_new_id`).
- This distinguishes direction at a glance when reading a proc signature, independent of the `IN`/`OUT` keyword.

## 3. Standard response envelope

Every proc — regardless of what it does — returns these two OUT parameters:

```sql
OUT o_result_code    INT,       -- see result code table below
OUT o_result_message VARCHAR(500)
```

Plus, where relevant, a data result set via `SELECT` (for `Get`/`List`/`Create` returning the created row) or a scalar `OUT` param (e.g. `o_new_id` for a simple create).

**Result codes** (kept small and generic — specific meaning comes from `o_result_message`, not a huge enum):

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | Validation error (bad/missing input) |
| 2 | Not found |
| 3 | Duplicate / conflict (e.g. reg_no already exists) |
| 4 | Business rule violation (e.g. OTP expired, wrong state transition) |
| 99 | Unexpected error (caught by the exit handler, logged, transaction rolled back) |

The C# data-access layer always reads `o_result_code`/`o_result_message` first and branches on it — it never has to parse MySQL error text for expected business outcomes (client not found, duplicate vehicle, etc.). Those are normal, anticipated results, not exceptions.

## 4. Error handling & transactions

Every proc that writes to more than one table wraps its body in a transaction with a generic exit handler:

```sql
CREATE PROCEDURE usp_Purchase_Create (
    IN  p_client_id BIGINT UNSIGNED,
    -- ...other inputs...
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500),
    OUT o_purchase_id BIGINT UNSIGNED
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_result_code = 99;
        SET o_result_message = 'Unexpected error — transaction rolled back.';
        RESIGNAL;  -- real/unanticipated errors still surface to ADO.NET as an exception
    END;

    START TRANSACTION;

    -- validation (see §5) — sets o_result_code/message and LEAVEs early on failure,
    -- no RESIGNAL, this is an expected outcome not a system error

    -- business logic / inserts / updates

    COMMIT;
    SET o_result_code = 0;
    SET o_result_message = 'Success';
END
```

Key rule: **expected business outcomes never throw** — they set `o_result_code`/`o_result_message` and return normally. **Truly unexpected errors** (constraint violations we didn't anticipate, deadlocks, connection issues) roll back, get logged via `RESIGNAL`, and surface to ADO.NET as a real `MySqlException` — so bugs aren't silently swallowed as if they were normal business responses.

## 5. Input validation pattern

Validate required inputs at the top of the proc, before starting the transaction, using early-exit blocks:

```sql
IF p_client_id IS NULL THEN
    SET o_result_code = 1;
    SET o_result_message = 'client_id is required.';
    LEAVE proc_label;
END IF;
```

(Requires wrapping the body in a labelled block: `proc_label: BEGIN ... END;`.) This keeps validation errors distinct from not-found (2) and duplicate (3) errors, which are checked after validation, typically via a `SELECT ... INTO` existence check before the write.

## 6. Soft delete

No proc ever issues a hard `DELETE`. "Delete" procs (`usp_<Entity>_Delete`) set `isdeleted = 1`, `deleted_by = p_actor_user_id`, `deleted_on = NOW()`. All `Get`/`List`/`Search` procs filter `WHERE isdeleted = 0` by default.

## 7. Pagination (List/Search procs)

Standard inputs/outputs for any proc returning a list:

```sql
IN  p_page_number INT,      -- 1-based
IN  p_page_size   INT,
OUT o_total_count BIGINT     -- total matching rows, for building pagination UI
```

Uses `LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size` for the result set, with a separate `SELECT COUNT(*) ... INTO o_total_count` before it.

## 8. Actor tracking & audit

Every write proc takes `p_actor_type` (`USER` / `CHANNEL_SERVICE`) and `p_actor_id` as inputs — this is who the API layer has already authenticated (RBAC is enforced there, per our earlier decision; procs don't re-check permissions). The proc uses these to populate `created_by`/`registered_by_user_id`/etc. where relevant, and inserts a row into `AuditLog` (`actor_type`, `actor_id`, `action`, `entity`, `entity_id`, `old_value`, `new_value`) for any Create/Update/Delete/status-change action, inside the same transaction. This is an explicit `INSERT`, not a trigger — keeps the audit trail visible directly in the proc body rather than hidden behind implicit trigger logic.

## 9. Rate/history-style tables (e.g. AgentCommissionOverrides)

Procs that set a new rate never `UPDATE` the rate value in place. Pattern (matches what we discussed for commission history): within one transaction, `UPDATE` the currently-active row's `effective_to` to close it out, then `INSERT` a new row with the new rate and `effective_from`. Both steps happen in the same proc/transaction so the history is always consistent.

## 10. Example signature (putting it together)

```sql
CREATE PROCEDURE usp_Client_ResolveByIdNo (
    IN  p_id_no VARCHAR(50),
    OUT o_result_code INT,
    OUT o_result_message VARCHAR(500),
    OUT o_client_id BIGINT UNSIGNED,
    OUT o_match_status VARCHAR(20)   -- NOT_FOUND / HAS_LOGIN / NO_LOGIN
)
```

This gives the C# layer everything it needs to branch the three-way identity-resolution flow we designed earlier, in one round trip.

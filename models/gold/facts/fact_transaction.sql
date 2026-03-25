{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="transactions_unique_id",
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday")
    )
}}

with
/* =========================================================
   1. Accounting Lines (Incremental + Dedup)
   ========================================================= */
tal_final as (

    select *
    from {{ ref("transaction_accounting_line") }}

    {% if is_incremental()
       and adapter.get_relation(this.database, this.schema, this.identifier) %}

        where last_modified_date >
        (
            select coalesce(max(last_modified_date), '1900-01-01')
            from {{ this }}
        )

    {% endif %}

    qualify row_number() over (
        partition by
            transaction_line_id,
            account_id
        order by
            last_modified_date desc
    ) = 1

),


/* =========================================================
   2. Exchange Rates (Dedup)
   ========================================================= */
cer_final as (

    select *
    from {{ ref("consolidated_exchange_rates") }}

    qualify row_number() over (
        partition by
            posting_period_id,
            to_subsidiary_id,
            from_currency_id
        order by
            last_modified_date desc
    ) = 1

),


/* =========================================================
   3. Main Join
   ========================================================= */
source_rows as (

    select
        /* ===============================
           PRIMARY KEY
           =============================== */
        {{
            dbt_utils.generate_surrogate_key(
                [
                    "tl.transaction_id",
                    "tl.transaction_line_id",
                    "tal.account_id"
                ]
            )
        }} as transactions_unique_id,


        /* ===============================
           FOREIGN KEYS
           =============================== */
        tl.transaction_id,
        t.tran_id,
        tl.transaction_line_id,
        tal.account_id,
        tl.item_id,
        tl.class_id,
        t.posting_period_id,
        t.employee_id,
        tl.entity_id,
        t.billing_address_id,
        t.shipping_address_id,
        t.currency_id,
        tl.subsidiary_id,
        t.location_id,
        t.transaction_status_id,
        tl.department_id,
        cer.accounting_book_id,


        /* ===============================
           DETAILS
           =============================== */
        a.account_number,
        a.account_type,
        a.account_name,
        t.transaction_type,
        t.transaction_number,
        t.title,
        tl.transaction_line_type,
        tl.item_type,
        tl.accounting_line_type,
        tl.quantity,
        t.memo,
        t.billing_status,
        t.transaction_session_ro,
        tal.transaction_accounting_posting_flag,


        /* ===============================
           MEASURES
           =============================== */
        tal.net_amount,
        tal.amount,
        tal.amount_paid,
        tal.amount_un_paid,

        round(tal.net_amount * t.exchange_rate, 2) as converted_net_amount,
        round(tal.net_amount * try_cast(tl.quantity as number), 2) as bom_quantity,


        /* ===============================
           DERIVED KEYS
           =============================== */
        {{
            dbt_utils.generate_surrogate_key(
                ["tal.account_id", "tl.class_id"]
            )
        }} as chart_of_accounts_unique_id,

        {{
            dbt_utils.generate_surrogate_key(
                [
                    "tl.subsidiary_id",
                    "t.posting_period_id",
                    "t.currency_id"
                ]
            )
        }} as consolidated_exchange_rate_unique_id,


        /* ===============================
           DATES
           =============================== */
        t.tran_date,
        t.start_date,
        t.end_date,
        t.due_date,
        t.close_date,
        per.start_date as posting_period_date,


        /* ===============================
           LOOKUPS
           =============================== */
        t.transaction_status_id as transaction_status_name,


        /* ===============================
           AUDIT
           =============================== */
        t.record_type,
        tal.last_modified_date


    from tal_final tal

    left join {{ ref("transaction_lines") }} tl
        on tl.transaction_line_id = tal.transaction_line_id

    left join {{ ref("transaction") }} t
        on t.transaction_id = tl.transaction_id

    left join {{ ref("accounts") }} a
        on a.account_id = tal.account_id

    left join {{ ref("accounting_period") }} per
        on per.posting_period_id = t.posting_period_id


    left join cer_final cer
        on cer.posting_period_id = t.posting_period_id
       and cer.to_subsidiary_id = tl.subsidiary_id
       and cer.from_currency_id = t.currency_id

)

select *
from source_rows
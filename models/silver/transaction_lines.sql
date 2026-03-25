
{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="transaction_line_id",
        on_schema_change="append_new_columns",
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
    )
}}

with
    raw as (

        select *
        from {{ source("netsuite_bronze", "transactionline") }}
        where
            1 = 1
            {% if is_incremental() %}
                and linelastmodifieddate
                >= (select max(line_lastmodified_date) from {{ this }})
            {% endif %}
    ),

    cleaned as (

        select
            -- PRIMARY KEY
            {{ dbt_utils.generate_surrogate_key(['id', 'transaction']) }} as transaction_line_id,

            -- DETAILS / KEYS
            {{ clean_string("accountinglinetype") }} as accounting_line_type,
            {{ clean_string("transactionlinetype") }} as transaction_line_type,
            {{ safe_timestamp_ntz("actualshipdate") }} as actual_ship_date,
            {{ safe_timestamp_ntz("billeddate") }} as billed_date,
            {{ safe_integer("billingschedule") }} as billing_schedule_id,
            {{ safe_integer("class") }} as class_id,
            {{ safe_date("closedate") }} as close_date,
            {{ safe_integer("createdfrom") }} as created_from_transaction_id,
            {{ safe_integer("department") }} as department_id,
            {{ safe_integer("ENTITY") }} as entity_id,
            {{ safe_integer("expenseaccount") }} as revenue_account_name,
            {{ safe_integer("ITEM") }} as item_id,
            {{ clean_string("ITEMtype") }} as item_type,
            {{ safe_timestamp_ntz("linelastmodifieddate") }} as line_lastmodified_date,
            {{ safe_integer("linesequencenumber") }} as line_sequence_number_id,
            {{ safe_integer("location") }} as location_id,
            {{ safe_integer("paymentmethod") }} as payment_method_id,
            {{ safe_integer("price") }} as price_id,
            {{ safe_integer("revenueelement") }} as zab_revenue_detail_id,
            {{ safe_integer("SUBSIDIARY") }} as subsidiary_id,
            {{ safe_integer("transaction") }} as transaction_id,
            {{ safe_integer("uniquekey") }} as unique_key,
            {{ safe_integer("units") }} as unit_id,

            -- AMOUNTS / METRICS
            {{ safe_decimal("foreignamount") }} as foreign_amount,
            {{ safe_decimal("netamount") }} as net_amount,
            {{ safe_decimal("orderpriority") }} as order_priority,
            {{ safe_decimal("quantity") }} as quantity,
            {{ safe_decimal("rate") }} as rate,

            -- FLAGS
            {{ safe_boolean("isbillable") }} as is_billable,
            {{ safe_boolean("isclosed") }} as is_closed,
            {{ safe_boolean("iscogs") }} as is_cogs,
            {{ safe_boolean("isfullyshipped") }} as is_fully_shipped,
            {{ safe_boolean("taxline") }} as tax_line,
            {{ safe_boolean("transactiondiscount") }} as transaction_discount,

            -- FREE TEXT
            {{ clean_string("memo") }} as memo,

            -- AUDIT / METADATA
            {{ safe_timestamp_ntz("CURRENT_TIMESTAMP()") }} as silver_load_date

        from raw
    )

select *
from cleaned

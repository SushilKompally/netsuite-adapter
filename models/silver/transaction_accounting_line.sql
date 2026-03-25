{#
-- Description: Incremental Load Script for Silver Layer - transaction_accounting_line table
-- Script Name: transaction_accounting_line.sql
-- Created on: 24-Dec-2025
-- Author: Sushil Kumar Kompally
-- Purpose:
--     Incremental load from Bronze to Silver for the NetSuite transaction accounting line table.
--     Standardizes types, applies cleanup macros, and enforces unique key on TRANSACTION_LINE_ID.
-- Data source version: v62.0
-- Change History:
--     24-Dec-2025 - Initial creation - Sushil Komp--     24-Dec-2025 - Initial creation - Sushil Kompally
#}
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
        from {{ source("netsuite_bronze", "transactionaccountingline") }}
        where
            1 = 1
            {% if is_incremental() %}
                and lastmodifieddate >= (select max(last_modified_date) from {{ this }})
            {% endif %}
    ),

    cleaned as (

        select
            -- PRIMARY KEY
            {{ dbt_utils.generate_surrogate_key(['transaction','accountingbook', 'transactionline']) }} as transaction_line_id,

            -- FOREIGN KEYS 
            {{ safe_integer("account") }} as account_id,
            {{ safe_integer("transaction") }} as transaction_id,
            {{ safe_integer("accountingbook") }} as accounting_book_id,

            -- DETAILS
            {{ clean_string("accounttype") }} as account_type,
            {{ safe_decimal("amount") }} as amount,
            {{ safe_decimal("amountpaid") }} as amount_paid,
            {{ safe_decimal("amountunpaid") }} as amount_un_paid,
            {{ safe_decimal("exchangerate") }} as exchange_rate,
            {{ safe_decimal("netamount") }} as net_amount,
            {{ safe_boolean("posting") }} as transaction_accounting_posting_flag,

            -- DATES / TIMESTAMPS
            {{ safe_timestamp_ntz("lastmodifieddate") }} as last_modified_date,

            -- AUDIT / METADATA
            {{ safe_timestamp_ntz("CURRENT_TIMESTAMP()") }} as silver_load_date

        from raw

    )

select *
from cleaned

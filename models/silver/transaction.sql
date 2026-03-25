{#
-- Description: Incremental Load Script for Silver Layer - transaction table
-- Script Name: transaction.sql
-- Created on: 24-Dec-2025
-- Author: Sushil Kumar Kompally
-- Purpose:
--     Incremental load from Bronze to Silver for the NetSuite transaction accounting line table.
--     Standardizes types, applies cleanup macros, and enforces unique key on TRANSACTION_ID.
-- Data source version: v62.0
-- Change History:
--     24-Dec-2025 - Initial creation - Sushil Komp--     24-Dec-2025 - Initial creation - Sushil Kompally
#}
{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="transaction_id",
        on_schema_change="append_new_columns",
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
    )
}}

with
    raw as (

        select *
        from {{ source("netsuite_bronze", "transaction") }}
        where
            1 = 1
            {% if is_incremental() %}
                and lastmodifieddate >= (select max(last_modified_date) from {{ this }})
            {% endif %}
    ),

    cleaned as (

        select
            -- PRIMARY KEY
            {{ safe_integer("id") }} as transaction_id,

            -- FOREIGN KEYS / REFERENCES
            {{ safe_integer("postingperiod") }} as posting_period_id,
            {{ clean_string("status") }} as transaction_status_id,
            {{ safe_integer("employee") }} as employee_id,
            {{ safe_integer("SOURCETRANSACTION") }} as source_transaction,
            {{ safe_integer("currency") }} as currency_id,
            {{ safe_integer("ENTITY") }} as internal_entity_id,
            {{ safe_integer("TRANSFERLOCATION") }} as location_id,
            {{ safe_integer("partner") }} as partner_id,
            {{ safe_integer("paymentmethod") }} as payment_method_id,
            {{ safe_integer("website") }} as transaction_session_vin,

            -- DETAILS (strings cleaned)
            {{ clean_string("BILLINGADDRESS") }} as billing_address_id,
            {{ clean_string("email") }} as session_shop_email,
            {{ clean_string("memo") }} as memo,
            {{ clean_string("SHIPPINGADDRESS") }} as shipping_address_id,
            {{ clean_string("status") }} as billing_status,
            {{ clean_string("title") }} as title,
            {{ clean_string("tranid") }} as tran_id,
            {{ clean_string("transactionnumber") }} as transaction_number,
            {{ clean_string("partner") }} as transaction_session_ro,
            {{ clean_string("source") }} as source,
            {{ clean_string("type") }} as transaction_type,
            {{ clean_string("RECORDTYPE") }} as record_type,

            -- NUMBERS
            {{ safe_decimal("amountunbilled") }} as amount_unbilled,
            {{ safe_decimal("exchangerate") }} as exchange_rate,

            -- DATES / TIMESTAMPS (Snowflake-safe)
            {{ safe_timestamp_ntz("closedate") }} as close_date,
            {{ safe_timestamp_ntz("CREATEDDATE") }} as created_date,
            {{ safe_timestamp_ntz("lastmodifieddate") }} as last_modified_date,
            {{ safe_timestamp_ntz("duedate") }} as due_date,
            {{ safe_timestamp_ntz("enddate") }} as end_date,
            {{ safe_timestamp_ntz("startdate") }} as start_date,
            {{ safe_timestamp_ntz("trandate") }} as tran_date,

            -- AUDIT / METADATA
            {{ safe_timestamp_ntz("CURRENT_TIMESTAMP()") }} as silver_load_date

        from raw
        where _fivetran_deleted = false
    )

select *
from cleaned

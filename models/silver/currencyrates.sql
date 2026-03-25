{#
-- Description: Incremental Load Script for Silver Layer - currencyrates Table
-- Script Name: silver_currencyrates.sql
-- Created on: 23-dec-2025
-- Author: Sushil Kumar Kompally
-- Purpose:
--     This script performs an incremental load from the Bronze layer to the
--     Silver layer for the currencyrates table in the NetSuite data pipeline.
-- Data source version: v62.0
-- Change History:
--     23-dec-2025 - Initial creation - Sushil Kompally
#}
with
    raw as (

        select * from {{ source("netsuite_bronze", "currencyrate") }} where 1 = 1
    -- {{ incremental_filter() }}
    ),

    cleaned as (

        select
            -- PRIMARY KEY
            {{ safe_integer("id") }} as currency_rate_id,

            -- DATES
            {{ safe_date("effectivedate") }} as effective_date,
            {{ safe_timestamp_ntz("lastmodifieddate") }} as last_modified_date,

            -- DETAILS
            {{ safe_decimal("exchangerate") }} as exchange_rate,
            {{ clean_string("externalid") }} as externalid,
            {{ safe_integer("transactioncurrency") }} as transaction_currency,

            -- AUDIT
            {{ safe_timestamp_ntz("CURRENT_TIMESTAMP()") }} AS silver_load_date
        from raw
        where _fivetran_deleted = false

    )

select *
from cleaned

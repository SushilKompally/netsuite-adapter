{#
-- Description: Incremental Load Script for Silver Layer - currencies Table
-- Script Name: silver_currencies.sql
-- Created on: 23-dec-2025
-- Author: Sushil Kumar Kompally
-- Purpose:
--     This script performs an incremental load from the Bronze layer to the
--     Silver layer for the currencies table in the NetSuite data pipeline.
-- Data source version: v62.0
-- Change History:
--     23-dec-2025 - Initial creation - Sushil Kompally
#}
with
    raw as (

        select * from {{ source("netsuite_bronze", "currency") }} where 1 = 1
    -- {{ incremental_filter() }}
    ),

    cleaned as (

        select
            -- KEYS
            {{ safe_integer("id") }} as currency_id,

            -- DATES
            {{ safe_timestamp_ntz("lastmodifieddate") }} as last_modified_date,

            -- DETAILS / FLAGS
            {{ safe_decimal("exchangerate") }} as exchange_rate,  -- INT as requested
            {{ safe_boolean("isinactive") }} as is_inactive,
            {{ safe_boolean("isbasecurrency") }} as is_base_currency,
            {{ clean_string("name") }} as currency_name,
            {{ clean_string("symbol") }} as display_symbol,

            -- AUDIT
            {{ safe_timestamp_ntz("CURRENT_TIMESTAMP()") }} AS silver_load_date

        from raw
        where _fivetran_deleted = false

    )

select *
from cleaned

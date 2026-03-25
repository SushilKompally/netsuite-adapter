{#
-- Description: Incremental Load Script for Silver Layer - consolidated_exchange_rates Table
-- Script Name: silver_consolidated_exchange_rates.sql
-- Created on: 23-dec-2025
-- Author: Sushil Kumar Kompally
-- Purpose:
--     This script performs an incremental load from the Bronze layer to the
--     Silver layer for the consolidated_exchange_rates table in the NetSuite data pipeline.
-- Data source version: v62.0
-- Change History:
--     23-dec-2025 - Initial creation - Sushil Kompally
#}
with
    raw as (

        select *

        from {{ source("netsuite_bronze", "consolidatedexchangerate") }}
        where 1 = 1
    -- {{ incremental_filter() }}
    ),

    cleaned as (

        select
            -- PRIMARY KEY
            {{ safe_integer("id") }} as consolidated_exchange_rate_id,

            -- FOREIGN KEYS
            {{ safe_integer("accountingbook") }} as accounting_book_id,
            {{ safe_integer("postingperiod") }} as posting_period_id,
            {{ safe_integer("fromsubsidiary") }} as from_subsidiary_id,
            {{ safe_integer("tosubsidiary") }} as to_subsidiary_id,
            {{ safe_integer("fromcurrency") }} as from_currency_id,
            {{ safe_integer("tocurrency") }} as to_currency_id,

            -- DETAILS 
            {{ safe_decimal("averagerate") }} as average_rate,
            {{ safe_decimal("currentrate") }} as current_rate,
            {{ safe_decimal("historicalrate") }} as historical_rate,
            {{ safe_timestamp_ntz("_fivetran_synced") }} as last_modified_date,

            -- AUDIT
            {{ safe_timestamp_ntz("CURRENT_TIMESTAMP()") }} as silver_load_date

        from raw
        where _fivetran_deleted = false

    )

select *
from cleaned

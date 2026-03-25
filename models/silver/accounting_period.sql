{#
-- Description: Incremental Load Script for Silver Layer - accounting_period Table
-- Script Name: silver_accounting_period.sql
-- Created on: 23-dec-2025
-- Author: Sushil Kumar Kompally
-- Purpose:
--   Incremental load from Bronze to Silver for accounting_period in the NetSuite pipeline.
-- Data source version: v62.0
-- Change History:
--   23-dec-2025 - Initial creation - Sushil Kompally
#}
{{
    config(
        materialized="incremental",
        unique_key="posting_period_id",
        incremental_strategy="merge",
        on_schema_change="append_new_columns",
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
    )
}}

with
    raw as (
        select *
        from {{ source("netsuite_bronze", "accountingperiod") }}
        where
            1 = 1

            {% if is_incremental() %}
                and lastmodifieddate >= (select max(last_modified_date) from {{ this }})
            {% endif %}
    ),

    cleaned as (

        select
            -- PRIMARY KEY
            {{ safe_integer("id") }} as posting_period_id,

            -- DATES
            {{ safe_date("closedondate") }} as closed_on_date,
            {{ safe_timestamp_ntz("lastmodifieddate") }} as last_modified_date,
            {{ safe_date("enddate") }} as end_date,
            {{ safe_date("startdate") }} as start_date,

            -- DETAILS
            {{ clean_string("periodname") }} as period_name,
            cast(right(periodname, 4) as int) as year,

            -- LOAD / AUDIT
            {{ safe_timestamp_ntz("CURRENT_TIMESTAMP()") }} as silver_load_date

        from raw
        where _fivetran_deleted = false
    )

select *
from cleaned

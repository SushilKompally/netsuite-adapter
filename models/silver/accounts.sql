{#
-- Description: Incremental Load Script for Silver Layer - accounting_period Table
-- Script Name: silver_accounting_period.sql
-- Created on: 23-dec-2025
-- Author: Sushil Kumar Kompally
-- Purpose:
--     This script performs an incremental load from the Bronze layer to the
--     Silver layer for the accounting_period table in the netsuite data pipeline.
-- Data source version: v62.0
-- Change History:
--     23-dec-2025 - Initial creation - Sushil Kompally
#}
{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="account_id",
        on_schema_change="append_new_columns",
        full_refresh = (modules.datetime.datetime.now().strftime('%A') == 'Monday')
    )
}}

with
    raw as (

        select *
        from {{ source("netsuite_bronze", "account") }}
        where
            1 = 1
            {% if is_incremental() %}
                and lastmodifieddate >= (select max(last_modified_date) from {{ this }})
            {% endif %}

    ),

    cleaned as (

        select
            -- PRIMARY KEY
            {{ safe_integer("id") }} as account_id,

            -- FOREIGN KEYS
            {{ safe_integer("class") }} as class_id,
            {{ safe_integer("currency") }} as currency_id,
            {{ safe_integer("department") }} as department_id,
            {{ safe_integer("location") }} as location_id,
            {{ safe_integer("parent") }} as parent_id,
            {{ safe_integer("subsidiary") }} as subsidiary_id,

            -- DETAILS
            {{ clean_string("acctnumber") }} as account_number,
            {{ clean_string("description") }} as account_description,
            {{ clean_string("displaynamewithhierarchy") }} as display_name,
            {{ clean_string("fullname") }} as display_name_with_hierarchy,
            case when isinactive = 'T' then true else false end as is_inactive,
            {{ clean_string("accountsearchdisplaynamecopy") }} as account_name,
            {{ clean_string("accttype") }} as account_type,

            -- DATES / TIMESTAMPS
            {{ safe_timestamp_ntz("lastmodifieddate") }} as last_modified_date,

            -- AUDIT
            {{ safe_timestamp_ntz("CURRENT_TIMESTAMP()") }} as silver_load_date
        from raw
        where _fivetran_deleted = false

    )

select *
from cleaned

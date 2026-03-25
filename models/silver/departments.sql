{#
-- Description: Incremental Load Script for Silver Layer - departments Table
-- Script Name: silver_departments.sql
-- Created on: 23-dec-2025
-- Author: Sushil Kumar Kompally
-- Purpose:
--     This script performs an incremental load from the Bronze layer to the
--     Silver layer for the departments table in the NetSuite data pipeline.
-- Data source version: v62.0
-- Change History:
--     23-dec-2025 - Initial creation - Sushil Kompally
#}
{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="department_id",
        on_schema_change="append_new_columns",
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
    )
}}

with
    raw as (

        select *
        from {{ source("netsuite_bronze", "department") }}
        where
            1 = 1
            {% if is_incremental() %}
                and lastmodifieddate >= (select max(last_modified_date) from {{ this }})
            {% endif %}

    ),

    cleaned as (

        select

            -- KEYS
            {{ safe_integer("id") }} as department_id,
            {{ safe_integer("parent") }} as parent,

            -- DETAILS
            {{ clean_string("fullname") }} as department_full_name,
            {{ safe_boolean("isinactive") }} as is_inactive,
            {{ clean_string("name") }} as department_name,

            -- DATES
            {{ safe_timestamp_ntz("lastmodifieddate") }} as last_modified_date,

            -- AUDIT
            {{ safe_timestamp_ntz("CURRENT_TIMESTAMP()") }} as silver_load_date

        from raw
        where _fivetran_deleted = false

    )

select *
from cleaned

{#
-- Description: Incremental Load Script for Silver Layer - locations Table
-- Script Name: silver_locations.sql
-- Created on: 23-dec-2025
-- Author: Sushil Kumar Kompally
-- Purpose:
--     This script performs an incremental load from the Bronze layer to the
--     Silver layer for the locations table in the NetSuite data pipeline.
-- Data source version: v62.0
-- Change History:
--     23-dec-2025 - Initial creation - Sushil Kompally
#}
{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="location_id",
        on_schema_change="append_new_columns",
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
    )
}}

with
    raw as (

        select *
        from {{ source("netsuite_bronze", "location") }}
        where
            1 = 1
            {% if is_incremental() %}
                and lastmodifieddate >= (select max(last_modified_date) from {{ this }})
            {% endif %}
    ),

    cleaned as (

        select
            -- PRIMARY KEY
            {{ safe_integer("id") }} as location_id,

            -- FOREIGN KEYS
            {{ safe_integer("parent") }} as parent,
            {{ safe_integer("SUBSIDIARY") }} as subsidiary_id,
            {{ safe_integer("locationtype") }} as location_type,

            -- DETAILS
            {{ clean_string("fullname") }} as location_full_name,
            {{ clean_string("name") }} as location_name,
            {{ safe_boolean("isinactive") }} as is_inactive,
            {{ clean_string("latitude") }} as latitude,
            {{ clean_string("longitude") }} as longitude,

            -- DATES / TIMESTAMPS
            {{ safe_timestamp_ntz("lastmodifieddate") }} as last_modified_date,

            -- AUDIT / METADATA
            {{ safe_timestamp_ntz("CURRENT_TIMESTAMP()") }} as silver_load_date

        from raw
        where _fivetran_deleted = false
    )

select *
from cleaned

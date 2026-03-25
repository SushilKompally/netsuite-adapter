{#
-- Description: Incremental Load Script for Silver Layer - entity Table
-- Script Name: silver_entity.sql
-- Created on: 23-dec-2025
-- Author: Sushil Kumar Kompally
-- Purpose:
--     This script performs an incremental load from the Bronze layer to the
--     Silver layer for the entity table in the NetSuite data pipeline.
-- Data source version: v62.0
-- Change History:
--     23-dec-2025 - Initial creation - Sushil Kompally
#}
{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="internal_entity_id",
        on_schema_change="append_new_columns",
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
    )
}}

with
    raw as (

        select *
        from {{ source("netsuite_bronze", "entity") }}
        where
            1 = 1
            {% if is_incremental() %}
                and lastmodifieddate >= (select max(last_modified_date) from {{ this }})
            {% endif %}
    ),

    cleaned as (

        select
            -- PRIMARY KEY
            {{ safe_integer("id") }} as internal_entity_id,

            -- FOREIGN KEYS
            {{ safe_integer("contact") }} as contact_id,
            {{ safe_integer("customer") }} as customer_id,
            {{ safe_integer("employee") }} as employee_id,
            {{ safe_integer('"GROUP"') }} as group_id,
            {{ safe_integer("parent") }} as parent_id,
            {{ safe_integer("partner") }} as partner_id,
            {{ safe_integer("vendor") }} as vendor_id,

            -- DETAILS
            {{ clean_string("email") }} as email,
            {{ safe_integer("ENTITYid") }} as entity_id,
            {{ clean_string("ENTITYtitle") }} as entity_title,
            {{ clean_string("firstname") }} as first_name,
            {{ clean_string("lastname") }} as last_name,
            {{ clean_string("type") }} as entity_type,
            {{ safe_boolean("isinactive") }} as is_inactive,
            {{ safe_boolean("isperson") }} as is_person,

            -- DATES / TIMESTAMPS
            {{ safe_timestamp_ntz("datecreated") }} as date_created,
            {{ safe_timestamp_ntz("lastmodifieddate") }} as last_modified_date,

            -- AUDIT / METADATA
            {{ safe_timestamp_ntz("CURRENT_TIMESTAMP()") }} as silver_load_date

        from raw where _fivetran_deleted = false
    ), 
deduped as (

    select *
    from (
        select
            *,
            row_number() over (
                partition by internal_entity_id
                order by last_modified_date desc
            ) as rn
        from cleaned
    )
    where rn = 1
)

select * EXCLUDE (rn) from deduped

{#
-- Description: Incremental Load Script for Silver Layer - employees Table
-- Script Name: silver_employees.sql
-- Created on: 23-dec-2025
-- Author: Sushil Kumar Kompally
-- Purpose:
--     This script performs an incremental load from the Bronze layer to the
--     Silver layer for the employees table in the NetSuite data pipeline.
-- Data source version: v62.0
-- Change History:
--     23-dec-2025 - Initial creation - Sushil Kompally
#}
{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="employee_id",
        on_schema_change="append_new_columns",
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
    )
}}

with
    raw as (

        select *
        from {{ source("netsuite_bronze", "employee") }}
        where
            1 = 1
            {% if is_incremental() %}
                and lastmodifieddate >= (select max(last_modified_date) from {{ this }})
            {% endif %}
    ),

    cleaned as (

        select
            -- PRIMARY KEY
            {{ safe_integer("id") }} as employee_id,

            -- FOREIGN KEYS
            {{ safe_integer("class") }} as class_id,
            {{ safe_integer("currency") }} as currency,
            {{ safe_integer("department") }} as department_id,
            {{ safe_integer("location") }} as location_id,
            {{ safe_integer("employeetype") }} as employee_type_id,
            {{ safe_integer("subsidiary") }} as subsidiary,
            {{ clean_string("entityid") }} as entity_id,

            -- DETAILS
            {{ clean_string("accountnumber") }} as account_number,
            {{ clean_string("email") }} as email,
            {{ safe_boolean("isinactive") }} as is_inactive,
            {{ clean_string("jobdescription") }} as job_description,
            {{ clean_string("employeestatus") }} as employee_status_id,
            {{ clean_string("title") }} as title,

            -- DATES / TIMESTAMPS
            {{ safe_timestamp_ntz("datecreated") }} as date_created,
            {{ safe_timestamp_ntz("lastmodifieddate") }} as last_modified_date,

            -- AUDIT / METADATA
            {{ safe_timestamp_ntz("CURRENT_TIMESTAMP()") }} as silver_load_date

        from raw
        where _fivetran_deleted = false
    )

select *
from cleaned

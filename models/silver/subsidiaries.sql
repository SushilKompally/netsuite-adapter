{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="subsidiary_id",
        on_schema_change="append_new_columns",
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
    )
}}

with
    raw as (

        select *
        from {{ source("netsuite_bronze", "subsidiary") }}
        where
            1 = 1
            {% if is_incremental() %}
                and lastmodifieddate
                >= (select max(last_modified_date) from {{ this }})
            {% endif %}
    ),

    cleaned as (

        select
            -- PRIMARY KEY
            {{ safe_integer("id") }} as subsidiary_id,

            -- DETAILS
            {{ safe_integer("currency") }} as currency_id,
            {{ clean_string("fullname") }} as subsidiary_full_name,
            {{ safe_boolean("isinactive") }} as is_inactive,
            {{ clean_string("name") }} as subsidiary_name,
            {{ safe_integer("parent") }} as parent_id,

            -- DATES / TIMESTAMPS
            {{ safe_timestamp_ntz("lastmodifieddate") }} as last_modified_date,
            -- AUDIT / METADATA
            {{ safe_timestamp_ntz("CURRENT_TIMESTAMP()") }} as silver_load_date
        from raw
        where _fivetran_deleted = false
    )

select *
from cleaned

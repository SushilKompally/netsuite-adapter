{{
    config(
        materialized="incremental",
        unique_key="class_id",
        incremental_strategy="merge",
        on_schema_change="append_new_columns",
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
    )
}}


with
    raw as (

        select *
        from {{ source("netsuite_bronze", "classification") }}
        where
            1 = 1

            {% if is_incremental() %}
                and lastmodifieddate >= (select max(last_modified_date) from {{ this }})
            {% endif %}

    ),

    cleaned as (

        select
            -- PK
            {{ safe_integer("id") }} as class_id,

            -- DETAILS
            {{ clean_string("fullname") }} as class_full_name,
            {{ safe_boolean("isinactive") }} as is_inactive,
            {{ safe_timestamp_ntz("lastmodifieddate") }} as last_modified_date,
            {{ clean_string("name") }} as class_name,
            {{ safe_integer("parent") }} as parent,

            -- AUDIT
            {{ safe_timestamp_ntz("CURRENT_TIMESTAMP()") }} as silver_load_date

        from raw
        where _fivetran_deleted = false

    )

select *
from cleaned

{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="location_id",
        on_schema_change="append_new_columns",
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
    )
}}

{# Configurable lookback window (days); default = 1 #}
{%- set lb_days = var("lb_days", 1) -%}

with
    source_base as (
        select
            l.location_id,
            l.location_name,
            l.location_full_name,
            l.is_inactive,
            -- normalize timestamp
            l.last_modified_date as last_modified_date,
            l.latitude,
            l.longitude,
            l.location_type,
            l.parent,
            l.subsidiary_id,

            -- surrogate key
            {{ dbt_utils.generate_surrogate_key(["location_id"]) }} as location_surr_key
        from {{ ref("snp_locations") }} l
    -- If this is a SNAPSHOT, uncomment the next line:
    -- where l.dbt_valid_to is null
    ),

    source_rows as (
        select *
        from source_base

        {% if is_incremental() %}
            where
                last_modified_date >= (
                    select
                        dateadd(
                            day,
                            -1 * {{ lb_days }},
                            coalesce(
                                max(last_modified_date::timestamp_ntz),
                                '1900-01-01'::timestamp_ntz
                            )
                        )
                    from {{ this }}
                )
        {% endif %}
    )

-- dbt will use this SELECT as the USING subquery for MERGE
select *
from source_rows

{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="department_id",
        on_schema_change="append_new_columns",
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
    )
}}

{# configurable lookback window in days #}
{%- set lb_days = var("lb_days", 1) -%}

with
    current_snapshot as (
        -- Take only the current version from the snapshot
        select d.* from {{ ref("snp_departments") }} d where d.dbt_valid_to is null
    ),

    source_rows as (
        select
            d.department_id,
            d.department_name,
            d.department_full_name,
            d.is_inactive,
            d.parent,

            -- normalize timestamp for safe comparison
            d.last_modified_date::timestamp_ntz as last_modified_date,

            -- surrogate key
            {{ dbt_utils.generate_surrogate_key(["department_id"]) }} as department_surr_id

        -- optional lineage (uncomment if you want it in the dim)
        -- , d.dbt_valid_from as effective_from
        -- , d.dbt_scd_id     as scd_id
        from current_snapshot d

        {% if is_incremental() %}
            where
                d.last_modified_date::timestamp_ntz >= (
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

-- dbt uses this as the USING subquery of MERGE
select *
from source_rows

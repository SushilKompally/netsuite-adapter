{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'employee_id',
    on_schema_change = 'append_new_columns',
    full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
  )
}}

{# Configurable lookback days with a safe default of 1 day #}
{%- set lb_days = var("lb_days", 1) -%}

with
    current_snapshot as (
        -- Only current (latest) SCD2 rows from the snapshot
        select * from {{ ref("snp_employees") }} e where dbt_valid_to is null
    ),

    source_rows as (
        select
            -- Keys & attributes (as provided)
            employee_id,
            entity_id,
            email,
            title,
            job_description,
            class_id,
            currency,
            department_id,
            date_created,
            employee_type_id,
            account_number,
            location_id,
            employee_status_id,
            is_inactive,
            subsidiary,

            -- normalize timestamp for safe comparison & merge
            last_modified_date::timestamp_ntz as last_modified_date,

            --surrogate key
            {{ dbt_utils.generate_surrogate_key(["employee_id"]) }} as employee_surr_id

        -- Optionally include lineage if needed in the dimension:
        -- , dbt_valid_from as effective_from
        -- , dbt_scd_id     as scd_id
        from current_snapshot e

        {% if is_incremental() %}
            where
                last_modified_date::timestamp_ntz >= (
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

-- dbt uses this SELECT as the USING subquery of the MERGE
select *
from source_rows

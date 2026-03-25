{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'account_id',
    on_schema_change = 'append_new_columns',
    full_refresh = (modules.datetime.datetime.now().strftime('%A') == 'Monday')
  )
}}

{# parameterized lookback days with a safe default #}
{%- set lb_days = var("lb_days", 1) -%}

with
    current_snapshot as (
        -- Only current rows from the snapshot (SCD2 current state)
        select * from {{ ref("snp_chartofaccounts") }} a where dbt_valid_to is null
    ),

    source_rows as (
        select
            -- KEYS / ATTRIBUTES
            account_id,
            class_id,
            currency_id,
            department_id,
            location_id,
            account_parent_id,
            subsidiary_id,
            account_number,
            account_description,
            display_name,
            display_name_with_hierarchy,
            account_name,
            account_type,
            subsidiary_name,
            subsidiary_full_name,
            subsidiary_parent_id,
            class_full_name,
            class_name,
            classification_parent,

            -- normalize timestamp type for consistent comparisons
            last_modified_date as last_modified_date,

            --surrogate key
            {{ dbt_utils.generate_surrogate_key(["account_id"]) }} as chatofaccount_surr_id

        -- optionally bring lineage fields if you want (commented out by default)
        -- , dbt_valid_from as effective_from
        -- , dbt_scd_id     as scd_id
        from current_snapshot a

        {% if is_incremental() %}
            where
                last_modified_date::timestamp_ntz >= (
                    -- Use a parameterized lookback window: -1 * {{ lb_days }} days
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

-- dbt will use this SELECT as the USING subquery of the MERGE
select *
from source_rows

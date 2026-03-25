{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="subsidiary_id",
        on_schema_change="append_new_columns",
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
    )
}}

{# Configurable lookback window in days (default = 1) #}
{%- set lb_days = var("lb_days", 1) -%}

with
    current_snapshot as (
        -- Only the current (latest) SCD2 rows from the snapshot
        select s.* from {{ ref('snp_subsidiary') }} s where s.dbt_valid_to is null
    ),

    source_rows as (
        select
            s.subsidiary_id,
            s.currency_id,
            s.subsidiary_full_name,
            s.is_inactive,
            s.subsidiary_name,
            s.parent_id,

            -- silver metadata (not part of watermark, but included in dim)
            s.silver_load_date,

            --surrogate key
            {{ dbt_utils.generate_surrogate_key(["subsidiary_id"]) }} as subsidiary_surr_key

        -- normalize timestamp (only if you later want to watermark on it)
        -- If silver_load_date is DATE, you can cast to TIMESTAMP_NTZ if needed:
        -- cast(s.silver_load_date as timestamp_ntz) as silver_load_date
        from current_snapshot s

        {% if is_incremental() %}
            where
                s.silver_load_date >= (
                    select
                        dateadd(
                            day,
                            -1 * {{ lb_days }},
                            coalesce(max(silver_load_date), to_date('1900-01-01'))
                        )
                    from {{ this }}
                )
        {% endif %}
    )

-- dbt will use this SELECT as the USING subquery of the MERGE
select *
from source_rows

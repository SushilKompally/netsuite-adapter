{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="posting_period_id",
        on_schema_change="append_new_columns",
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
    )
}}

{# parameterized lookback days with a safe default #}
{%- set lb_days = var("lb_days", 1) -%}

with
    current_snapshot as (
        select *
        from {{ ref("snp_accounting_period") }}
        where dbt_valid_to is null
    ),

    source_rows as (
        select
            -- surrogate key (using dbt_utils for standard compatibility)
            {{ dbt_utils.generate_surrogate_key(["posting_period_id"]) }} as accounting_period_surr_key,

            -- business key
            t.posting_period_id,

            -- attributes
            t.closed_on_date,
            t.last_modified_date,
            t.end_date,
            t.start_date,
            t.period_name,
            t.year,
            t.silver_load_date,

            -- lineage
            t.dbt_valid_from as effective_from,
            t.dbt_scd_id as scd_id

        from current_snapshot t

        {% if is_incremental() %}
            where t.last_modified_date >= (
                select 
                    dateadd(day, -{{ lb_days }}, coalesce(max(last_modified_date), '1900-01-01'::timestamp_ntz))
                from {{ this }}
            )
        {% endif %}
    )

select *
from source_rows

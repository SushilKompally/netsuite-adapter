{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="currency_id",
        on_schema_change="append_new_columns",
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
    )
}}

{# parameterized lookback days with a safe default #}
{%- set lb_days = var("lb_days", 1) -%}

with
    current_snapshot as (
        -- Only current rows from the snapshot (SCD2 current state)
        select * from {{ ref("snp_currency") }} where dbt_valid_to is null
    ),

    source_rows as (
        select
            -- Natural key
            currency_id,

            -- Currency attributes
            currency_name,
            display_symbol as currency_symbol,
            is_base_currency,

            -- Normalize timestamp for incremental comparison
            last_modified_date::timestamp_ntz as last_modified_date,

            -- Surrogate key (NetSuite base)
            {{ dbt_utils.generate_surrogate_key(["currency_id"]) }} as currency_key

        from current_snapshot

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

-- dbt will use this SELECT as the USING subquery of the MERGE
select
    currency_key,
    currency_id,
    currency_name,
    currency_symbol,
    is_base_currency,
    last_modified_date
from source_rows

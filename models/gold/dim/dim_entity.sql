{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'internal_entity_id',
    on_schema_change = 'append_new_columns',
    full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
  )
}}

{# Lookback days param with default = 1 #}
{%- set lb_days = var("lb_days", 1) -%}

with
    current_rows as (
        select
            entity_id,
            contact_id,
            customer_id,
            date_created,
            email,
            employee_id,
            entity_title,
            first_name,
            group_id,
            internal_entity_id,
            is_inactive,
            is_person,
            -- normalize timestamp for safe comparison
            last_modified_date::timestamp_ntz as last_modified_date,
            last_name,
            parent_id,
            partner_id,
            entity_type,
            vendor_id,

            --surrogate key
            {{ dbt_utils.generate_surrogate_key(["internal_entity_id"]) }} as entity_surr_id
        from {{ ref("snp_entity") }} e
        where dbt_valid_to is null
    ),

    source_rows as (
        select *
        from current_rows

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

-- dbt will use this SELECT as the USING subquery of the MERGE
select *
from source_rows

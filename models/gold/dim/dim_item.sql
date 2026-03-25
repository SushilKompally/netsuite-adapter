{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'item_id',
    on_schema_change = 'append_new_columns',
    full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
  ) 
}}

{# Configurable lookback window in days (default = 1) #}
{%- set lb_days = var("lb_days", 1) -%}

with
    current_snapshot as (
        -- Only the current (latest) SCD2 rows from the snapshot
        select *
        from {{ ref("snp_item") }} i
        where dbt_valid_to is null
    ),

    source_rows as (
        select
            item_id,
            average_cost,
            class_id,
            cost,
            costing_method,
            created_date,
            department_id,
            description,
            display_name,
            item_full_name,
            income_account,
            is_ful_fillable,
            is_inactive,
            item_name,
            item_type,
            -- normalize timestamp for safe comparisons & merge
            last_modified_date::timestamp_ntz as last_modified_date,
            last_purchase_price,
            location_id,
            manufacturer,
            maximum_quantity,
            parent_id,
            pricing_group,
            total_quantity_on_hand,
            sale_unit,
            shipping_cost,
            stock_unit,
            store_description,
            store_detailed_description,
            store_display_name,
            subsidiary_id,
            sub_type,
            total_value,
            units_type,
            vendor_name,
            weight,

            --surrogate key
            {{ dbt_utils.generate_surrogate_key(["item_id"]) }} as item_surr_key

        -- Optional lineage if you want it in the dim:
        -- , dbt_valid_from as effective_from
        -- , dbt_scd_id     as scd_id
        from current_snapshot i

        {% if is_incremental() %}
            where
                last_modified_date::timestamp_ntz >= (
                    select dateadd(
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

-- dbt will use this as the USING subquery of MERGE
select *
from source_rows
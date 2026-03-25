{% snapshot snp_item %}
{{
    config(
        unique_key="item_id",
        strategy="check",
        check_cols= 'all',
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
    )
}}

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
    last_modified_date,
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
    weight

  from {{ ref('item') }}

{% endsnapshot %}


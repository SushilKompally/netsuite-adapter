{#
-- Description: Incremental Load Script for Silver Layer - item Table
-- Script Name: silver_items.sql
-- Created on: 23-dec-2025
-- Author: Sushil Kumar Kompally
-- Purpose:
--     Incremental load from Bronze to Silver for NetSuite items.
-- Data source version: v62.0
-- Change History:
--     23-dec-2025 - Initial creation - Sushil Kompally
#}
{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="item_id",
        on_schema_change="append_new_columns",
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
    )
}}

with
    raw as (

        select *
        from {{ source("netsuite_bronze", "item") }}
        where
            1 = 1
            {% if is_incremental() %}
                and lastmodifieddate >= (select max(last_modified_date) from {{ this }})
            {% endif %}
    ),

    cleaned as (

        select
            -- PRIMARY KEY
            {{ safe_integer("id") }} as item_id,

            -- FOREIGN KEYS
            {{ safe_integer("class") }} as class_id,
            {{ safe_integer("department") }} as department_id,
            {{ safe_integer("incomeaccount") }} as income_account,
            {{ safe_integer("location") }} as location_id,
            {{ safe_integer("parent") }} as parent_id,
            {{ safe_integer("pricinggroup") }} as pricing_group,
            {{ safe_integer("saleunit") }} as sale_unit,
            {{ safe_integer("stockunit") }} as stock_unit,
            {{ safe_integer("SUBSIDIARY") }} as subsidiary_id,
            {{ safe_integer("unitstype") }} as units_type,

            -- DETAILS
            {{ safe_decimal("averagecost", 18, 6) }} as average_cost,
            {{ safe_decimal("cost", 18, 6) }} as cost,
            {{ clean_string("costingmethod") }} as costing_method,
            {{ clean_string("description") }} as description,
            {{ clean_string("displayname") }} as display_name,
            {{ clean_string("fullname") }} as item_full_name,
            {{ clean_string("ITEMid") }} as item_name,
            {{ clean_string("ITEMtype") }} as item_type,
            {{ safe_decimal("lastpurchaseprice", 18, 6) }} as last_purchase_price,
            {{ clean_string("manufacturer") }} as manufacturer,
            {{ safe_integer("maximumquantity") }} as maximum_quantity,
            {{ clean_string("storedescription") }} as store_description,
            {{ clean_string("storedetaileddescription") }}
            as store_detailed_description,
            {{ clean_string("storedisplayname") }} as store_display_name,
            {{ clean_string("subtype") }} as sub_type,
            {{ safe_decimal("totalvalue", 18, 6) }} as total_value,
            {{ clean_string("vendorname") }} as vendor_name,
            {{ safe_decimal("weight", 18, 6) }} as weight,
            {{ safe_decimal("shippingcost", 18, 6) }} as shipping_cost,
            {{ safe_boolean("isfulfillable") }} as is_ful_fillable,
            {{ safe_boolean("isinactive") }} as is_inactive,
            {{ safe_decimal("totalquantityonhand") }} as total_quantity_on_hand,

            -- DATES / TIMESTAMPS
            {{ safe_timestamp_ntz("createddate") }} as created_date,
            {{ safe_timestamp_ntz("lastmodifieddate") }} as last_modified_date,

            -- AUDIT / METADATA
            {{ safe_timestamp_ntz("CURRENT_TIMESTAMP()") }} as silver_load_date

        from raw
        where _fivetran_deleted = false
    )

select *
from cleaned

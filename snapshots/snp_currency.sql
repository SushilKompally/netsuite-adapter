{% snapshot snp_currency %}

{{
    config(
      unique_key='currency_id',
      strategy='timestamp',
      updated_at='last_modified_date',
      full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
      invalidate_hard_deletes=True
    )
}}

with silver_currency as (
    -- Reference your silver model here
    select * from {{ ref('currencies') }} 
),

final as (
    select
        -- PRIMARY KEY
        currency_id,

        -- ATTRIBUTES
        currency_name,
        display_symbol,
        exchange_rate,
        
        -- FLAGS
        is_inactive,
        is_base_currency,

        -- METADATA
        last_modified_date,
        silver_load_date

    from silver_currency
)

select * from final

{% endsnapshot %}
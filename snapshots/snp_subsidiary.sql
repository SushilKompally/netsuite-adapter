{% snapshot snp_subsidiary %}
    {{
        config(
            unique_key="subsidiary_id",
            strategy="check",
            full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
            check_cols=[
                "subsidiary_id",
                "currency_id",
                "subsidiary_full_name",
                "is_inactive",
                "subsidiary_name",
                "parent_id",
            ],
        )
    }}

    select
        subsidiary_id,
        currency_id,
        subsidiary_full_name,
        is_inactive,
        subsidiary_name,
        parent_id,
        silver_load_date

    from {{ ref("subsidiaries") }}

{% endsnapshot %}

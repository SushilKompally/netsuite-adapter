{% snapshot snp_accounting_period %}
{{
    config(
        unique_key="posting_period_id",
        strategy="check",
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
        check_cols=[
            "closed_on_date",
            "last_modified_date",
            "end_date",
            "start_date",
            "period_name",
            "year"

        ]
    )
}}

select
    posting_period_id,
    closed_on_date,
    last_modified_date,
    end_date,
    start_date,
    period_name,
    year,
    silver_load_date
from {{ ref("accounting_period") }}

{% endsnapshot %}


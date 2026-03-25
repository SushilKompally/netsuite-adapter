{% snapshot snp_classification %}
{{
    config(
        unique_key="class_id",
        strategy="check",
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
        check_cols=[
            "class_full_name",
            "is_inactive",
            "last_modified_date",
            "class_name",
            "parent"
        ]
    )
}}

select
    class_id,
    class_full_name,
    is_inactive,
    last_modified_date,
    class_name,
    parent,
    silver_load_date
from {{ ref("classification") }} 

{% endsnapshot %}

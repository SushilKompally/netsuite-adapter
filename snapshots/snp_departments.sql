{% snapshot snp_departments %}
    {{
        config(
            unique_key="department_id",
            strategy="check",
            full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
            check_cols=[
                "department_id",
                "department_name",
                "department_full_name",
                "is_inactive",
                "parent"
            ]
        )
    }}

    select
        department_id,
        department_name,
        department_full_name,
        is_inactive,
        parent,
        last_modified_date,

    from {{ ref("departments") }}

{% endsnapshot %}

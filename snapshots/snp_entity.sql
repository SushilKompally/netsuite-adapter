{% snapshot snp_entity %}
{{
    config(
        unique_key="internal_entity_id",
        strategy="check",
        check_cols= 'all',
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
    )
}}

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
    last_modified_date,
    last_name,
    parent_id,
    partner_id,
    entity_type,
    vendor_id

  from {{ ref('entity') }}

{% endsnapshot %}


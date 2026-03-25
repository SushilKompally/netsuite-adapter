{% snapshot snp_locations
 %}
{{
    config(
        unique_key="location_id",
        strategy="check",
        check_cols= 'all',
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
    )
}}

select
    location_id,
    location_name,
    location_full_name,
    is_inactive,
    last_modified_date,
    latitude,
    longitude,
    location_type,
    parent,
    subsidiary_id

  from {{ ref('locations') }}

{% endsnapshot %}


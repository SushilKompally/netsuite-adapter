{% snapshot snp_employees %}
{{
    config(
        unique_key="employee_id",
        strategy="check",
        check_cols= 'all',
        full_refresh=(modules.datetime.datetime.now().strftime("%A") == "Monday"),
    )
}}

select
    EMPLOYEE_ID,
    ENTITY_ID,
    EMAIL,
    TITLE,
    JOB_DESCRIPTION,
    CLASS_ID,
    CURRENCY,
    DEPARTMENT_ID,
    DATE_CREATED,
    EMPLOYEE_TYPE_ID,
    ACCOUNT_NUMBER,
    LOCATION_ID,
    EMPLOYEE_STATUS_ID,
    IS_INACTIVE,
    SUBSIDIARY,
    LAST_MODIFIED_DATE,

  from {{ ref('employees') }}

{% endsnapshot %}


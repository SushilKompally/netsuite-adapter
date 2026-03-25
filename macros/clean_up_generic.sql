
{# ---------------------------------------------------------
# Strings: trim + NULL if empty
# --------------------------------------------------------- #}
{% macro clean_string(col, tool_name='snowflake') -%}
nullif(trim(to_varchar({{ col }})), '')
{%- endmacro %}

{% macro clean_int(col, tool_name='snowflake') -%}
  -- try_to_number returns a number, so we don't need trim() (which is for strings)
  try_cast({{ col }} as number)
{%- endmacro %}

{% macro clean_string_lower(col, tool_name='snowflake') -%}
lower(nullif(trim(to_varchar({{ col }})), ''))
{%- endmacro %}


{# ---------------------------------------------------------
# Numerics: safe integer / decimal
# --------------------------------------------------------- #}
{% macro safe_integer(col, tool_name='snowflake') -%}
-- Returns NUMBER(38,0) for integer-like fields (IDs, counts)
cast(try_to_number({{ col }}) as number(38,0))
{%- endmacro %}

{% macro safe_decimal(col, precision=18, scale=2, tool_name='snowflake') -%}
-- Returns DECIMAL(precision, scale); 
-- We cast to to_varchar first to avoid direct numeric-to-numeric TRY_CAST errors
try_to_decimal(to_varchar({{ col }}), {{ precision }}, {{ scale }})
{%- endmacro %}

{% macro safe_float(col, tool_name='snowflake') -%}
-- Floating-point when exact precision isn’t required
try_to_double({{ col }})
{%- endmacro %}


{# ---------------------------------------------------------
# Boolean: normalize common representations (1/0, Y/N, T/F)
# --------------------------------------------------------- #}
{% macro safe_boolean(col, tool_name='snowflake') -%}
case
  when {{ col }} is null then null
  when upper(trim(to_varchar({{ col }}))) in ('TRUE','T','YES','Y','1') then true
  when upper(trim(to_varchar({{ col }}))) in ('FALSE','F','NO','N','0') then false
  else null
end
{%- endmacro %}


{# ---------------------------------------------------------
# Date: guard blanks/invalid and cutoff
# --------------------------------------------------------- #}
{% macro safe_date(col, default_date="1900-01-01", tool_name='snowflake') -%}
coalesce(
  case
    when nullif(trim(to_varchar({{ col }})), '') is null then null
    when try_to_date(to_varchar({{ col }})) is null then null
    when try_to_date(to_varchar({{ col }})) <= date '{{ default_date }}' then null
    else try_to_date(to_varchar({{ col }}))
  end,
  date '{{ default_date }}'
)
{%- endmacro %}



{# ---------------------------------------------------------
# Timestamp (TIMESTAMP_NTZ): guard blanks/invalid
# --------------------------------------------------------- #}
{% macro safe_timestamp_ntz(col, default_date="1900-01-01", tool_name='snowflake') -%}
coalesce(
  case
    when nullif(trim(to_varchar({{ col }})), '') is null then null
    when try_to_timestamp_ntz(to_varchar({{ col }})) is null then null
    else try_to_timestamp_ntz(to_varchar({{ col }}))
  end,
  to_timestamp_ntz('{{ default_date }} 00:00:00')
)
{%- endmacro %}


{% macro gen_surrogate_key(id_expr) %}
  {{ dbt_utils.generate_surrogate_key([
      "'{{ var('source_database') }}'",
      "'{{ var('source_schema') }}'",
      id_expr
  ]) }}
{% endmacro %}
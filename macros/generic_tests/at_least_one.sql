{% test at_least_one(model, column_name, group_by_columns = []) %}
  {{ return(adapter.dispatch('test_at_least_one', 'dbt_utils')(model, column_name, group_by_columns)) }}
{% endtest %}

{% macro default__test_at_least_one(model, column_name, group_by_columns) %}

{% set pruned_cols = [column_name] %}

{% if group_by_columns|length() > 0 %}

  {% set select_gb_cols = group_by_columns|join(' ,') + ', ' %}
  {% set groupby_gb_cols = 'group by ' + group_by_columns|join(',') %}
  {% set pruned_cols = group_by_columns %}

  {% if column_name not in pruned_cols %}
    {% do pruned_cols.append(column_name) %}
  {% endif %}

{% endif %}

{% set select_pruned_cols = pruned_cols|join(' ,') %}

select *
from (
    with pruned_rows as (
      select
        {{ select_pruned_cols }}
      from {{ model }}
      {% if group_by_columns|length() == 0 %}
        where {{ column_name }} is not null
        limit 1
      {% endif %}
    )
    select
        {# In TSQL, subquery aggregate columns need aliases #}
        {# thus: a filler col name, 'filler_column' #}
      {{select_gb_cols}}
      count({{ column_name }}) as filler_column

    from pruned_rows

    {{groupby_gb_cols}}

    having count({{ column_name }}) = 0

) validation_errors

{% endmacro %}


{% macro fabric__test_at_least_one(model, column_name, group_by_columns) %}

{% set pruned_cols = [column_name] %}

{% if group_by_columns|length() > 0 %}

  {% set select_gb_cols = group_by_columns|join(' ,') + ', ' %}
  {% set groupby_gb_cols = 'group by ' + group_by_columns|join(',') %}
  {% set pruned_cols = group_by_columns %}

  {% if column_name not in pruned_cols %}
    {% do pruned_cols.append(column_name) %}
  {% endif %}

{% endif %}

{% set select_pruned_cols = pruned_cols|join(' ,') %}

  select * 
  from (
    select 
      COUNT({{ column_name }}) AS filler_column
  FROM (
      SELECT 
          {{ select_pruned_cols }}
      FROM 
          {{ model }}
      WHERE 
          {{ column_name }} is not null 
      ORDER BY 
          (SELECT NULL) 
      OFFSET 0 ROWS FETCH FIRST 1 ROWS ONLY
  ) AS pruned_rows
  HAVING 
      COUNT({{ column_name }}) = 0
  ) validation_errors

{% endmacro %}

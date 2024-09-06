{% if target.type == 'fabric' %}

    {{
        dbt_utils.deduplicate(
            ref('data_deduplicate') ,
            partition_by='user_id',
            order_by='version desc',
        ) | indent
    }}

{% else %}

    with source as (
    select *
    from {{ ref('data_deduplicate') }}
    where user_id = 1
    ),

    deduped as (

        {{
            dbt_utils.deduplicate(
                'source',
                partition_by='user_id',
                order_by='version desc',
            ) | indent
        }}

    )

    select * from deduped
{% endif %}
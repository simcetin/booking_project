{{ config(
        materialized='incremental'
        , unique_key = ['booking_event_id']
    )
}}
select
    booking_event_id
    , booking_id
    , event_type
    , old_value
    , new_value
    , status
    , created_at
    , source
    , calendar_id
    , event_owner_type
    , current_timestamp(0) as _dbt_insert_at
from {{ source('staging_doc_planner_external', 'external_booking_events') }}
{% if is_incremental() %}
    -- this filter will only be applied on an incremental run
    where created_at > coalesce((select max({{ this }}.created_at) from {{ this }}), '1900-01-01 00:00:00')
{% endif %}
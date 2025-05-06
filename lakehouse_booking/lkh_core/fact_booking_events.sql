{{ config(
        materialized='incremental'
        , unique_key = ['booking_event_id']
    )
}}

with union_booking_events as (
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
from {{ ref('stg_docplanner__patient_bookings_events') }}
{% if is_incremental() %}
    -- this filter will only be applied on an incremental run taken into consideration late-arrival data.
    where _dbt_insert_at > (select max({{ this }}._dbt_insert_at) from {{ this }})
{% endif %}
union all
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
from {{ ref('stg_docplanner_external__booking_events') }}
{% if is_incremental() %}
    -- this filter will only be applied on an incremental run taken into consideration late-arrival data.
    where _dbt_insert_at > (select max({{ this }}._dbt_insert_at) from {{ this }})
{% endif %}
)

select 
*
, current_timestamp(0) as _dbt_insert_at
from union_booking_events
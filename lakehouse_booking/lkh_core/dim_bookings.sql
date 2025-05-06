with union_bookings as (
select
    booking_id
    , patient_id
    , booking_type
    , booked_by
    , calendar_id as booked_calendar_id
    , doctor_id
    , booking_date_time
from {{ ref('stg_docplanner__patient_bookings') }}
union all
select
    booking_id
    , patient_id
    , booking_type
    , booked_by
    , calendar_id as booked_calendar_id
    , doctor_id
    , booking_date_time
from {{ ref('stg_docplanner_external__bookings') }}
)

select 
*
from union_bookings
select
    booking_id
    , patient_id
    , booking_type
    , booked_by
    , calendar_id
    , doctor_id
    , booking_date_time
from {{ source('staging_doc_planner', 'patient_bookings') }}

select
    calendar_id
    , doctor_id
    , clinic_id
    , calendar_type
    , clinic_name
    , location_address
    , service_type
    , calendar_status
    , created_at
    , updated_at
    , coalesce(removed_at, '{{ var("in_long_time") }}') as removed_at
from {{ ref('stg_docplanner__calendars') }}
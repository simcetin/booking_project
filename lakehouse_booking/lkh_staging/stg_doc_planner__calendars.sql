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
    , removed_at
from {{ source('staging_doc_planner', 'calendars') }}

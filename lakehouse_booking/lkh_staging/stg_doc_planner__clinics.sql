select
    clinic_id
    , clinic_name
    , clinic_address
    , is_independent
from {{ source('staging_doc_planner', 'clinics') }}
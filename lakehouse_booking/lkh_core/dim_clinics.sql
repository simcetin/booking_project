select
    clinic_id
    , clinic_name
    , clinic_address
    , is_independent
from {{ ref('stg_docplanner__clinics') }}
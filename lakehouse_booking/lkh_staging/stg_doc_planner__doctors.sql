select
    doctor_id
    , name
    , surname
    , email
    , phone_number
    , specialization
    , created_at
    , updated_at
from {{ source('staging_doc_planner', 'doctors') }}
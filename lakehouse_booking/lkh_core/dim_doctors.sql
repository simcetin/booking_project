select
    doctor_id
    , name
    , surname
    , email
    , phone_number
    , specialization
    , created_at
    , updated_at
from {{ ref('stg_docplanner__doctors') }}
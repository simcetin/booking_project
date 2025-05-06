select
    patient_id
    , patient_name
    , patient_surname
    , patient_age
    , gender
    , created_at
from {{ ref('stg_docplanner__patients') }}
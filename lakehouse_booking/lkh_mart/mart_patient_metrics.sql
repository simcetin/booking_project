select
    year_month
    , sum(number_of_bookings) as nb_of_patient_bookings
    , sum(number_of_bookings_w_mobile_app) as nb_of_patient_bookings_w_mobile_app
    , count(case when is_rebooking then 1 else 0 end) as nb_of_patient_rebookings
    , count(case when is_engaged_month then 1 else 0 end) as nb_of_engaged_patients
    , (nb_of_patient_rebookings/nb_of_patient_bookings)*100 as rebooking_patient_booking_rate
    , (nb_of_patient_bookings_w_mobile_app/nb_of_patient_bookings)*100 as mobile_booking_patient_rate
from {{ ref('fact_patients_engagement') }}
group by all
with doctors_monthly_prep as (
    select
        calendar_booking.date_day
        , calendar_booking.year_month
        , calendar_booking.booked_calendar_id
        , calendar_booking.patient_id
        , calendar_booking.booking_id
        , calendar_booking.doctor_id
        , calendar_booking.booking_date_time::date as booked_date
        , fact_doctors_engagement.first_engaged_month
        , fact_doctors_engagement.is_engaged_month
        , fact_doctors_engagement.is_first_engaged_month
    from {{ ref('fact_booking_calendar_daily') }} as calendar_booking
    left join {{ ref('fact_booking_events') }}
        on calendar_booking.date_day = fact_booking_events.created_at::date
            and calendar_booking.booked_calendar_id = fact_booking_events.calendar_id
            and calendar_booking.booking_id = fact_booking_events.booking_id
    left join {{ ref('fact_doctors_engagement') }}
        on calendar_booking.year_month = fact_doctors_engagement.year_month
            and calendar_booking.doctor_id = fact_doctors_engagement.doctor_id
    where
        fact_booking_events.event_type = 'booking-created'
        and lower(fact_booking_events.status) = 'confirmed'
)


select
    year_month
    , doctor_id
    , is_engaged_month
    , first_engaged_month
    , is_first_engaged_month
    , count(booking_id) as nb_of_bookings
    , count(distinct patient_id) as nb_of_unique_patient_visits
    , count(case when is_first_engaged_month then booking_id end) as nb_of_bookings_first_engaged_month
    , count(distinct case when is_first_engaged_month then patient_id end) as nb_of_unique_patient_visits_first_engaged_month
    , count(case when is_engaged_month then booking_id end) as nb_of_bookings_engaged_month
    , count(distinct case when is_engaged_month then patient_id end) as nb_of_unique_patient_visits_engaged_month
    , nb_of_unique_patient_visits_engaged_month >= 3 then has_at_least_3_patient_bookings_in_engaged_month
    , nb_of_unique_patient_visits_first_engaged_month >=1 then has_at_least_1_patient_bookings_in_first_engaged_month
    , nb_of_unique_patient_visits_first_engaged_month >=2 then has_at_least_2_patient_bookings_in_first_engaged_month
from doctors_monthly_prep
group by all
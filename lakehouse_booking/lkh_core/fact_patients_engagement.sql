-- step 1: prepare detailed booking data per patient per day
with patient_eng_prep as (
    select
        calendar_booking.date_day,                              -- calendar date of booking
        calendar_booking.year_month,                            -- year and month of booking (e.g., '2025-04')
        calendar_booking.booked_calendar_id,                    -- id of calendar (doctor’s schedule) where booking was made
        calendar_booking.patient_id,                            -- id of the patient who booked
        calendar_booking.booking_id,           -- unique booking id
        calendar_booking.doctor_id,                             -- id of the doctor associated with the booking
        calendar_booking.booking_date_time::date as booked_date, -- actual date of booking
        fact_booking_events.source as booking_creating_source,     -- source used for booking (e.g., 'mobile app', 'desktop', etc.)
        -- next booking for the same patient (used to check rebooking behavior)
        lead(booked_date) over(partition by calendar_booking.patient_id order by booked_date) as next_booking_date,
        -- previous booking for the same patient (used to calculate gaps between visits)
        lag(booked_date) over(partition by calendar_booking.patient_id order by booked_date) as previous_booking_date,
        -- boolean flag: true if the patient rebooks within 30 days of the previous booking
        datediff('days', previous_booking_date, booked_date) <= 30 as is_rebooking
    from {{ ref('fact_booking_calendar_daily') }} as calendar_booking
    left join {{ ref('fact_booking_events') }}
        on calendar_booking.date_day = fact_booking_events.created_at::date
        and calendar_booking.booked_calendar_id = fact_booking_events.calendar_id
        and calendar_booking.booking_id = fact_booking_events.booking_id
    where 
        event_type = 'booking-created'               -- only look at created booking events
        and lower(status) = 'confirmed'              -- only confirmed bookings count
        and booked_by like '%patient%'               -- only include bookings made by patients
)

-- step 2: count monthly bookings per patient
, number_of_bookings_cte as (
    select
        year_month,
        patient_id,
        -- total number of bookings in that month
        count(booking_id) as number_of_bookings,
        -- number of those bookings that were made via the mobile app
        count(case when lower(booking_creating_source) = 'mobile app' then booking_id end) as number_of_bookings_w_mobile_app
    from patient_eng_prep
    group by year_month, patient_id
)

-- step 3: identify engaged months per patient based on defined criteria
select 
    patient_eng_prep.year_month,
    patient_eng_prep.patient_id,
    number_of_bookings_cte.number_of_bookings,
    number_of_bookings_cte.number_of_bookings_w_mobile_app,
    patient_eng_prep.is_rebooking,
    -- flag the month as "engaged" if:
    -- (1) patient made booking in previous month
    -- (2) patient had at least 2 bookings in this month
    -- (3) at least 1 was via mobile app
    max(
        datediff('months', previous_booking_date, booked_date) = 1
        and number_of_bookings >= 2
        and number_of_bookings_w_mobile_app >= 1
    ) as is_engaged_month
from patient_eng_prep
left join number_of_bookings_cte
    on patient_eng_prep.year_month = number_of_bookings_cte.year_month
    and patient_eng_prep.patient_id = number_of_bookings_cte.patient_id
group by all
with doctor_engagement_prep as (
    select
        calendar_booking.date_day,
        calendar_booking.year_month,
        calendar_booking.is_full_week,
        calendar_booking.booked_calendar_id,
        calendar_booking.booking_id,
        calendar_booking.beginning_of_week,
        calendar_booking.doctor_id,
        calendar_booking.booking_date_time::date as booked_date,
        fact_booking_events.source as booking_creating_source,
        -- Bookings created within a full week window
        is_full_week 
            and (booking_date_time::date between beginning_of_week and end_of_week) 
            as is_booked_within_full_week,
        -- Bookings created within a full week AND via mobile app
        is_full_week 
            and (booking_date_time::date between beginning_of_week and end_of_week) 
            and lower(booking_creating_source) = 'mobile app'
            as is_booked_within_full_week_with_mobile_app
    from {{ ref('fact_booking_calendar_daily') }} as calendar_booking
    left join {{ ref('fact_booking_events') }}
        on calendar_booking.date_day = fact_booking_events.created_at::date
        and calendar_booking.booked_calendar_id = fact_booking_events.calendar_id
    where 
        --- take only valid booking creations where status is confirmed
        fact_booking_events.event_type = 'booking-created'
        and lower(fact_booking_events.status) = 'confirmed'
        and calendar_booking.booked_by = 'doctor'  -- only count doctor-side bookings
)

-- Aggregate weekly engagement flags
, flag_engaged_week as (
    select 
        year_month,
        beginning_of_week,
        doctor_id,
        -- Bookings count made during full weeks
        count(case when is_booked_within_full_week then booking_id end) 
            as number_of_bookings_within_full_week,
        -- Bookings made via mobile app during full weeks
        count(case when is_booked_within_full_week_with_mobile_app then booking_id end) 
            as number_of_bookings_within_full_week_with_mobile_app,
        -- Weekly engagement flag based on thresholds (5 bookings + 1 mobile)
        case 
            when number_of_bookings_within_full_week >= 5 
              and number_of_bookings_within_full_week_with_mobile_app >= 1 
            then 1 else 0 
        end as is_engaged_week
    from doctor_engagement_prep
    group by all
)

-- Count number of engaged weeks per doctor and month
, number_of_engagement_week as (
    select
        calendar_booking.year_month,
        calendar_booking.doctor_id,
        -- Count how many weeks the doctor was engaged in a month
        count(distinct calendar_booking.beginning_of_week) 
            as count_of_engagement_week
    from {{ ref('fact_booking_calendar_daily') }} as calendar_booking
    left join flag_engaged_week 
        on calendar_booking.year_month = flag_engaged_week.year_month
        and calendar_booking.beginning_of_week = flag_engaged_week.beginning_of_week
        and calendar_booking.doctor_id = flag_engaged_week.doctor_id
    where is_engaged_week = 1
    group by all
)

-- Final calculation: flag engaged months and identify first engagement
select 
    calendar_booking.year_month,
    calendar_booking.doctor_id,
    number_of_engagement_week.count_of_engagement_week,
    -- Engagement status for  month: doctor is engaged for all full weeks in a month
    coalesce(number_of_engagement_week.count_of_engagement_week >= calendar_booking.number_of_full_weeks, false) 
        as is_engaged_month,
    -- Find the first month the doctor became engaged
    min(case when is_engaged_month then calendar_booking.year_month end) 
        as first_engaged_month,
    -- Check if the given month is the first engaged month for the doctor
    coalesce(first_engaged_month = calendar_booking.year_month, false) 
        as is_first_engaged_month
from {{ ref('fact_booking_calendar_daily') }} as calendar_booking
left join number_of_engagement_week 
    on calendar_booking.year_month = number_of_engagement_week.year_month
    and calendar_booking.doctor_id = number_of_engagement_week.doctor_id
group by all

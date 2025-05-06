select 
        dim_dates.date_day,                          -- specific calendar date
        dim_dates.year_month,                        -- month extracted from date
        dim_dates.is_full_week,                      -- boolean: if date falls within a full week
        dim_dates.beginning_of_week,                 -- first day of the week
        dim_dates.end_of_week,                       -- last day of the week
        dim_calendars.calendar_id,                   -- ID of the calendar where booking occurred
        dim_dates.number_of_full_weeks,              -- number of full weeks in the given month
        --- all booking fields
        booking.booking_id,
        booking.patient_id,
        booking.booking_type,
        booking.booked_by,
        booking.booked_calendar_id,
        booking.doctor_id,
        booking.booking_date_time,
        , {{ dbt_utils.generate_surrogate_key([
	    "dim_dates.date_day",
	    "booking.booking_id"
	    ]) }} as booking_calendar_daily_pk
    from {{ ref('dim_dates') }}
    inner join {{ ref('dim_calendars') }}
        on date_trunc('month', dim_dates.date_day)
    --generate a date_day row for each calendar active duration
    --starting from when calendar was created 
    --if the calendar is removed until the removal date.
           between date_trunc('month', dim_calendars.created_at::date)
               and date_trunc('month', dim_calendars.removed_at::date)
    ---The bookings made for a given day
    left join  {{ ref('dim_bookings') }} as booking 
        on booking.booking_date_time::date = dim_dates.date_day
        and dim_calendars.calendar_id = booking.booked_calendar_id
    ---- show the bookings until current date 
    where date_trunc('month', dim_dates.date_day) <= date_trunc('month', current_date())  -- exclude future months
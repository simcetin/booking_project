with calendar_dates as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="'2025-01-01'::date",
        end_date="'2026-01-01'::date"
    ) }}
)

, calendar_prep as (
select 
    date_day::date as date_day
    ---beginning of the month
    , date_trunc('month', date_day::date) as year_month
    -- flag whether the week that the date belongs to 
    -- contains exactly 7 days within the same month. This defines the week as full week.
    , coalesce(count(*) over (partition by year_month, weekofyear(date_day)) = 7, false) as is_full_week
    , date_trunc('week', date_day) as beginning_of_week
    , dayofweek(date_day) as day_of_week
    , max(case when day_of_week = 1 then date_day + 6 end) over (partition by beginning_of_week) as end_of_week
from calendar_dates
)

, number_of_full_weeks_each_month as (
select 
year_month
, count (distinct case when is_full_week then beginning_of_week end) as number_of_full_weeks
from calendar_prep
where is_full_week
group by 1
)

select 
calendar_prep.*
, number_of_full_weeks_each_month.number_of_full_weeks
from calendar_prep
left join 
number_of_full_weeks_each_month
on calendar_prep.year_month = number_of_full_weeks_each_month.year_month
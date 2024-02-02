use hr;

select * 
from [HR Data];

select termdate
from [HR Data]
order by termdate desc

update [HR Data]
set termdate =format(CONVERT(DATETIME, LEFT(termdate,19),120),'yyyy-MM-dd');

alter table [HR Data]
add new_termdate date;

--copy converted values to new_termdate from termdate
update [HR Data]
set new_termdate =CASE
when termdate is not null and ISDATE(termdate)=1 then CAST(termdate as datetime) else null end;

--create a new column age
alter table [HR Data]
add age nvarchar(50);

--populate new column with age
update [HR Data]
set age=DATEDIFF(YEAR, birthdate, GETDATE());

select age
from [HR Data]

--Questions to answer from data
--1)	What's the age distribution in the company?
--age distribution

select 
MAX(age) as oldest,
MIN(age) as youngest
from [HR Data]

--age group by gender
select age_group,gender,
count(*) as count
from
	(select
		case 
			when age<=22 and age<=30 then '22 to 30'
			when age<=31 and age<=40 then '31 to 40'
			when age<=41 and age<=50 then '41 to 50'
			when age<=51 and age<=60 then '51 to 60'
			else '50+'
		end as age_group,gender
	from [HR Data]
	where new_termdate is null
	) as sub_query
group by age_group,gender
order by age_group,gender

--2)	What's the gender breakdown in the company?
select gender,
count(gender) as count
from [HR Data]
where new_termdate is null
group by gender
order by gender asc

--3)	How does gender vary across departments and job titles?
select department,gender,
count(gender) as count
from [HR Data]
where new_termdate is null
group by department,gender
order by department,gender asc

--job titles
select department,jobtitle,gender,
count(gender) as count
from [HR Data]
where new_termdate is null
group by department,jobtitle,gender
order by department,jobtitle,gender asc

--4)	What's the race distribution in the company?
select race, count(race) as count
from [HR Data]
where new_termdate is null
group by race
order by count desc;

--5)	What's the average length of employment in the company?
select
avg(datediff(year, hire_date, new_termdate)) as tenure
from [HR Data]
where new_termdate is not null and new_termdate<=GETDATE()

--6)	Which department has the highest turnover rate?
--get total count
--get terminated count
--terminated count/total count
select
	department,
	total_count,
	terminated_count,
	(round((cast(terminated_count as float)/total_count),2))*100 as turnover_rate
	from
		(select 
			department,
			count(*) as total_count,
			sum(case when new_termdate is not null and new_termdate<=getdate() then 1 else 0
				end) as terminated_count
		from [HR Data]
		group by department
		) as sub_query
	order by turnover_rate desc

--7)	What is the tenure distribution for each department?
select department,
avg(datediff(year, hire_date, new_termdate)) as tenure
from [HR Data]
where new_termdate is not null and new_termdate<=GETDATE()
group by department
order by tenure desc

--8)	How many employees work remotely?
select location,
count(*) as count
from [HR Data]
where new_termdate is null
group by location

--9)	What's the distribution of employees across different states?
select location_state,
count(*) as count
from [HR Data]
where new_termdate is null
group by location_state
order by count desc

--10)	How are job titles distributed in the company?
select jobtitle,
count(*) as count
from [HR Data]
where new_termdate is null
group by jobtitle
order by count desc

--11)	How have employee hire counts varied over time?
--calculate hires
--calculate terminations
--(hire-terminations)/hires percentage hire change
select
	hire_year,
	hires,
	terminations,
	hires-terminations as net_change,
	(round(cast(hires-terminations as float)/hires,2))*100 as percent_hire_change
	from
		(select
		YEAR(hire_date) as hire_year,
		count(*) as hires,
		sum(case
				when new_termdate is not null and new_termdate <= GETDATE() then 1 else 0
				end
				) as terminations
		from [HR Data]
		group by year(hire_date)
		) as subquery
	order by percent_hire_change asc
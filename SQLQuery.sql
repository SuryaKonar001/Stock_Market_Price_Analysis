select * from INFOSYS

select * from [TATA CONSULTANCY SERVICES]

select * from WIPRO

--Adding a new column Symbol to the tables
alter table INFOSYS
add Symbol varchar(10)

update INFOSYS
set [Symbol]='INFOSYS'

alter table [TATA CONSULTANCY SERVICES]
add Symbol varchar(10)

update [TATA CONSULTANCY SERVICES]
set [Symbol]='TCS'

alter table WIPRO
add Symbol varchar(10)

update WIPRO
set [Symbol]='WIPRO'

drop view if exists A1
create view A1 as (select Symbol, High, Low from INFOSYS where High is not null or Low is not null 
union 
select Symbol, High, Low from [TATA CONSULTANCY SERVICES] where High is not null or Low is not null
union
select Symbol, High, Low from WIPRO where High is not null or Low is not null);

select * from A1;

--Union removes all duplicate rowa. So in A1 we can see only 3 NULL rows whereas originally there are 7,7,9 NULL rows



----------------------------------VOLATILITY Calculation
select Symbol,ROUND(avg(High-Low),2) as Avg_Volatility, DENSE_RANK() over(order by avg(High-Low) asc)
as Ranking from A1
group by Symbol;
--WIPRO has minimum volatility and TCS has maximum volatility



---------------------------------Drawdown/Fall in Stock Price Calculation during Covid Period

-------INFOSYS
--Finding the date where the Close Price fell to the minimum during covid period
select *
from Infosys
where Date between '2020-01-01' and '2021-12-31' and [Close] is not null
order by [Close] asc
--The lowest close was on 2020-03-23

--Finding the date before the lowest Close where the Close Price was maximum during covid period
select *
from Infosys
where Date between '2020-01-01' and '2020-03-23' and [Close] is not null
order by [Close] desc
--The max close in the covid period before the fall is 2020-02-19

drop view if exists A2
create view A2 as(select Date, Symbol, [Close] from Infosys where Date='2020-03-23'
union
select Date, Symbol, [Close] from Infosys where Date='2020-02-19')
select * from A2

select ROUND((-max([Close])+min([Close]))/max([Close]),4)*100 as Infosys_Drawdown
from A2
--INFOSYS drawdown is -34.23



----------TCS
--Finding the date where the Close Price fell to the minimum during covid period
select *
from [TATA CONSULTANCY SERVICES]
where Date between '2020-01-01' and '2021-12-31' and [Close] is not null
order by [Close] asc
--The lowest close was on 2020-03-19

--Finding the date before the lowest Close where the Close Price was maximum during covid period
select *
from [TATA CONSULTANCY SERVICES]
where Date between '2020-02-01' and '2020-03-19' and [Close] is not null
order by [Close] desc
--The max close in the covid period before the fall is 2020-02-18





-----------------------------------------Drawdown/Fall in Stock Price Calculation during Covid Period from Feb to March for all the companies

drop view if exists A3
create view A3 as(select Date, Symbol, [Close] from Infosys where Date between '2020-02-01' and '2020-03-31' and [Close] is not null
union
select Date, Symbol, [Close] from [TATA CONSULTANCY SERVICES] where Date between '2020-02-01' and '2020-03-31' and [Close] is not null
union
select Date, Symbol, [Close] from WIPRO where Date between '2020-02-01' and '2020-03-31' and [Close] is not null)
select * from A3

select Symbol,MAX([Close]) as Max_Close,MIN([Close]) as Min_Close, round((MIN([Close])-MAX([Close]))/MAX([Close]),4)*100 as Drawdown
from A3
group by Symbol
--WIPRO has the maximum Drawdown and TCS has the minimum Drawdown



--------------------------------------------------Recovery Days
drop view if exists A4
create view A4 as(
select Date,Symbol from
(select Date,Symbol,[Close],row_number() over(order by Date asc) as Date_Number_MaxCloseRecovered
from INFOSYS
where Date between '2020-03-23' and '2021-03-31' and [Close]>=(select max([Close]) from A3 where Symbol='INFOSYS')
union
select Date,Symbol,[Close],row_number() over(order by Date asc) as Date_Number_MaxCloseRecovered
from [TATA CONSULTANCY SERVICES]
where Date between '2020-03-19' and '2021-03-31' and [Close]>=(select max([Close]) from A3 where Symbol='TCS')
union
select Date,Symbol,[Close],row_number() over(order by Date asc) as Date_Number_MaxCloseRecovered
from WIPRO
where Date between '2020-03-19' and '2021-03-31' and [Close]>=(select max([Close]) from A3 where Symbol='WIPRO')) as D
where D.Date_Number_MaxCloseRecovered=1)

select * from A4
--converting the view into a temptable to add a new column
select * 
into #temptable
from A4

alter table #temptable
add Min_Close_Date Date

select* from #temptable

update #temptable set Min_Close_Date = '2020-03-23' where Symbol = 'INFOSYS'
update #temptable set Min_Close_Date = '2020-03-19' where Symbol = 'TCS'
update #temptable set Min_Close_Date = '2020-03-19' where Symbol = 'WIPRO'

select Symbol, Date, Min_Close_Date, DATEDIFF(day,Min_Close_Date,Date) as Recovery_Days_Number from #temptable
--TCS has the minimum number of recovery days. So it recovered from the covid fall the fastest. WIPRO has the max number of recovery days.



------------------------Strength(Nos. of days stock price closed above its previous day's closing price)
drop view if exists A5
create view A5 as(select Symbol, Date, [Close],LAG([Close]) over (order by Date) as Prev_Day_Close from INFOSYS where [Close] is not null
union
select Symbol, Date, [Close],LAG([Close]) over (order by Date) as Prev_Day_Close from [TATA CONSULTANCY SERVICES] where [Close] is not null
union
select Symbol, Date, [Close],LAG([Close]) over (order by Date) as Prev_Day_Close from WIPRO where [Close] is not null)
select * from A5

select Symbol,sum(case when [Close]>Prev_Day_Close then 1 else 0 end) as Strength,RANK() over (order by sum(case when [Close]>Prev_Day_Close then 1 else 0 end) desc) as Ranking 
from A5
group by Symbol --we can also use IIF function instead of case when
--WIPRO has the max strength and TCS has the min strength


------------------------Month with the Highest Volume
select * from
(select top 1 Symbol,YEAR(Date) as Year,MONTH(Date) as Month,MAX(Volume) as Max_Volume
from INFOSYS
group by Symbol,YEAR(Date),MONTH(Date)
order by MAX(Volume) desc
union
select top 1 Symbol,YEAR(Date) as Year,MONTH(Date) as Month,MAX(Volume) as Max_Volume
from [TATA CONSULTANCY SERVICES]
group by Symbol,YEAR(Date),MONTH(Date)
order by MAX(Volume) desc
union
select top 1 Symbol,YEAR(Date) as Year,MONTH(Date) as Month,MAX(Volume) as Max_Volume
from WIPRO
group by Symbol,YEAR(Date),MONTH(Date)
order by MAX(Volume) desc) as p

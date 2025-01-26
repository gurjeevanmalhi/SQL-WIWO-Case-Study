-- exploring database
-- test if database is case sensitive
select CONVERT(varchar(256), SERVERPROPERTY('collation')) as collation; 
-- returns SQL_Latin1_General_CP1_CI_AS -- CI = case insensitive

-- basic customer data questions

-- describe type of customers in customer dimension. Individuals, supermarkets, novelty shops, a mixture?
select distinct category
from dimCustomer;

-- how many rows does customer table have?
select COUNT(*)
from dimCustomer;

-- does customer table include entry for customer unknown?
select customer 
from dimCustomer
where customer = 'unknown';

-- how many known customers do we have?
select count(distinct customer)
from dimCustomer
where customer <> 'unknown';

-- product data questions

-- how many foreign keys does dimstock item table have?
-- 0, used entity relationship diagram (ERD)

-- how many rows does dimstock item table have?
select count(*)
from dimStockItem;

-- how many defined products?
select count(distinct [stock item])
from dimStockItem
where [Stock Item] <> 'unknown';

-- what does 'is chiller stock" column mean? -- items that need refrigeration, from data warehouse documentation file

-- marketing questions

-- marketing team plans to ship a low cost items to reward those who share social media content

-- what is the lowest unit price of the cheapest product we sell? (excluding unknown)
select min([unit price])
from dimStockItem
where [Stock Item Key] != 0;

-- name of cheapest product we sell?
select [stock item], [Unit Price]
from dimStockItem
where [unit price] = 
    (select min([unit price])
    from dimStockItem
    where [Stock Item Key] != 0);

-- exclude all items that contain the word box, bag, or carton in their names. what is the cheapest non packaging related product?
select [stock item], [unit price]
from dimStockItem
where [Stock Item Key] <> 0
    and [Stock Item] not like '%box%'
    and [Stock Item] not like '%bag%'
    and [Stock Item] not like '%carton%'
order by [Unit Price] asc;

-- find a list of products that contain mug or shirt in their name. How many are there?
select count([stock item])
from dimStockItem
where [Stock Item] like '%mug%' or [Stock Item] like '%shirt%';

-- the product should also be black. How many products are there?
select count([stock item])
from dimStockItem
where ([Stock Item] like '%mug%' or [Stock Item] like '%shirt%')
    and color = 'black';

-- What is the WWI Stock Item ID of the cheapest product meeting the above conditions? If multiple products have the same price, choose the one with the lowest WWI Stock Item ID.
select [WWI Stock Item ID], [Unit Price], [Stock Item]
from dimStockItem
where ([Stock Item] like '%mug%' or [Stock Item] like '%shirt%')
    and color = 'black'
order by ([Unit Price]) asc, [WWI Stock Item ID] asc;

-- What is the markup of WWI Stock Item ID 29? 
select [WWI Stock Item ID],
cast(([Recommended Retail Price]-[Unit Price])/[Unit Price] as decimal(8,4)) as pctmarkup
from dimStockItem
where [WWI Stock Item ID] = 29;

-- Instead of making deliveries to individual customer stores, the team wants to group deliveries by postcode and buying group.
-- Buying groups purchase inventory on behalf of the stores within the group.
-- how many customers are in each buying group?

select count(distinct customer) as CustomerNum, [Buying Group]
from dimCustomer
where customer <> 'unknown'
group by [Buying Group];

-- We are trialing a new delivery process with Wingtip Toys. We need to identify clusters of shops from this buying group near each other.
-- Do any postcodes have more than 3 Wingtip Toys shops? If so, which postcode?

select [postal code]
from dimCustomer
where [Buying Group] = 'wingtip toys'
group by [Postal Code]
having count([Customer Key]) > 3;

-- If a postcode has been identified, which of the following stores should be included in the delivery efficiency trial?

select customer, [Postal Code]
from dimCustomer
where [Buying Group] = 'wingtip toys' -- must include filter again, the below sub query only returns a postal code, we need to refilter for wingtip toys
and [postal code] IN
    (select [postal code]
    from dimCustomer
    where [Buying Group] = 'wingtip toys'
    group by [Postal Code]
    having count([Customer Key]) > 3);

-- What proportion of our workforce works in sales?

select cast(cast(count([Is Salesperson]) as decimal (8,4)) /
    (select count([Employee])
    from dimEmployee
    where [Employee] <> 'unknown')
    as decimal (8,4))
    as sales_pct_of_workforce
from dimEmployee
where [Employee] <> 'unknown'
and [Is Salesperson] = 1;

-- Which sales territory has the highest population?

select [sales territory], sum([Latest Recorded Population]) as total_pop
from dimCity
where [City] <> 'unknown'
group by [Sales Territory]
order by total_pop desc;

-- How many cities are in the above territory?
select [sales territory], sum([Latest Recorded Population]) as total_pop, count([WWI City ID]) as total_cities
from dimCity
where [City] <> 'unknown'
group by [Sales Territory]
order by total_pop desc;


--What is the approximate population of the biggest city in that territory?
select [sales territory],
sum([Latest Recorded Population]) as total_pop,
count([WWI City ID]) as total_cities,
max([latest recorded population]) as max_pop_of_city
from dimCity
where [City] <> 'unknown'
group by [Sales Territory]
order by total_pop desc;

-- What is the total population across all sales territories?
select sum([latest recorded population]) as total_pop
from dimCity
where [Sales Territory] <>'unknown'

-- What is the maximum fiscal year in dimDate?
select max([Fiscal Year]) as max_fiscal_year
from dimdate;

-- How many fiscal years do we have sales data for? 

select count(distinct d.[fiscal year]) as num_of_fiscal_year
from factSale as s
inner join dimdate as d
on s.[Invoice Date Key] = d.[Date];

-- Calculate a report of [Sales Excluding Tax], [Profit], [Quantity Sold]. You may need to analyze data by fiscal year or month.
select d.[fiscal year] as fiscal_year,
sum(s.[total excluding tax]) as total_sales_without_tax,
sum(s.[quantity]) as quantity_sold,
sum(s.[profit]) as profit 
from factsale as s 
inner join dimdate as d 
on s.[Invoice Date Key] = d.[Date]
group by d.[Fiscal Year]
order by [fiscal_year] desc;

-- What were the Sales Excluding tax in fiscal year 2015?

select sum(s.[Total Excluding Tax])
from factsale as s 
inner join dimdate as d 
on s.[Invoice Date Key] = d.[Date]
where d.[Fiscal Year] = 2015;
-- query for the calculated report will also answer this question. wrote another query for additional demonstration  

-- Which fiscal year appears to have the highest profit?
select d.[fiscal year], sum(s.[profit]) as profit_per_year
from factsale as s 
inner join dimdate as d
on s.[Invoice Date Key] = d.[Date]
group by d.[Fiscal Year]
order by profit_per_year desc;
-- query for the calculated report will also answer this question. wrote another query for additional demonstration  

-- What explanation can you offer as to why the profit in 2016 is significantly lower than 2015?
-- Find ways to analyze quantity, unit price, total excluding tax, profit, profits per month

select d.[fiscal year],sum(s.[quantity]) as quantity, sum(s.[profit]) as profit, avg([Unit Price]) as avg_unit_price
from factsale as s 
inner join dimdate as d
on s.[Invoice Date Key] = d.[Date]
group by [Fiscal Year]
order by d.[Fiscal Year] desc;
-- returns total quantity, profit, avg unit price per year. this data will exemplify the profit increase from 2016 over prior year mentioned
-- determined avg pricing is consistent across all years, profits & volume were trending higher from 2013-2015
-- requires lower level of detail by month

select d.[fiscal year] as fiscal_year,
d.[Fiscal Month Label] as fiscal_year_month,
d.[fiscal month number] as fiscal_month_number,
sum(s.[quantity]) as quantity,
sum(s.[profit]) as profit,
avg([Unit Price]) as avg_unit_price

from factsale as s 
inner join dimdate as d
on s.[Invoice Date Key] = d.[Date]
where d.[fiscal year] = 2016
or d.[Fiscal Year] = 2015

group by d.[Fiscal Year], d.[Fiscal Month Label], d.[Fiscal Month Number]
order by fiscal_year desc, fiscal_month_number desc;
-- shows same metrics above but further grouped into months
-- determination: only 7 months in 2016 have sales resulting in lower profit vs 2015

-- Top Selling Products

-- What were the total sales excluding tax in fiscal year 2016?
select d.[fiscal year], sum(s.[total excluding tax]) as totalsalesbeforetax
from factsale as s
inner join dimdate as d 
on s.[Invoice Date Key] = d.[Date]
where d.[Fiscal Year] = 2016
group by d.[fiscal year];

-- What was the top selling product in fiscal 2016 so far?

select top 1 p.[stock item] as product, sum(s.[total excluding tax]) as grossrevenue
from factsale as s
inner join dimStockItem as p 
on s.[Stock Item Key] = p.[Stock Item Key]
inner join dimdate as d 
on s.[Invoice Date Key] = d.[Date]
where d.[fiscal year] = 2016
group by p.[Stock Item]
order by grossrevenue desc;
-- returns top product by gross revenue

--What was the top performing product/salesperson combination in fiscal 2016?
select p.[stock item] as product,
sum(s.[total excluding tax]) as grossrevenue,
e.[employee] as salesperson

from factsale as s
inner join dimStockItem as p 
on s.[Stock Item Key] = p.[Stock Item Key]
inner join dimdate as d 
on s.[Invoice Date Key] = d.[Date]
inner join dimEmployee as e
on s.[Salesperson Key] = e.[employee key]

where d.[fiscal year] = 2016
group by p.[Stock Item], e.[Employee]
order by grossrevenue desc;
-- employees amy & anthony are tied

-- What proportion of total fiscal 2016 sales do these top performances represent?
select p.[stock item] as product,
e.[employee] as salesperson,
sum(s.[total excluding tax]) as grossrevenue,
format(cast((sum(s.[total excluding tax]))/(select sum([total excluding tax]) -- subquery returns total sales for latest year
                                            from factsale as s
                                            inner join dimdate as d
                                            on s.[Invoice Date Key] = d.[Date]
                                            where [Fiscal Year] = (select max([fiscal year]) -- subquery is futureproof by always returning latest year
                                                                    from factsale as s 
                                                                    inner join dimdate as d 
                                                                    on s.[invoice date key] = d.[date]))
as decimal (8,6)),'P4') as pctoftotalsales

from factsale as s
inner join dimStockItem as p 
on s.[Stock Item Key] = p.[Stock Item Key]
inner join dimdate as d 
on s.[Invoice Date Key] = d.[Date]
inner join dimEmployee as e
on s.[Salesperson Key] = e.[employee key]

where d.[fiscal year] = (select max([fiscal year])
                         from factsale as s 
                         inner join dimdate as d 
                         on s.[invoice date key] = d.[date])
group by p.[Stock Item], e.[Employee]
order by grossrevenue desc;

--How many chiller products have zero quantity sold to date?
select i.[stock item], sum(s.[quantity]) as quantitysold
from factsale as s 
right join dimStockItem as i 
on s.[Stock Item Key] = i.[Stock Item Key]
where i.[Is Chiller Stock] = 1 
group by i.[Stock Item]
order by quantitysold asc;
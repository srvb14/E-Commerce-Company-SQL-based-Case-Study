-- E-COMMERCE COMPANY CASE STUDY:
-- 1) Describe the Tables:

select * from customers;
select * from order_details;
select * from orders;
select * from products;
------------------------------------------------------------------------------------------------------------
/* 
market segmentation analysis:
2) Identify the top 3 cities with the highest number of customers to determine key
markets for targeted marketing and logistic optimization. 
*/

SELECT 
    location, COUNT(*) AS number_of_customers
FROM
    customers
GROUP BY location
ORDER BY number_of_customers DESC
LIMIT 3;
 -- (As per the query's result Delhi, Chennai,Jaipur must be focused as a part of marketing strategies)
--------------------------------------------------------------------------------------------------------- 
/*
engagement depth analysis:
3)Determine the distribution of customers by the number of orders placed. This insight will help in
segmenting customers into one-time buyers, occasional shoppers, and regular customers for tailored 
marketing strategies
*/
 
with cte as (
    select customer_id, 
    count(order_id) as numberoforders
    from orders
    group by customer_id
)
select numberoforders,
count(customer_id) as customercount
from cte group  by numberoforders 
order by numberoforders;
 -- (as the numver of order increases, customer count decreases & occational shoppers experience the most)
------------------------------------------------------------------------------------
/* 
purchase high value products:
Identify products where the average purchase quantity per order is 2 but with a high total revenue, suggesting
premium product trends.
*/

SELECT 
    product_id,
    AVG(quantity) AS avgquantity,
    SUM(quantity * price_per_unit) AS totalrevenue
FROM
    order_details
GROUP BY product_id
HAVING avgquantity = 2
ORDER BY totalrevenue DESC;
-- product1 exhibit the highest total revenue,
---------------------------------------------------------------------------------------
/*
category wise customer reach 
For each product category, calculate the unique number of customers purchasing from it.
This will help understand which categories have wider appeal across the customer base.
*/

SELECT 
    p.category,
    COUNT(DISTINCT o.customer_id) AS unique_customers
FROM
    products p
        JOIN
    order_details od ON p.product_id = od.product_id
        JOIN
    orders o ON od.order_id = o.order_id
GROUP BY p.category
ORDER BY unique_customers DESC;
-- product category electronics needs more focus as it is in high demand among the customers,
------------------------------------------------------------------------------------------------
/*
sales trend analysis:
Analyze the month-on-month percentage change in total sales to identify growth trends.
*/

with cte as(
    select date_format(order_date,'%Y-%m') as month ,
    total_amount from orders
),
cte2 as (
    select
        month,
        sum(total_amount) as total_sales
    from cte group by month
),
cte3 as(
    select month, total_sales,
    lag(total_sales) over(order by month) as prev_month
    from cte2
)
select month , total_sales, 
round((total_sales-prev_month)/prev_month*100,2) as percent_change
from cte3;
-- As per Sales Trend Analysis Feb 2024 did the sales experience the largest decline.
-- and sales fluctuated with no clear trend .
--------------------------------------------------------------------------------------------------
/* 
Average ordervalue fluctuation:
Examine how the average order value changes month-on-month. Insights can guide pricing and promotional 
strategies to enhance order value.
*/

with cte as(
    select date_format(order_date, '%Y-%m') as month ,
    round(avg(total_amount),2) as avgordervalue
    from orders group by date_format(order_date, '%Y-%m')
),
cte2 as(
    select month ,avgordervalue,
        lag(avgordervalue) over(order by month) as prev_m
    from cte
)
select month , avgordervalue,
round(avgordervalue-prev_m,2) as changeinvalue
from cte2 order by changeinvalue desc;
-- December has the highest change in the average order value
------------------------------------------------------------------------------------------------------
/*
Inventory refresh rate:
Based on sales data, identify products with the fastest turnover rates, suggesting high demand and the
need for frequent restocking.
*/

SELECT 
    product_id, COUNT(order_id) AS salesfrequency
FROM
    orderdetails
GROUP BY product_id
ORDER BY salesfrequency DESC
LIMIT 5;
-- product_id 7 has the highest turnover rates and needs to be restocked frequently
-------------------------------------------------------------------------------------------------------
/* 
Low engagement product
List products purchased by less than 40% of the customer base, indicating potential mismatches between
inventory and customer interest.
*/

with cte as (
	select od.product_id, p.name,
	count(distinct o.customer_id ) as UniqueCustomerCount 
	from products p join orderdetails od 
		on p.product_id = od.product_id
	join orders o 
		on od.order_id= o.order_id
	join customers c
		on o.customer_id= c.customer_id
	group by od.product_id, p.name
    ),

cte2 as(
select count(distinct customer_id) as total_cust 
from customers
)

select cte.product_id,
cte.name,
cte.UniqueCustomerCount
from cte cross join cte2 
	where cte.UniqueCustomerCount<0.4*cte2.total_cust
	order by cte.UniqueCustomerCount;
-- poor visiblity on the platform might be a reason certain products have purchase rates below 40% of the total customer base
-- strategic action:
-- implement targeted marketing campaigns to raise awareness and interest could be a strategic action to
-- improve the sales of these underperforming products. 
-----------------------------------------------------------------------------------------------------------
/* customer acquisition trends:
Evaluate the month-on-month growth rate in the customer base to understand the effectiveness of marketing 
campaigns and market expansion efforts.
*/

with FirstPurchase as (
    select date_format(min(order_date),'%Y-%m') as FirstPurchaseMonth,
    customer_id
    from orders
    group by customer_id
),
CustomerCount as (
    select FirstPurchaseMonth,
    count(customer_id) as total_custm
    from FirstPurchase 
    group by FirstPurchaseMonth
)
select FirstPurchaseMonth, total_custm as TotalNewCustomers 
from CustomerCount order by FirstPurchaseMonth ;
-- it is downward trend that implies that marketing campaigns are not much effective.
----------------------------------------------------------------------------------------------------
/*
Peak sales period identification:
Identify the months with the highest sales volume, aiding in planning for stock levels, marketing efforts,
and staffing in anticipation of peak demand periods.
*/

SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    SUM(total_amount) AS totalsales
FROM
    orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY totalsales DESC
LIMIT 3;
-- september & december months will require major restocking of product and increased staffs.


-- CEATING A DATABASE
create database walmartSales;

-- CREATING THE TABLE
create table sales (
	invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    customer_gender VARCHAR(30) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    tax_pct FLOAT(6,4) NOT NULL,
    total DECIMAL(12, 4) NOT NULL,
    date DATETIME NOT NULL,
    time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_pct FLOAT(11,9),
    gross_income DECIMAL(12, 4),
    rating FLOAT(2, 1)
);


-- --------------------------------------------------------------------------

-- ADDING NEW COLUMNS

-- ADDING COLUMN time_of_day TO DETERMINE WHEN THE SALE WAS MADE (Morning,
--  Afternoon, Evening, Night)
alter table sales
add column time_of_day  varchar(20);

update sales
set time_of_day = (
	CASE
		WHEN TIME(`time`) BETWEEN '00:00:00' AND '11:59:59' THEN 'Morning'
		WHEN TIME(`time`) BETWEEN '12:00:00' AND '16:00:00' THEN 'Afternoon'
		WHEN TIME(`time`) BETWEEN '16:00:01' AND '19:59:59' THEN 'Evening'
		WHEN TIME(`time`) BETWEEN '20:00:00' AND '23:59:59' THEN 'Night'
	END
);

-- ADDING COLUMN day_name TO KNOW ON WHICH DAY OF THE WEEK THE SALE WAS MADE
alter table sales
add column day_name varchar(20);

update sales
set day_name = dayname(date) ;

-- ADDING COLUMN month_name TO KNOW IN WHICH MONTH THE SALE WAS MADE
alter table sales
add column month_name varchar(20);

update sales
set month_name = monthname(date);


-- --------------------------------------------------------------------------
-- QUESTIONS

-- GENERIC
-- 1. How many unique cities does the data have?
select count(distinct city)
from sales;

-- 2. In which city is each branch?
select distinct branch, city
from sales;

-- PRODUCT
-- 1. How many unique product lines does the data have?
select count(distinct product_line)
from sales;

-- 2. What is the most common payment method?
select payment,count(*)
from sales
group by payment
order by count(*) desc
limit 1;

-- 3. What is the most selling product line?
select product_line, sum(quantity)
from sales
group by product_line
order by sum(quantity) desc
limit 1;

-- 4. What is the total revenue by month?
select month_name, sum(total)
from sales
group by month_name;

-- 5. What month had the largest COGS?
select month_name,sum(cogs)
from sales
group by month_name;

-- 6. What product line had the largest revenue?
select product_line, sum(total)
from sales
group by product_line
order by sum(total) desc;

-- 7. What is the city with the largest revenue?
select branch,city, sum(total)
from sales
group by branch,city
order by sum(total) desc;

-- 8. What product line had the largest VAT?
select product_line, avg(tax_pct)
from sales
group by product_line
order by avg(tax_pct) desc;

-- 9. Fetch each product line and add a column 
-- to those product line showing "Good", "Bad". 
-- Good if its greater than average sales
select product_line, avg(total),
	case 
		when avg(total) > (select avg(total) from sales)
			then 'Good'
        else'Bad'
	end as good_bad
from sales
group by product_line;

-- 10. Which branch sold more products than the average ?
select branch, sum(quantity)
from sales
group by branch
having sum(quantity) > (
	select SUM(quantity) / 3
    from sales ) ; 
    
-- 11. What is the most common product line by gender?
select customer_gender, product_line, count(*)
from sales
group by customer_gender, product_line
order by customer_gender, count(*) desc;

-- 12. What is the average rating of each product line?
select product_line, avg(rating)
from sales
group by product_line
order by avg(rating) desc;


-- SALES
-- 1. Number of sales made in each time of the day per weekday
select day_name, time_of_day, count(*)
from sales
group by day_name, time_of_day
order by 
	CASE day_name
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        WHEN 'Sunday' THEN 7
    END,
    CASE time_of_day
        WHEN 'Morining' THEN 1
        WHEN 'Afternoon' THEN 2
        WHEN 'Evening' THEN 3
        WHEN 'Night' THEN 4
    END;
    
-- 2. Which of the customer types brings the most revenue?
select customer_type, sum(total)
from sales
group by customer_type
order by sum(total) desc;

-- 3. Which city has the largest tax percent/ VAT (Value Added Tax)?
select city, avg(tax_pct)
from sales
group by city
order by avg(tax_pct) desc;

-- 4. Which customer type pays the most in VAT?
select customer_type, avg(tax_pct)
from sales
group by customer_type
order by avg(tax_pct) desc;

-- Customer
-- 1. How many unique customer types does the data have?
select count(distinct customer_type)
from sales;

-- 2. How many unique payment methods does the data have?
select count(distinct payment)
from sales;

-- 3. What is the most common customer type?
select customer_type, count(*)
from sales 
group by customer_type
order by count(*) desc;

-- 4. Which customer type buys the most?
select customer_type, sum(quantity) as sales
from sales
group by customer_type
order by sales;

-- 5. What is the gender of most of the customers?
select customer_gender, count(*)
from sales
group by customer_gender
order by count(*) desc;

-- 6. What is the gender distribution per branch?
select branch, customer_gender, count(*)
from sales
group by branch, customer_gender
order by branch, count(*) desc;

-- 7. Which time of the day do customers give most ratings?
select time_of_day, count(rating)
from sales
group by time_of_day
order by count(rating) desc;

-- 8. Which time of the day do customers give most ratings per branch?
select branch, time_of_day, count(rating)
from sales
group by branch, time_of_day
order by branch, count(rating) desc;

-- 9. Which day fo the week has the best avg ratings?
select day_name, avg(rating)
from sales
group by day_name
order by avg(rating) desc;

-- 10. Which day of the week has the best average ratings per branch?
WITH ranked_sales AS ( 
    SELECT 
        branch, 
        day_name,
        AVG(rating) OVER (PARTITION BY branch, day_name) AS avg_rating
    FROM sales
),
ranked_results AS (
    SELECT 
        branch, 
        day_name, 
        avg_rating,
        ROW_NUMBER() OVER (PARTITION BY branch ORDER BY avg_rating DESC) AS avg_rating_rank
    FROM ranked_sales
)
SELECT branch, day_name, avg_rating
FROM ranked_results
WHERE avg_rating_rank = 1;



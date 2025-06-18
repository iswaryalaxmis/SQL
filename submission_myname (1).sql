/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
 CREATE DATABASE vehdb;
 use vehdb;
/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/
     
SELECT state, COUNT(customer_id) AS Customer_count_state
FROM customer_t
GROUP BY state
order by Customer_count_state desc;
-- ---------------------------------------------------------------------------------------------------------------------------------
/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. */

with feedback_score_t as
(select * ,case when customer_feedback = 'Very Bad' THEN 1
         WHEN customer_feedback = 'Bad' THEN 2
         WHEN customer_feedback = 'Okay' THEN 3
         WHEN customer_feedback = 'Good' THEN 4
         WHEN customer_feedback = 'Very Good' THEN 5
		 END AS feedback_score
    from order_t)
    
SELECT
	quarter_number,
    AVG(feedback_score) AS Quarterly_Average_Rating
FROM feedback_score_t
GROUP BY 1
ORDER BY 2 DESC;
-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback.*/
      
with feedback_per as
(select quarter_number,customer_feedback,
count(customer_feedback) as count_customer_feedback,
sum(count(customer_feedback)) over (partition by quarter_number) as Quarterly_customer_feedback
from order_t 
group by quarter_number,customer_feedback 
order by quarter_number desc)
select quarter_number,customer_feedback,count_customer_feedback,Quarterly_customer_feedback,
round(count_customer_feedback * 100 / SUM(count_customer_feedback) OVER (PARTITION BY quarter_number),2) AS Feedback_percentage
from feedback_per
group by quarter_number,customer_feedback
order by quarter_number,customer_feedback;

-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/

select p.vehicle_maker,count(o.customer_id) as count_customers
from product_t as p 
join order_t as o on p.product_id = o.product_id 
group by p.vehicle_maker
order by count_customers desc 
limit 5;
- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/

WITH ranked_data AS (
  SELECT
    c.state,
    p.vehicle_maker,
    COUNT(o.customer_id) AS count_of_customers,
    Rank() OVER (partition by state order by COUNT(o.customer_id)desc ) AS Rank_vehicle_maker
  FROM customer_t c
  INNER JOIN order_t o ON c.customer_id = o.customer_id
  INNER JOIN product_t p ON o.product_id = p.product_id
  GROUP BY c.state, p.vehicle_maker
)
SELECT state, vehicle_maker,count_of_customers,Rank_vehicle_maker
FROM ranked_data
WHERE Rank_vehicle_maker = 1 
ORDER BY state, count_of_customers DESC;
-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/

select 
quarter_number,count(*) as Quarterly_order_quantity
from order_t
group by quarter_number
order by quarter_number;
-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 
 
Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.*/
      
WITH revenue_by_quarter AS (
  SELECT
    quarter_number,
    SUM(quantity * vehicle_price * (1 - discount)) AS Quarterly_Revenue
  FROM order_t
  GROUP BY quarter_number
  ORDER BY quarter_number
)
SELECT
  quarter_number,
  Quarterly_Revenue,
  LAG(Quarterly_Revenue) OVER(ORDER BY quarter_number) AS previous_quarter_revenue,
  round(((Quarterly_Revenue - LAG(Quarterly_Revenue) OVER(ORDER BY quarter_number)) / LAG(Quarterly_Revenue) OVER(ORDER BY quarter_number))*100,2) AS QoQ_Percentage_Change
FROM revenue_by_quarter;
-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/

SELECT
    quarter_number,
    round(SUM(quantity * vehicle_price * (1 - discount)),2) AS Quarterly_Revenue,
    count(*) as Count_orders
  FROM order_t
  GROUP BY quarter_number
  ORDER BY quarter_number;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/

select
c.credit_card_type, avg(o.discount) as Average_Discount
from customer_t as c join order_t as o on
c.customer_id = o.customer_id
group by c.credit_card_type
order by Average_Discount desc;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.*/
    
with time_ship as (
select quarter_number,order_date,ship_date,datediff(ship_date,order_date) as Time_to_ship
from order_t
where ship_date is not null
)
select quarter_number,round(avg(Time_to_ship),0) as Avg_Time_to_ship
from time_ship
group by quarter_number
order by quarter_number;

-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------

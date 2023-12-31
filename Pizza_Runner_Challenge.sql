use dannys_diner;
1.How many pizzas were ordered?;
select count(*) as total_pizza_ordered 
from customer_orders;


2.How many unique customer orders were made?;
select count(distinct(order_id)) as order_made_by_unique_customer
from customer_orders;


3.How many successful orders were delivered by each runner?;
select count(order_id), runner_id 
from runner_orders 
where cancellation = 'delivered' 
group by runner_id; 


4.How many of each type of pizza was delivered?;
WITH cte AS (
  SELECT
    ro.order_id AS runner_order_id,
    co.order_id AS customer_order_id,
    pn.pizza_id AS pizza_name_pizza_id,
    co.pizza_id AS customer_order_pizza_id, pn.pizza_name,
    customer_id, ro.cancellation
  FROM
    runner_orders AS ro
    INNER JOIN customer_orders AS co ON ro.order_id = co.order_id
    INNER JOIN pizza_names AS pn ON co.pizza_id = pn.pizza_id
)
select count(pizza_name) as pizza_ordered, pizza_name 
from cte where cancellation = 'delivered'
group by pizza_name;



5.How many Vegetarian and Meatlovers were ordered by each customer?;
WITH cte AS (
  SELECT
    ro.order_id AS runner_order_id,
    co.order_id AS customer_order_id,
    pn.pizza_id AS pizza_name_pizza_id,
    co.pizza_id AS customer_order_pizza_id, pn.pizza_name,
    customer_id
  FROM
    runner_orders AS ro
    INNER JOIN customer_orders AS co ON ro.order_id = co.order_id
    INNER JOIN pizza_names AS pn ON co.pizza_id = pn.pizza_id
)
select customer_id,count(pizza_name) as pizza_ordered, pizza_name 
from cte 
group by pizza_name,customer_id;



6.What was the maximum number of pizzas delivered in a single order?;
with cte as 
(select co.order_id,count(co.order_id) as total_orders, dense_rank() over(order by count(co.order_id) desc) as count_order_rank from customer_orders as co join runner_orders as ro 
on co.order_id = ro.order_id where ro.cancellation = 'delivered' group by co.order_id
)
select order_id, total_orders  from cte where count_order_rank = 1 ;



7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?;
select customer_id,count(case when exclusions != 0 or extras != 0 then 1 end) as change_pizza_toppings, 
count(case when exclusions = 0 and extras = 0 then 1 end) as unchange_pizza_topings
from customer_orders as co 
join runner_orders as ro on co.order_id = ro.order_id 
where cancellation = 'delivered'
group by customer_id;



8.How many pizzas were delivered that had both exclusions and extras?;
WITH cte AS (
  SELECT
    ro.order_id AS order_id,
    co.customer_id,
    pn.pizza_id AS pizza_name_pizza_id,
	pn.pizza_name,co.exclusions, co.extras,ro.cancellation
  FROM
    runner_orders AS ro
    INNER JOIN customer_orders AS co ON ro.order_id = co.order_id
    INNER JOIN pizza_names AS pn ON co.pizza_id = pn.pizza_id
)
select count(customer_id) as count_pizza 
from cte 
where exclusions != '0' and extras != '0' and cancellation = "delivered";



9.what was the total volume of pizzas ordered for each hour of the day?;
select extract(HOUR from order_time) as order_hour, count(*) as order_coun_in_hour
from customer_orders 
group by extract(HOUR from order_time);



10.What was the volume of orders for each day of the week;
select dayofweek(order_time) as order_days_of_week, count(*) as order_count_in_hour
from customer_orders 
group by  dayofweek(order_time);


 #Second part of the challenge
1.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)?;
select week(registration_date) as week_day_numbers, count(week(registration_date)) as count_day_by_week 
from runners
where registration_date >= '2021-01-01' 
group by week(registration_date);



2.What was the average time in minutes it took 
for each runner to arrive at the Pizza Runner HQ to pickup the order?;
with cte as 
(
select * ,time(order_time)as order_time1 
from customer_orders
),
cte2 as
(
select *, time(pickup_time) as pickup_time1 
from runner_orders
)
select avg(timestampdiff(minute, cte.order_time, pickup_time)) as avg_time 
from cte 
inner join cte2 on cte.order_id=cte2.order_id ;



3.Is there any relationship between the number of pizzas and how long the order takes to prepare?;
with cte as 
(
	select count(order_time) as number_of_pizza_ordered, avg(timestampdiff(minute, co.order_time, ro.pickup_time)) as avg_time
    from customer_orders as co join runner_orders as ro on co.order_id = ro.order_id 
    where pickup_time != 0
    group by order_time
)
select number_of_pizza_ordered, round(avg(avg_time),2) as avg_time_to_prepare_pizza_in_mins 
from cte 
group by number_of_pizza_ordered;



4.What was the average distance travelled for each customer?;
select co.customer_id, round(avg(ro.distance_in_km),2) as avg_distance_travelled
from customer_orders as co join runner_orders as ro on co.order_id = ro.order_id
where ro.distance_in_km != 0 
group by co.customer_id;



5.What was the difference between the longest and shortest delivery times for all orders?
SELECT (MAX(duration_in_mins) - MIN(duration_in_mins)) AS delivery_time_diff 
FROM runner_orders where duration_in_mins != 0;



6.What was the average speed for each runner for each delivery and do you notice any trend for these values?;
select ro.order_id, ro.runner_id,round(avg(ro.distance_in_km * 60 / duration_in_mins),2) as 
avg_speed_of_runner_in_kmh,count(*) as total_order_placed
from customer_orders as co join runner_orders as ro on co.order_id = ro.order_id
where ro.cancellation = 'delivered'
group by order_id, runner_id,distance_in_km,duration_in_mins;

# Here large variance in the runner 2's speed because it's speed is 35.1km/h and 93.6km/h so i think investigate.



7.What was the difference between the longest and shortest delivery times for all orders?;
SELECT MAX(duration_in_mins)  - MIN(duration_in_mins) as duration_time
FROM runner_orders
where duration_in_mins != '0';



8.What is the successful delivery percentage for each runner?;
select runner_id, round(count(case when cancellation = 'delivered' then 1 end)/ count(runner_id) * 100) as delivered_percentage 
from runner_orders group by runner_id;



#3rd part of the challenge 
1.If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes how much money has Pizza Runner made so far if there are no delivery fees?
with cte as 
(
	select co.order_id as customer, ro.order_id as runner,case when pizza_id = 1 then 12	
					when pizza_id = 2 then 10
                    end as price_in_dollar from customer_orders as co join runner_orders as ro on co.order_id = ro.order_id
                    where cancellation = 'delivered'
)
select sum(price_in_dollar) as made_money from cte;
if meatlovers pizza price is $12/pizza and vegitarian pizza price is $10/pizza then Pizza Runner made $138 from all the orders.



2.What if there was an additional $1 charge for any pizza extras? 
--Add cheese is $1 extra
select * , case when  (extras like '4%' or
					  extras like '4%' or 
					  extras like '%4')
					 then 1 else 0
end as price_for_extras 
from customer_orders ;




3.The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner,
--  how would you design an additional table for this new dataset - generate a schema for this new table and insert
--  your own data for ratings for each successful customer order between 1 to 5.

create table rating
( 
	delivery_min_mins varchar(3),
    delivery_max_mins varchar(3),
    rating varchar(5)
);
select* from rating;

Insert into rating values ('1','20', '5'),
						  ('20','30', '4'),
                          ('30','40', '3'),
                          ('40','50', '2'),
                          ('50','60', '1'),
                          ('0', '0', '0');



4.Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas;

-- Time between order and pickup
with cte as 
(
select * ,time(order_time)as order_time1 
from customer_orders
),cte2 as
(
select *, time(pickup_time) as pickup_time1 
from runner_orders
)
select cte.order_id, cte.customer_id,timestampdiff(minute, cte.order_time, pickup_time) as time_between_order_and_pickup 
from cte 
inner join cte2 on cte.order_id=cte2.order_id;

-- Duration time  Formula for the : total duration for the pizza_delivered / total ordered placed both delivered and cancellation 

with cte as 
(
select * ,time(order_time)as order_time1 
from customer_orders
),cte2 as
(
select *, time(pickup_time) as pickup_time1 
from runner_orders
)
select sum(timestampdiff(minute, cte.order_time, pickup_time))/(select count(*) as total_pizza_ordered from customer_orders) as duration_time 
from cte 
inner join cte2 on cte.order_id=cte2.order_id;

-- Average speed of the pizza delivery 
with cte as (
select ro.order_id, ro.runner_id,round(ro.distance_in_km * 60 / duration_in_mins,2) speed_of_runner_in_kmh,count(*) as total_order_placed
from customer_orders as co 
join runner_orders as ro on co.order_id = ro.order_id
where ro.cancellation = 'delivered'
group by order_id, runner_id,distance_in_km,duration_in_mins
)
select round(avg(speed_of_runner_in_kmh),4) as avg_speed_of_runner_in_kmh from cte;


-- Total pizza delivered
select count(order_id)as total_pizza_delivered 
from runner_orders 
where cancellation = 'delivered';



5.If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost 
-- for extras and each runner is paid $0.30 per kilometre traveled - how much money does 
-- Pizza Runner have left over after these deliveries?
with cte as 
(
select  ro.order_id, co.customer_id, co.pizza_id,ro.distance_in_km, 
case when pizza_id = '1' then 12
	else 10 
	end as pizza_price,ro.distance_in_km*0.30 as paid_to_runner_for_delivery 
from runner_orders as ro inner join 
customer_orders as co on ro.order_id = co.order_id
)
select  round(sum(pizza_price - paid_to_runner_for_delivery), 2) as left_money
from cte ;
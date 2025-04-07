-- select * from tbl_yelp_reviews limit 10;
-- select * from tbl_yelp_businesses limit 10;

-- Q.1) Find number of businesses in each categories

with cte as (select business_id, trim(A.value) as category from tbl_yelp_businesses,
LATERAL split_to_table(categories, ',') A)
select category, count(business_id) as number_of_businesses from cte
group by category
order by number_of_businesses DESC;


-- Q.2) Find the top 10 users who have reviewed the most restaurants in the 'restaurant' category

with cte1 as (select business_id, trim(A.value) as category from tbl_yelp_businesses, 
              LATERAL split_to_table(categories, ',') A),
cte2 as (select b.business_id, b.category, r.user_id from tbl_yelp_reviews r join cte1 b on r.business_id = b.business_id)
select user_id, count(distinct business_id) as num_of_businesses_reviewed
from cte2 where category = 'Restaurants'
group by user_id
order by num_of_businesses_reviewed DESC
limit 10;

select r.user_id, count(distinct r.business_id)
from tbl_yelp_reviews r
inner join tbl_yelp_businesses b
on r.business_id = b.business_id
where b.categories ilike '%restaurant%' and r.user_id is not null
group by 1
order by 2 desc limit 10;


-- Q.3) Find the most popular categories of businesses (based on number of reviews):
with cte1 as (select business_id, review_count,trim(A.value) as category from tbl_yelp_businesses,
              LATERAL split_to_table(categories, ',') A)
select category, sum(review_count)  from cte1
group by category
order by 2 DESC;


-- Q.4) Find the top 3 most recent reviews for each business

with cte as (select business_id, review_date, review_text,
ROW_NUMBER() OVER (partition by business_id order by review_date desc) as rnk
from tbl_yelp_reviews where review_date is not null)
select * from cte where rnk <= 3;

-- Q.5) Find the month with highest number of reviews

-- CONCAT(year(review_date), '-', month(review_date))

---with cte as (select TO_CHAR(review_date, '%Y-%m') as mnth from tbl_yelp_reviews)
--select mnth, count(*) as cnt_mnths from cte group by mnth
--order by 2 DESC;

select month(review_date), count(*) from tbl_yelp_reviews
group by month(review_date)
order by 2 desc;

-- Q.6) Find the percentage of 5 star reviews for each business

select b.business_id, b.name, count(*) as total_reviews,
count(case when r.review_stars = 5 then 1 else null end) as stars5_reviews,
stars5_reviews*100/total_reviews as percentage
from tbl_yelp_reviews r join tbl_yelp_businesses b on r.business_id=b.business_id
group by 1,2;


-- Q.7) Find the top 5 most reviewed businesses in each city


--with cte as (select b.city, b.business_id, b.name, count(*) as total_reviews,
--row_number() over (partition by b.city order by total_reviews desc) as rnk
--from tbl_yelp_reviews r join tbl_yelp_businesses b on r.business_id=b.business_id
--group by 1,2,3)
--select * from cte where rnk <= 5 order by city, 5;

with cte as (select b.city, b.business_id, b.name, count(*) as total_reviews
from tbl_yelp_reviews r join tbl_yelp_businesses b on r.business_id=b.business_id
group by 1,2,3)
select * from cte 
qualify row_number() over (partition by city order by total_reviews desc) <= 5
order by city;

-- Q.8) Find the average rating of businesses that have at least 100 reviews

select business_id, avg(review_stars) from tbl_yelp_reviews
group by business_id
having business_id in ( select business_id from tbl_yelp_businesses where review_count >= 100
);

-- Q.9) List the top 10 users who have written the most reviews, alongwith the businesses they reviewed

select r.user_id,b.name, count(*) from tbl_yelp_reviews r join tbl_yelp_businesses b on r.business_id = b.business_id
where r.user_id is not null group by r.user_id, b.name order by 3 DESC limit 10;

-- Q.10) Find top 10 businesses with highest positive sentiment reviews

select r.business_id,b.name, count(r.sentiments) from tbl_yelp_reviews r join tbl_yelp_businesses b on r.business_id = b.business_id
where r.sentiments ilike '%positive%'
group by 1, 2
order by 3 desc
limit 10

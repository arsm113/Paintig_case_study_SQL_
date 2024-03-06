-- 1) Fetch all the paintings which are not displayed on any museums?

select * from work where museum_id is null;

-- 2) Are there museuems without any paintings?

select count(m.name) from museum m left join work w on m.museum_id=w.museum_id where w.name is null;


-- 3) How many paintings have an asking price of more than their regular price? 
select * from product_size where sale_price>regular_price;

-- 4) Identify the paintings whose asking price is less than 50% of its regular price
select * from product_size where sale_price<(0.5*regular_price);


-- 5) Which canva size costs the most?
select p.sale_price, c.label 
from product_size p join canvas_size c
 on p.size_id=c.size_id 
 order by sale_price desc limit 1;


-- 6) Identify the museums with invalid city information in the given dataset

select * from museum where city is null or city='';


-- 7) Fetch the top 10 most famous painting subject

select s.subject, count(s.subject) as sub_count,
rank() over(order by count(s.subject) desc) as rnk 
from work w  join subject s
 on w.work_id=s.work_id
 group by s.subject 
 order by count(s.subject) desc limit 10;


-- 8) Identify the museums which are open on both Sunday and Monday. Display museum name, city.

select m.name,m.city,mh.day 
from museum_hours mh join museum m
 on mh.museum_id=m.museum_id
 where day in ('Sunday', 'Monday');


-- 9) How many museums are open every single day?

select count(museum_id) from
 (select museum_id, count(museum_id) 
 from museum_hours   
 group by museum_id  
 having count(museum_id)=7) x;


-- 10) Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
select m.name,count(w.name),
rank() over(order by count(w.name) desc) as rnk
 from museum m join work w
 on m.museum_id=w.museum_id 
 group by m.name
 order by count(w.name) desc limit 5;


-- 11) Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)

select a.full_name, count(w.name) as no_of_paint
 from artist a join work w on a.artist_id=w.artist_id 
group by a.full_name
 order by count(w.name) desc limit 5;



-- 12) Display the 3 least popular canva sizes

select label,ranking,no_of_paintings
	from (
		select cs.size_id,cs.label,count(1) as no_of_paintings
		, dense_rank() over(order by count(1) ) as ranking
		from work w
		join product_size ps on ps.work_id=w.work_id
		join canvas_size cs on cs.size_id= ps.size_id
		group by cs.size_id,cs.label) x
	where x.ranking<=3;


-- 13) Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?

select museum_id, timediff(
time_format(close,'%h:%i:%s %p'),
time_format(open,'%h:%i:%s %p')
) as duration from museum_hours group by museum_id order by timediff(
time_format(close,'%h:%i:%s %p'),
time_format(open,'%h:%i:%s %p')
) desc;



-- 14) Which museum has the most no of most popular painting style?


	with pop_style as 
			(select style
			,rank() over(order by count(1) desc) as rnk
			from work
			group by style),
		cte as
			(select w.museum_id,m.name as museum_name,ps.style, count(1) as no_of_paintings
			,rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			join pop_style ps on ps.style = w.style
			where w.museum_id is not null
			and ps.rnk=1
			group by w.museum_id, m.name,ps.style)
	select museum_name,style,no_of_paintings
	from cte 
	where rnk=1;



-- 15) Identify the artists whose paintings are displayed in multiple countries

select distinct a.full_name, count(m.country) as country from artist a 
join work w on a.artist_id=w.artist_id 
join museum m on w.museum_id=m.museum_id
group by a.full_name having count(m.country)>1  order by count(m.country)  desc ;



-- 16)Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. 
If there are multiple value, seperate them with comma.

with cte_country as (
select country, count(*),
rank() over(order by count(*) desc) as rnk  from museum group by country),
cte_city as (select city, count(*),
rank() over(order by count(*) desc) as rnk from museum group by city)
select group_concat(distinct cc.country separator ' ,') as country, group_concat(cc2.city separator ' ,') as city from cte_country cc
cross join cte_city cc2
where cc.rnk=1
and cc2.rnk=1;



-- 17) Identify the artist and the museum where the most expensive and least expensive painting is placed. 
--  Display the artist name, sale_price, painting name, museum name, museum city and canvas label


with cte as 
		(select *
		, rank() over(order by sale_price desc) as rnk
		, rank() over(order by sale_price ) as rnk_asc
		from product_size )
	select distinct w.name as painting
	, cte.sale_price
	, a.full_name as artist
	, m.name as museum, m.city
	, cz.label as canvas
	from cte
	join work w on w.work_id=cte.work_id
	join museum m on m.museum_id=w.museum_id
	join artist a on a.artist_id=w.artist_id
	join canvas_size cz on cz.size_id = cte.size_id
	where rnk=1 or rnk_asc=1;


-- 18) Which country has the 5th highest no of paintings?

select m.country,count(w.name) as num_of_paint
 from museum m join work w on m.museum_id=w.museum_id 
 group by m.country
order by count(w.name) desc
 limit 1 offset 4;


-- 19) Which are the 3 most popular and 3 least popular painting styles?

WITH ranked_styles AS (
  SELECT
    style,
    COUNT(style) AS style_count,
    ROW_NUMBER() OVER (ORDER BY COUNT(style) DESC) AS rn_desc,
    
    ROW_NUMBER() OVER (ORDER BY COUNT(style) ASC) AS rn_asc
  FROM
    work
  GROUP BY
    style
)
SELECT style, style_count,
case when ranked_styles.rn_asc<=3 then "Least Popular"
else "Best" end as stat
FROM ranked_styles
WHERE rn_desc <= 3 OR rn_asc <= 3;



-- 20) Which artist has the most no of Portraits paintings outside USA?. 
-- Display artist name, no of paintings and the artist nationality.

select a.full_name, m.country,a.nationality, count(w.name) as num_paint 
from artist a join work w on a.artist_id=w.artist_id
join museum m on w.museum_id=m.museum_id 
join subject s on w.work_id=s.work_id 
where m.country!='USA' and s.subject='Portraits'
 group by a.full_name, m.country,a.nationality 
 order by count(w.name) desc 
 limit 1;

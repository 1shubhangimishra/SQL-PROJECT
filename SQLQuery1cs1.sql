select * from Customer1
select * from prod_cat_info1
select * from Transactions

---------------------------DATA PREPARATION AND UNDERSTANDING----------------------------------
===============================================================================================

--1. What is the total number of rows in each of the 3 table in the database?
SELECT  COUNT(*)AS count_customer from customer1 
SELECT  COUNT(*)AS count_prod from prod_cat_info1 
SELECT  COUNT(*)AS count_tranfrom from transactions 

--2.What is the total number of transaction that have a return?

SELECT  COUNT(*) as Count_return from Transactions
WHERE qty<0

--3.As you would have noticed, the dates provided across the datasets are not in a 
--correct format. As first steps, pls convert the date variables into valid date foemats
--before proceeding ahead.
SELECT CONVERT(date, tran_date, 103) as DATE FROM Transactions

--4.What is the time range of the transaction data avaliable for analysis? Show the output
--in number of days, months and years simultaneously in different columns.
SELECT DATEDIFF(DAY, MIN(CONVERT(DATE, tran_date, 105)) , MAX(CONVERT(DATE, tran_date, 105)))AS DAY_D, 
DATEDIFF(MONTH, MIN(CONVERT(DATE, tran_date, 105)), MAX(CONVERT(DATE, tran_date, 105))) AS MONTH_M ,
DATEDIFF(YEAR, MIN(CONVERT(DATE, tran_date, 105)), MAX(CONVERT(DATE, tran_date, 105))) AS YEAR_Y
FROM Transactions


--5.Which product category does the sub-category "DIY" belong to?
select * from prod_cat_info1
WHERE prod_subcat ='DIY'

---------------------------------------------------------------------------------------------------
------------------------------------------DATA ANALYSIS--------------------------------------------
--1.Which channel is most frequently used for transaction?
SELECT DISTINCT Store_type,
COUNT(store_type) as count_channeltype
From transactions
group by Store_type

--2.What is the count of male and female customers in the database?
SELECT
COUNT(GENDER) AS COUNT_GENDER
FROM Customer1
GROUP BY Gender
HAVING Gender IS NOT NULL


--3. From which city do we have the maximum number of customers and how many?
SELECT city_code, COUNT(*) AS num_customers
FROM Customer1
GROUP BY city_code
ORDER BY num_customers DESC

--4.How many sub-categories are there under the books category?'
SELECT * FROM prod_cat_info1
WHERE prod_cat =  'Books'

--5.What is the maximum quantity of products ever ordered?
SELECT MAX(QTY) AS MAX_QUANTITY
FROM Transactions

--6.What is the net total revenue generated in categories electronics and books?
SELECT DISTINCT prod_cat , SUM(total_amt) AS SUM_OF_AMOUNT FROM prod_cat_info1 AS PC
INNER JOIN Transactions AS T
ON PC.prod_cat_code = T.prod_cat_code AND
PC.prod_sub_cat_code =T.prod_subcat_code
WHERE PC.prod_cat = 'Electronics'OR PC.prod_cat=  'Books'
GROUP BY prod_cat


--7.How many customers have >10 transactions with us, excluding returns?
SELECT cust_id, COUNT(Qty) AS transaction_count
FROM transactions
WHERE Qty>0
GROUP BY cust_id
HAVING COUNT(Qty)>10

--8.What is the combined revenue earned from the "electronics" & "clothing" categories, 
--from "flagship stores"?

SELECT SUM(T.total_amt) AS Combined_revenue FROM
Transactions AS T
WHERE T.store_type = 'Flagship store' AND (T.prod_cat_code =1 OR T.prod_cat_code = 3)
GROUP BY STORE_TYPE


--9.What is the total revenue generated from "male" customers in "electronics" category?
--output should display total revenue by prod sub-cat.
SELECT prod_subcat, SUM(TOTAL_AMT) AS TOT_AMT FROM Customer1 AS A
INNER JOIN Transactions AS B
ON A.customer_Id = B.cust_id
INNER JOIN prod_cat_info1 AS C
ON B.prod_subcat_code=C.prod_sub_cat_code
WHERE prod_cat = 'ELECTRONICS' AND Gender = 'M'
GROUP BY prod_subcat

--10.What is percentage of sales and returns by product sub category
    --display only top 5 sub categories in terms of sales?

select  TOP 5 prod_subcat,
SUM ( CASE WHEN QTY <0 THEN QTY ELSE NULL END) *100/ ( select sum(qty) from transactions where qty<0)  AS  prcnt_returns,
SUM ( CASE WHEN TOTAL_AMT> 0 THEN  total_amt ELSE NULL END)*100 /(select sum(total_amt) from Transactions where qty>0 )    as prcnt_sale
from 
 Transactions as t1
 inner join prod_cat_info1 as t2 on t1.prod_subcat_code= t2.prod_sub_cat_code
 GROUP BY prod_subcat
 order by prcnt_sale desc 

--11.For all customers aged between 25 to 35 years find what is the 
	--net total revenue generated by these consumers in last 30 days of transactions
	--from max transaction date available in the data?

SELECT CUST_ID,SUM(TOTAL_AMT) AS REVENUE FROM Transactions
WHERE CUST_ID IN 
	(SELECT customer_id
	 FROM Customer1
     WHERE DATEDIFF(YEAR,CONVERT(DATE,DOB,103),GETDATE()) BETWEEN 25 AND 35)
     AND CONVERT(DATE,tran_date,103) BETWEEN DATEADD(DAY,-30,(SELECT MAX(CONVERT(DATE,tran_date,103)) FROM Transactions)) 
	 AND (SELECT MAX(CONVERT(DATE,tran_date,103)) FROM Transactions)
GROUP BY CUST_ID

--12. Which product category has seen the max value of returns in the last 3 
	--months of transactions?

SELECT TOP 1 prod_cat, SUM(TOTAL_AMT) FROM Transactions T1
INNER JOIN prod_cat_info1 T2 ON T1.PROD_CAT_CODE = T2.prod_cat_code AND 
T1.PROD_SUBCAT_CODE = T2.prod_sub_cat_code
WHERE TOTAL_AMT < 0 AND 
CONVERT(date, tran_date, 103) BETWEEN DATEADD(MONTH,-3,(SELECT MAX(CONVERT(DATE,tran_date,103)) FROM Transactions)) 
	 AND (SELECT MAX(CONVERT(DATE,tran_date,103)) FROM Transactions)
GROUP BY PROD_CAT
ORDER BY 2 DESC

--13.Which store-type sells the maximum products; by value of sales amount and
	--by quantity sold?

SELECT  STORE_TYPE, SUM(TOTAL_AMT) TOT_SALES, SUM(QTY) TOTAL_QUANTIY
FROM Transactions
GROUP BY STORE_TYPE
HAVING SUM(TOTAL_AMT) >=ALL (SELECT SUM(TOTAL_AMT) FROM Transactions GROUP BY STORE_TYPE)
AND SUM(QTY) >=ALL (SELECT SUM(QTY) FROM Transactions GROUP BY STORE_TYPE)

--14.	What are the categories for which average revenue is above the overall average.

select prod_cat, avg(total_amt)
from Transactions as x
join prod_cat_info1 as y on y.prod_cat_code = x.prod_cat_code
where total_amt >0
group by prod_cat
having avg(total_amt )> (select avg(total_amt) from Transactions where total_amt>0)

select  avg(total_amt)
from Transactions as x
join prod_cat_info1 as y on y.prod_cat_code = x.prod_cat_code
where total_amt >0

--15.Find the average and total revenue by each subcategory for the categories 
	--which are among top 5 categories in terms of quantity sold.


SELECT prod_subcat_code, prod_subcat_code, AVG(TOTAL_AMT) AS AVERAGE_REV, SUM(TOTAL_AMT) AS REVENUE
FROM Transactions
INNER JOIN prod_cat_info1 ON prod_subcat_code=prod_subcat_code AND prod_sub_cat_code=PROD_SUBCAT_CODE
WHERE PROD_CAT IN
(
SELECT TOP 5 
prod_cat
FROM Transactions
INNER JOIN prod_cat_info1 ON prod_subcat_code= prod_subcat_code AND prod_sub_cat_code = PROD_SUBCAT_CODE
GROUP BY PROD_CAT
ORDER BY SUM(QTY) DESC
)
GROUP BY prod_subcat_code, PROD_SUBCAT 
 






 















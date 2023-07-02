    SELECT  * FROM dbo.[credit_card];
--1. Write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends --
    SELECT TOP 5 City, 
	    city_credit_spends,
	    ((city_credit_spends / total_credit_spends) * 100) AS per_credit_spends
    FROM
	    (SELECT City, 
		    SUM(Amount) AS city_credit_spends,
		    SUM(SUM(Amount)) OVER () AS total_credit_spends
	     FROM dbo.credit_card
	     GROUP BY City)  AS table_credit
    ORDER BY city_credit_spends DESC;


2.-- Write a query to print highest spend month and amount spent in that month for each card type
WITH month_year AS (
	SELECT *, 
		MONTH(Date) AS spend_month, 
		YEAR(Date) AS spend_year  
	FROM dbo.credit_card
)
,highest_spend_month AS (
	SELECT TOP 1 
		spend_month, 
		spend_year, 
		SUM(Amount) AS spend 
	FROM month_year GROUP BY  spend_month, spend_year ORDER BY spend DESC 
)
SELECT 
	 my.spend_month, my.spend_year, my.[Card Type], SUM(my.Amount)
FROM  highest_spend_month AS hsm join month_year AS
my ON hsm.spend_month = my.spend_month and 
hsm.spend_year = my.spend_year
GROUP BY  my.[Card Type], my.spend_month, my.spend_year;                  

     

3./* Write a query to print the transaction details(all columns from the table) for each card type when
    it reaches a cumulative of 1000000 total spends */
	
	WITH cte_amount AS
	   (SELECT *,
	       SUM(Amount)Over(PARTITION BY [Card Type] ORDER BY Date) as Commulative
	    FROM dbo.credit_card),
	cte_rank AS
	    (Select *,DENSE_RANK()OVER(PARTITION BY [Card Type] ORDER BY Date ) as rank_predict
	        FROM cte_amount 
			WHERE cte_amount.Commulative>1000000)
	SELECT  [Card Type],
	   Date FROM cte_rank 
	WHERE  rank_predict=1
	GROUP BY [Card Type] , Date




4.--Write a query to find city which had lowest percentage spend for gold card type
    
WITH Total_Spend_Gold As (
   SELECT 
	   City,SUM(Amount) as total_spend_all 
   FROM dbo.credit_card
   GROUP BY City
)
,Lowest_Spend_city_for_gold AS (
SELECT TOP 1
	City, [Card Type], SUM(Amount) AS amount 
	FROM dbo.credit_card WHERE [Card Type] = 'Gold'
	GROUP BY  city,[Card Type]
	ORDER BY  Amount 
)
select x.City, x.[Card Type], 
x.Amount, ROUND(CAST(x.amount AS DECIMAL)/x.total_spend_all * 100,2)  AS pct_contribution
From ( 
	SELECT ls.*, ts.total_spend_all 
	FROM Lowest_Spend_city_for_gold AS ls inner join Total_Spend_Gold AS ts 
	ON ls.City = ts.City
) AS x;

5.--Write a query to print 3 columns: city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
    
WITH expenses AS (
    SELECT City, [Exp Type], SUM(Amount) AS Exp_Amount
    FROM dbo.credit_card
    GROUP BY City, [Exp Type]
),
highest_expenses AS (
    SELECT City, [Exp Type], ROW_NUMBER() OVER (PARTITION BY City ORDER BY Exp_Amount DESC) AS rn_desc
    FROM expenses
),
lowest_expenses AS (
    SELECT City, [Exp Type], ROW_NUMBER() OVER (PARTITION BY City ORDER BY Exp_Amount ASC) AS rn_asc
    FROM expenses
)
SELECT e.City, h.[Exp Type] AS highest_expense_type, l.[Exp Type] AS lowest_expense_type
FROM (
    SELECT DISTINCT City
    FROM expenses
) e
LEFT JOIN highest_expenses h ON e.City = h.City AND h.rn_desc = 1
LEFT JOIN lowest_expenses l ON e.City = l.City AND l.rn_asc = 1;

6.--Write a query to find percentage contribution of spends by females for each expense type

SELECT [Exp Type],
    SUM(CASE WHEN Gender = 'F' THEN Amount ELSE 0 END) AS expense_per_type,
	SUM(Amount) AS total_expense,
    SUM(CASE WHEN Gender = 'F' THEN Amount ELSE 0 END) / SUM(Amount) * 100 AS percentage_contribution_by_female
FROM dbo.credit_card
GROUP BY [Exp Type];

7-- Which card and expense type combination saw highest month over month growth in Jan-2014
WITH month_year_spend AS (
	SELECT 
	   [Card Type], 
	   [Exp Type], 
	   MONTH(Date) AS spend_month, 
	   YEAR(Date) AS spend_year,
	   SUM(Amount) AS spend
	FROM dbo.credit_card
	GROUP BY  [Card Type], [Exp Type], MONTH(Date), YEAR(Date)
)	
,prev_spent AS (
	SELECT 
	*
	,lag(spend,1) OVER(PARTITION BY  [Card Type],[Exp Type] ORDER BY  spend_year, spend_month) AS lag_spend
	FROM month_year_spend
)	
SELECT   TOP 1 *, 
   (spend-lag_spend) AS growth
FROM prev_spent
WHERE  spend_month = 1 and spend_year = 2014 and(spend-lag_spend) > 0 
ORDER BY  (spend-lag_spend) DESC



8--During weekends which city has highest total spend to total no of transcations ratio 
	SELECT TOP 1 
       City,
       SUM(Amount) AS TotalSpend,
       COUNT(*) AS TotalTransactions,
       SUM(Amount) / COUNT(*) AS SpendTransactionRatio
   FROM
      dbo.credit_card
   WHERE
       DATEPART(dw, Date) IN (6, 7)  
   GROUP BY
      City
   ORDER BY
      SpendTransactionRatio DESC


9--Which city took least number of days to reach its 500th transaction after first transaction in that city

WITH  get_first_transaction AS
        (SELECT q1.City, q1.Date FROM 
        (SELECT City, Date, ROW_NUMBER()OVER(PARTITION BY City ORDER BY Date  ASC) AS transaction_rank FROM dbo.credit_card ) AS q1 
         WHERE q1.transaction_rank=1 ),
 get_500th_transaction AS
           (SELECT q2.City, q2.Date FROM 
           (SELECT City, Date, ROW_NUMBER()OVER(PARTITION BY City ORDER BY Date  ASC) AS transaction_rank2 FROM dbo.credit_card ) AS q2 
            WHERE q2.transaction_rank2=500 )
SELECT  TOP 1 f.City,f.Date as First_trans_date,l.Date AS last_trans_date,
    DATEDIFF(DAY, f.Date, l.Date) AS days 
FROM get_first_transaction AS f JOIN get_500th_transaction AS l ON f.City=l.city 
ORDER BY l.Date-f.Date 



	
	 
	 
	 





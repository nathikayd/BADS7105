WITH cust_month as (
    select distinct CUST_CODE, date_trunc(PARSE_DATE('%Y%m%d', CAST(SHOP_DATE AS STRING)) , month) shop_month
    FROM `crm-supermarket.supermarket.supermarket`
    where CUST_CODE is not null 
)
SELECT report_month,
    count(distinct case when status = 'New' THEN CUST_CODE ELSE NULL END) as NewCustomer,
    count(distinct case when status = 'Repeat' THEN CUST_CODE ELSE NULL END) as RepeatCustomer,
    count(distinct case when status = 'Reactivated' THEN CUST_CODE ELSE NULL END) as ReactivatedCustomer,
    count(distinct case when status = 'Churn' THEN CUST_CODE ELSE NULL END) as ChurnCustomer
FROM (
    SELECT CUST_CODE,
    shop_month AS report_month, prev_month,
        CASE
            WHEN DATE_DIFF(shop_month, prev_month, month) IS NULL THEN 'New'
            WHEN DATE_DIFF(shop_month, prev_month, month) =1 THEN 'Repeat'
            WHEN DATE_DIFF(shop_month, prev_month, month) >1 THEN 'Reactivated'
        ELSE NULL END AS status
    FROM (
        SELECT CUST_CODE, shop_month, LAG(shop_month,1) OVER (PARTITION BY cust_code ORDER BY shop_month) AS prev_month
        FROM cust_month
    )
    UNION ALL
    SELECT cust_code, DATE_ADD(shop_month, INTERVAL 1 MONTH) report_month, shop_month as prev_month,
        'Churn' AS status
    FROM (
        SELECT cust_code, shop_month,
            LEAD(shop_month,1) OVER( PARTITION BY cust_code ORDER BY shop_month) AS next_trans_date,
            DATE_DIFF(LEAD(shop_month,1) OVER (PARTITION BY cust_code ORDER BY shop_month), shop_month, MONTH) AS n_months
        FROM cust_month
    ) WHERE
        (n_months > 1 or n_months is null)
        AND shop_month < (SELECT MAX(shop_month) FROM cust_month)   
    ) GROUP BY report_month
    ORDER BY report_month
;
CREATE DATABASE fmcg_analysis;
USE fmcg_analysis;

SELECT * FROM sales_raw;

-- =========================================
-- CZYSZCZENIE I PRZYGOTOWANIE DANYCH
-- =========================================

SELECT
    Order_Date,
    Ship_Date,
    Quantity,

    TRY_CAST(Sales AS DECIMAL(10,2)) AS sales,
    TRY_CAST(Profit AS DECIMAL(10,2)) AS profit,
    TRY_CAST(Discount AS DECIMAL(5,2)) AS discount,

    Region,
    Category,
    Sub_Category,

	    -- flagi b³êdów
    CASE WHEN TRY_CAST(Sales AS DECIMAL(10,2)) IS NULL AND Sales IS NOT NULL THEN 1 ELSE 0 END AS bad_sales,
    CASE WHEN TRY_CAST(Profit AS DECIMAL(10,2)) IS NULL AND Profit IS NOT NULL THEN 1 ELSE 0 END AS bad_profit,
    CASE WHEN TRY_CAST(Discount AS DECIMAL(5,2)) IS NULL AND Discount IS NOT NULL THEN 1 ELSE 0 END AS bad_discount

INTO sales_stg
FROM sales_raw;

SELECT * FROM sales_stg;
SELECT CAST(Order_Date AS DATE) AS order_date, YEAR(Order_Date) AS order_year, MONTH(Order_Date) AS order_month, 
CONVERT(char(7), Order_Date, 126) AS year_month, Region AS region, Category AS category, 
Sub_Category AS sub_category, Sales AS revenue, Quantity AS quantity, Discount AS discount, Profit AS profit, 
Profit * 1.0 / NULLIF(Sales, 0) AS margin, 
CASE WHEN Discount > 0 THEN 1 ELSE 0 END AS is_promo INTO sales_base
FROM sales_stg;
SELECT * FROM sales_base;

--charakter kolumny

SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales_raw';

-- =========================================
-- ANALIZA SPRZEDA¯Y I RENTOWNOŒCI
-- =========================================

--select top 10 * from sales_base;
select year_month, SUM(revenue) AS total_revenue, SUM(profit) AS total_profit, SUM(profit) * 1.0 / NULLIF(SUM(revenue), 0) AS total_margin, 
SUM(quantity)  AS total_quantity, count(*) as number_transactions, AVG(discount) AS avg_discount from sales_base 
group by year_month
order by year_month;

-- WNIOSKI:
-- 1. Wysoka sprzeda¿ nie zawsze przek³ada³a siê na wysoki zysk. 
-- W niektórych miesi¹cach firma generowa³a du¿y obrót przy bardzo niskiej mar¿y.
-- 2. Wy¿sze rabaty mog³y negatywnie wp³ywaæ na rentownoœæ sprzeda¿y. 
-- W miesi¹cach z wysokim poziomem discount pojawia³y siê spadki mar¿y, a nawet ujemny profit.
-- 3. Wzrost liczby sprzedanych produktów nie zawsze poprawia³ rentownoœæ. 
-- Czêœæ wzrostu sprzeda¿y by³a prawdopodobnie napêdzana promocjami i rabatami.
-- 4. Wiêksza liczba transakcji nie zawsze przek³ada³a siê na wy¿szy przychód, 
-- co sugeruje ró¿nice w wartoœci koszyka lub strukturze sprzedawanych produktów.
-- 5. Sprzeda¿ oraz profit charakteryzowa³y siê du¿¹ zmiennoœci¹ w czasie, bez wyraŸnego stabilnego trendu wzrostowego.
-- 6. Wy¿szy poziom rabatów nie przek³ada³ siê na wzrost profit, a w czêœci okresów wi¹za³ siê ze spadkiem mar¿y i rentownoœci sprzeda¿y.

-- =========================================
-- ANALIZA KATEGORII
-- =========================================

SELECT category, SUM(revenue) AS total_revenue, SUM(profit) AS total_profit, SUM(profit) * 1.0 / NULLIF(SUM(revenue), 0) AS total_margin,
SUM(quantity) AS total_quantity, COUNT(*) AS number_transactions, AVG(discount) AS avg_discount from sales_base 
group by category;

-- 1. Kategoria Furniture generowa³a wysoki przychód, jednak charakteryzowa³a siê bardzo nisk¹ rentownoœci¹. 
-- Mo¿e to sugerowaæ nadmierne rabaty, wysokie koszty lub nieefektywn¹ strukturê produktów.
-- 2. Kategoria Technology osi¹ga³a najwy¿sz¹ rentownoœæ przy relatywnie ni¿szym poziomie rabatów.
-- 3. Wy¿sze rabaty w kategorii Furniture mog³y negatywnie wp³ywaæ na mar¿ê oraz koñcowy profit.

-- =========================================
-- ANALIZA SUBCATEGORY
-- =========================================

SELECT sub_category, SUM(revenue) AS total_revenue, SUM(profit) AS total_profit, SUM(profit) * 1.0 / NULLIF(SUM(revenue), 0) AS total_margin,
SUM(quantity) AS total_quantity, COUNT(*) AS number_transactions, AVG(discount) AS avg_discount from sales_base 
group by sub_category
order by total_revenue desc;

-- 1. Subcategory Tables generowa³a wysoki przychód, jednak by³a nierentowna. 
-- Wysoki poziom rabatów móg³ negatywnie wp³ywaæ na koñcowy profit oraz mar¿ê sprzeda¿y.
-- 2. Czêœæ subcategories w kategorii Furniture charakteryzowa³a siê ujemn¹ rentownoœci¹,
-- co sugeruje problem z polityk¹ rabatow¹ lub kosztami sprzeda¿y.
-- 3. Wp³yw rabatów na profit ró¿ni³ siê pomiêdzy subcategories. 
-- Niektóre produkty utrzymywa³y wysok¹ rentownoœæ mimo du¿ych discountów.
-- 4. Subcategory Copiers osi¹ga³a najwy¿sz¹ rentownoœæ, 
-- generuj¹c wysoki profit przy relatywnie umiarkowanym poziomie rabatów.

-- =========================================
-- ANALIZA REGIONÓW
-- =========================================

SELECT region, SUM(revenue) AS total_revenue, SUM(profit) AS total_profit, SUM(profit) * 1.0 / NULLIF(SUM(revenue), 0) AS total_margin,
SUM(quantity) AS total_quantity, COUNT(*) AS number_transactions, AVG(discount) AS avg_discount from sales_base 
group by region
order by total_revenue desc;

-- 1. Region Central osi¹ga³ najni¿sz¹ rentownoœæ przy jednoczeœnie najwy¿szym poziomie rabatów. 
-- Mo¿e to sugerowaæ, ¿e agresywna polityka discountów negatywnie wp³ywa³a na profit.
-- 2. Region West generowa³ najwy¿szy profit oraz najwy¿sz¹ mar¿ê przy relatywnie niskim poziomie rabatów.
-- 3. Regiony ró¿ni³y siê nie tylko poziomem sprzeda¿y, ale równie¿ efektywnoœci¹ generowania zysku.

-- =========================================
-- FINALNY WIDOK POD POWER BI
-- =========================================

CREATE VIEW vw_fmcg_sales_dashboard AS 

SELECT 
	order_date,
	order_year,
	order_month,
	year_month, 
	region,
	category,
	sub_category,
	revenue, 
	quantity, 
	discount, 
	profit,
	margin,
	is_promo
FROM sales_base;
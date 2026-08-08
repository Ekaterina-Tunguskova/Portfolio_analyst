/* Проект первого модуля: анализ данных для агентства недвижимости
 * Часть 2. Решаем ad hoc задачи
 *
 * Автор: Тунгускова Екатерина
 * Дата: 11.03.2026
*/



-- Задача 1: Время активности объявлений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы, также оставим пропущенные данные:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ),
-- Определяем категории объявлений по дням активности и по территории, считаем стоимость квадратного метра, фильтруем только города:
info_category_and_price_metr AS (
SELECT *,
	CASE
		WHEN a.days_exposition >=1 AND a.days_exposition <= 30 THEN 'около одного месяца'
		WHEN a.days_exposition > 30 AND a.days_exposition <= 90 THEN 'от одного до трёх месяцев'
		WHEN a.days_exposition > 90 AND a.days_exposition <= 180 THEN 'от трёх месяцев до полугода'
		WHEN a.days_exposition > 180 THEN 'более полугода'
		ELSE 'non category'
	END AS days_category,
	CASE 
		WHEN f.city_id = '6X8I' THEN 'Санкт-Петербург'
		ELSE 'ЛенОбл'
	END AS regoin,
	a.last_price/f.total_area AS price_metr
FROM real_estate.advertisement AS a
LEFT JOIN real_estate.flats AS f ON a.id = f.id
LEFT JOIN real_estate.city AS c ON f.city_id = c.city_id
LEFT JOIN real_estate.type AS t ON f.type_id = t.type_id
WHERE a.id IN (SELECT * FROM filtered_id) AND type = 'город' AND first_day_exposition >= '2015-01-01' AND first_day_exposition <= '2018-12-31'
-- Выводим основной запрос, считая характеристики для каждой категории
)
SELECT regoin AS "регион",
	   days_category AS "категория активности",
	   COUNT (*) AS "кол во объявлений",
	   ROUND (((COUNT(*)::numeric / (SUM(COUNT(*)) OVER (PARTITION BY regoin))) * 100),2) AS "доля объявлений",
	   ROUND ((AVG (price_metr)::numeric),2) AS "ср стоимость кв метра",
	   ROUND ((AVG (total_area)::numeric),2) AS "ср площадь",
	   PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY rooms) AS "ср кол во комнат",
	   PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY balcony) AS "ср кол во балконов",
	   ROUND ((AVG (ceiling_height)::numeric),2) AS "ср высота потолков",
	   ROUND (((SUM (is_apartment)::numeric/(SELECT COUNT (*) FROM real_estate.advertisement))*100),2) AS "доля апарт от всех объявл"
FROM info_category_and_price_metr
WHERE days_category <> 'non category'
GROUP BY regoin, days_category
	
-- Задача 2: Сезонность объявлений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы, также оставим пропущенные данные:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ),
-- Найдём месяц выставления объявления на продажу и снятия, а стоимость кв метра:
info_per_month AS (
SELECT *,
	   EXTRACT (MONTH FROM a.first_day_exposition) AS period_start,
	   EXTRACT (MONTH FROM a.first_day_exposition + days_exposition * INTERVAL '1 day') AS period_and,
	   a.last_price/f.total_area AS price_metr
FROM real_estate.advertisement AS a
LEFT JOIN real_estate.flats AS f ON a.id = f.id
LEFT JOIN real_estate.city AS c ON f.city_id = c.city_id
LEFT JOIN real_estate.type AS t ON f.type_id = t.type_id
WHERE a.id IN (SELECT * FROM filtered_id) AND type = 'город' AND first_day_exposition >= '2015-01-01' AND first_day_exposition <= '2018-12-31'
),
-- Считаем статистику по месяцу публикации объявлений:
stat_per_start AS (
SELECT period_start,
	   COUNT (*) AS count_flats,
	   ROUND (AVG (price_metr)::numeric,2) AS avg_price_metr,
	   ROUND (AVG (total_area)::numeric,2) AS avg_area
FROM info_per_month
GROUP BY period_start
),
-- Считаем статистику по месяцу снятия объявлений:
stat_per_and AS (
SELECT period_and,
	   COUNT (*) AS count_flats,
	   ROUND (AVG (price_metr)::numeric,2) AS avg_price_metr,
	   ROUND (AVG (total_area)::numeric,2) AS avg_area
FROM info_per_month
GROUP BY period_and
) 
-- Выводим итоговый запрос, объеденяя данные по периодам для публикации и снятия объявлений:
SELECT s.period_start AS "период",
	   s.count_flats AS "кол во объявлений (публикация)",
	   s.avg_price_metr AS "ср стоимость метра (публикация)",
	   s.avg_area AS "ср площадь (публикация)",
	   a.count_flats AS "кол во объявлений (снятие)",
	   a.avg_price_metr AS "ср стоимость метра (снятие)",
	   a.avg_area AS "ср площадь (снятие)"
FROM stat_per_start AS s
FULL JOIN stat_per_and AS a ON s.period_start = a.period_and
ORDER BY s.period_start



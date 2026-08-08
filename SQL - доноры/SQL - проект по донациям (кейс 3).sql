-- ЗАДАНИЕ 1. Определить регионы с наибольшим количеством зарегистрированных доноров.
SELECT region,
	   COUNT (id)
FROM donorsearch.user_anon_data
GROUP BY region
ORDER BY COUNT (id) DESC;

-- На первом месте крупные города, однако также много донаций без места и это стоит исправить

-- ЗАДАНИЕ 2. Изучить динамику общего количества донаций в месяц за 2022 и 2023 годы.
SELECT DATE_TRUNC ('month', donation_date)::date,
	   COUNT (id)
FROM donorsearch.donation_anon
WHERE donation_date BETWEEN '2022-01-01' AND '2023-12-31'
GROUP BY DATE_TRUNC ('month', donation_date)
ORDER BY DATE_TRUNC ('month', donation_date);

-- В 2022 году наблюдается устойчивый рост активности доноров в течение года за исключением небольших спадов в мае и июне.
-- В 2023 году наблюдается спад активности доноров в середине и конце года по сравнению с началом года.
-- В оба года наблюдаются пики активности в весенние месяцы март и апрель.

-- Рекомендации:
-- Увеличить маркетинговые и рекламные кампании в летние месяцы, чтобы компенсировать снижение активности доноров.
-- Провести дополнительные акции и мероприятия в конце года (октябрь-ноябрь), чтобы увеличить количество донаций.

-- ЗАДАНИЕ 3. Определить наиболее активных доноров в системе, учитывая только данные о зарегистрированных и подтвержденных донациях.
SELECT id,
       confirmed_donations
FROM donorsearch.user_anon_data
ORDER BY confirmed_donations DESC
LIMIT 10;

-- Доноры с наибольшим количеством донаций показывают высокую степень вовлечённости и лояльности.
-- У донора с ID 235391 большое количество донаций (361), что указывает на его исключительную активность.
-- Эти доноры могут быть основой для создания программ лояльности и награждения, чтобы поддерживать их активность

-- ЗАДАНИЕ 4. Оценить, как система бонусов влияет на зарегистрированные в системе донации.
WITH donor_activity AS
  (SELECT u.id,
          u.confirmed_donations,
          COALESCE(b.user_bonus_count, 0) AS user_bonus_count
   FROM donorsearch.user_anon_data u
   LEFT JOIN donorsearch.user_anon_bonus b ON u.id = b.user_id)
SELECT CASE
           WHEN user_bonus_count > 0 THEN 'Получили бонусы'
           ELSE 'Не получали бонусы'
       END AS статус_бонусов,
       COUNT(id) AS количество_доноров,
       AVG(confirmed_donations) AS среднее_количество_донаций
FROM donor_activity
GROUP BY статус_бонусов;

-- Доноры, которые получили бонусы, в среднем делают значительно больше донаций (~13.90), чем те, кто не получил бонусы (~0.53).
-- Это свидетельствует о сильном положительном влиянии программ лояльности на активность доноров.

-- ЗАДАНИЕ 5. Исследовать вовлечение новых доноров через социальные сети. 
-- Узнать, сколько по каким каналам пришло доноров, и среднее количество донаций по каждому каналу.
SELECT CASE
           WHEN autho_vk THEN 'ВКонтакте'
           WHEN autho_ok THEN 'Одноклассники'
           WHEN autho_tg THEN 'Telegram'
           WHEN autho_yandex THEN 'Яндекс'
           WHEN autho_google THEN 'Google'
           ELSE 'Без авторизации через соцсети'
       END AS социальная_сеть,
       COUNT(id) AS количество_доноров,
       AVG(confirmed_donations) AS среднее_количество_донаций
FROM donorsearch.user_anon_data
GROUP BY социальная_сеть;

-- Доноры, авторизованные через Яндекс, показывают наибольшее среднее количество подтверждённых донаций

-- Рекомендации:
-- Увеличить маркетинговые усилия на платформах Яндекс и Telegram, так как они показывают наибольшую активность доноров.
-- Стимулировать доноров, не использующих социальные сети, специальными кампаниями и предложениями.

-- ЗАДАНИЕ 6. Сравнить активность однократных доноров со средней активностью повторных доноров.
WITH donor_groups AS (
    SELECT 
        id AS user_id,
        confirmed_donations,
        count_bonuses_taken,
        EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM birth_date) AS age,
        CASE 
            WHEN confirmed_donations = 1 THEN 'Однократные'
            WHEN confirmed_donations >= 2 THEN 'Повторные'
            ELSE 'Неопределено'
        END AS donor_type
    FROM donorsearch.user_anon_data
    WHERE confirmed_donations >= 1
        AND confirmed_donations IS NOT NULL)
SELECT 
    donor_type AS "Тип донора",
    COUNT(*) AS "Количество доноров",
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS "Доля от всех доноров, %",
    ROUND(AVG(confirmed_donations), 2) AS "Среднее кол-во донаций",
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY confirmed_donations) AS "Медианное кол-во донаций",
    MIN(confirmed_donations) AS "Минимум донаций",
    MAX(confirmed_donations) AS "Максимум донаций",
    ROUND(AVG(count_bonuses_taken), 2) AS "Среднее кол-во использованных бонусов",
    ROUND(100.0 * COUNT(CASE WHEN count_bonuses_taken > 0 THEN 1 END) / COUNT(*), 2) AS "Доля использовавших бонусы, %",
    ROUND(AVG(age), 1) AS "Средний возраст"
FROM donor_groups
WHERE donor_type != 'Неопределено'
GROUP BY donor_type
ORDER BY donor_type

-- Доноры между однократными и повторыми распределены примерно одинаково, то есть каждый второй пока не стал повторным
-- Рекомендуется оздание специальных программ, направленных на поддержку и увеличение активности повторных доноров

-- ЗАДАНИЕ 7. Сравнить данные о планируемых донациях с фактическими данными, чтобы оценить эффективность планирования.
WITH planned_donations AS (
  SELECT DISTINCT user_id, donation_date, donation_type
  FROM donorsearch.donation_plan
),
actual_donations AS (
  SELECT DISTINCT user_id, donation_date
  FROM donorsearch.donation_anon
),
planned_vs_actual AS (
  SELECT
    pd.user_id,
    pd.donation_date AS planned_date,
    pd.donation_type,
    CASE WHEN ad.user_id IS NOT NULL THEN 1 ELSE 0 END AS completed
  FROM planned_donations pd
  LEFT JOIN actual_donations ad ON pd.user_id = ad.user_id AND pd.donation_date = ad.donation_date
)
SELECT
  donation_type,
  COUNT(*) AS total_planned_donations,
  SUM(completed) AS completed_donations,
  ROUND(SUM(completed) * 100.0 / COUNT(*), 2) AS completion_rate
FROM planned_vs_actual
GROUP BY donation_type;

-- Необходимость повышения вовлечённости доноров, тк реалиализуется меньше половины запланированных донаций 
-- Рекомендуется провести мероприятия по мотивации доноров, такие как программы поощрения
-- scd2_test.sql
-- Odev 3.4: (a) yukleyicinin idempotent oldugunu, (b) SCD2 mantiginin dogru
-- calistigini kanitlar. Repo kokunden calistirilmali.

\echo '########## 1) IDEMPOTENCY: yukleyiciyi tekrar calistir ##########'
\echo '--- once:'
SELECT 'dim_customer' AS tablo, count(*) FROM star.dim_customer
UNION ALL SELECT 'fct_orders', count(*) FROM star.fct_orders
UNION ALL SELECT 'fct_order_items', count(*) FROM star.fct_order_items;

\i star/load_star.sql

\echo '--- sonra (ayni olmali):'
SELECT 'dim_customer' AS tablo, count(*) FROM star.dim_customer
UNION ALL SELECT 'fct_orders', count(*) FROM star.fct_orders
UNION ALL SELECT 'fct_order_items', count(*) FROM star.fct_order_items;

\echo ''
\echo '########## 2) SCD2: bir musterinin ulkesi degisiyor ##########'

CREATE TEMP TABLE _tu AS
SELECT user_id FROM orders
GROUP BY user_id HAVING count(*) BETWEEN 3 AND 6
ORDER BY user_id LIMIT 1;

\echo '--- test kullanicisi:'
SELECT u.id, u.email, u.country FROM users u JOIN _tu t ON t.user_id = u.id;

\echo '--- dim_customer daki mevcut surum:'
SELECT customer_sk, user_id, country, valid_from, valid_to, is_current
FROM star.dim_customer WHERE user_id = (SELECT user_id FROM _tu) ORDER BY valid_from;

\echo '--- OLTP de ulkeyi degistiriyoruz:'
UPDATE users
SET country = CASE WHEN country = 'TR' THEN 'DE' ELSE 'TR' END
WHERE id = (SELECT user_id FROM _tu);

\i star/load_star.sql

\echo ''
\echo '--- dim_customer: artik IKI surum olmali, biri kapali biri guncel:'
SELECT customer_sk, user_id, country, valid_from, valid_to, is_current
FROM star.dim_customer WHERE user_id = (SELECT user_id FROM _tu) ORDER BY valid_from;

\echo ''
\echo '########## 3) TARIHSEL DOGRULUK: eski siparisler hangi surume bagli? ##########'
SELECT f.order_id, f.ordered_at::date AS siparis_tarihi, f.customer_sk,
       d.country AS siparis_anindaki_ulke, d.is_current AS surum_guncel_mi
FROM star.fct_orders f
JOIN star.dim_customer d ON d.customer_sk = f.customer_sk
WHERE d.user_id = (SELECT user_id FROM _tu)
ORDER BY f.ordered_at;

\echo ''
\echo '--- Karsilastirma: OLTP den bakinca ulke NE GORUNUYOR (leakage)?'
SELECT o.id AS order_id, o.ordered_at::date AS siparis_tarihi,
       u.country AS oltp_bugunku_ulke
FROM orders o JOIN users u ON u.id = o.user_id
WHERE u.id = (SELECT user_id FROM _tu)
ORDER BY o.ordered_at;

\echo ''
\echo '########## 4) SCD2 TUTARLILIK KONTROLLERI ##########'
\echo '--- Her kullanicinin tam olarak bir guncel surumu var mi? (beklenen: 0 satir)'
SELECT user_id, count(*) AS guncel_surum
FROM star.dim_customer WHERE is_current
GROUP BY user_id HAVING count(*) <> 1;

\echo '--- Kapali surumlerin valid_to su dolu mu? (beklenen: 0)'
SELECT count(*) AS hatali FROM star.dim_customer WHERE NOT is_current AND valid_to IS NULL;

\echo '--- Surumler ust uste biniyor mu? (beklenen: 0)'
SELECT count(*) AS cakisan
FROM star.dim_customer a
JOIN star.dim_customer b
  ON a.user_id = b.user_id AND a.customer_sk < b.customer_sk
 AND a.valid_from < COALESCE(b.valid_to, 'infinity'::timestamptz)
 AND b.valid_from < COALESCE(a.valid_to, 'infinity'::timestamptz);

\echo '--- Hicbir siparis surum bulamamis mi? (beklenen: 0)'
SELECT (SELECT count(*) FROM orders) - (SELECT count(*) FROM star.fct_orders) AS kayip_siparis;

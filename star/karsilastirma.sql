-- karsilastirma.sql
-- Odev 3.4: ayni 10 is sorusu, once OLTP'de sonra star schema'da.
-- Her sorgu count(*) ile sarmalandi: tam calisir, tek satir doner, sure temiz olculur.
-- Kapsam: paid + shipped + delivered.

\echo '### 1) Aylik ciro --- OLTP'
SELECT count(*) FROM (
  SELECT date_trunc('month', o.ordered_at)::date AS ay, sum(oi.quantity*oi.unit_price) AS ciro
  FROM orders o JOIN order_items oi ON oi.order_id = o.id
  WHERE o.status IN ('paid','shipped','delivered') GROUP BY ay) t;
\echo '### 1) Aylik ciro --- STAR'
SELECT count(*) FROM (
  SELECT d.ay_basi, sum(f.brut_tutar) AS ciro
  FROM star.fct_orders f JOIN star.dim_date d ON d.date_key = f.date_key
  WHERE f.status IN ('paid','shipped','delivered') GROUP BY d.ay_basi) t;

\echo '### 2) Kategori bazinda ciro --- OLTP'
SELECT count(*) FROM (
  SELECT c.name, sum(oi.quantity*oi.unit_price) AS ciro
  FROM order_items oi
  JOIN orders o     ON o.id = oi.order_id
  JOIN products p   ON p.id = oi.product_id
  JOIN categories c ON c.id = p.category_id
  WHERE o.status IN ('paid','shipped','delivered') GROUP BY c.name) t;
\echo '### 2) Kategori bazinda ciro --- STAR'
SELECT count(*) FROM (
  SELECT dp.kategori_adi, sum(fi.brut_tutar) AS ciro
  FROM star.fct_order_items fi JOIN star.dim_product dp ON dp.product_sk = fi.product_sk
  WHERE fi.status IN ('paid','shipped','delivered') GROUP BY dp.kategori_adi) t;

\echo '### 3) Ciro bazinda ilk 10 urun --- OLTP'
SELECT count(*) FROM (
  SELECT p.sku, sum(oi.quantity*oi.unit_price) AS ciro
  FROM order_items oi JOIN orders o ON o.id = oi.order_id JOIN products p ON p.id = oi.product_id
  WHERE o.status IN ('paid','shipped','delivered')
  GROUP BY p.sku ORDER BY ciro DESC LIMIT 10) t;
\echo '### 3) Ciro bazinda ilk 10 urun --- STAR'
SELECT count(*) FROM (
  SELECT dp.sku, sum(fi.brut_tutar) AS ciro
  FROM star.fct_order_items fi JOIN star.dim_product dp ON dp.product_sk = fi.product_sk
  WHERE fi.status IN ('paid','shipped','delivered')
  GROUP BY dp.sku ORDER BY ciro DESC LIMIT 10) t;

\echo '### 4) Musteri basina harcama, ilk 10 --- OLTP'
SELECT count(*) FROM (
  SELECT o.user_id, sum(oi.quantity*oi.unit_price) AS harcama
  FROM orders o JOIN order_items oi ON oi.order_id = o.id
  WHERE o.status IN ('paid','shipped','delivered')
  GROUP BY o.user_id ORDER BY harcama DESC LIMIT 10) t;
\echo '### 4) Musteri basina harcama, ilk 10 --- STAR'
SELECT count(*) FROM (
  SELECT f.customer_sk, sum(f.brut_tutar) AS harcama
  FROM star.fct_orders f
  WHERE f.status IN ('paid','shipped','delivered')
  GROUP BY f.customer_sk ORDER BY harcama DESC LIMIT 10) t;

\echo '### 5) Siparis durumu dagilimi --- OLTP'
SELECT count(*) FROM (SELECT status, count(*) FROM orders GROUP BY status) t;
\echo '### 5) Siparis durumu dagilimi --- STAR'
SELECT count(*) FROM (SELECT status, count(*) FROM star.fct_orders GROUP BY status) t;

\echo '### 6) Hafta gunu bazinda siparis --- OLTP'
SELECT count(*) FROM (
  SELECT EXTRACT(DOW FROM ordered_at) AS g, count(*) FROM orders GROUP BY g) t;
\echo '### 6) Hafta gunu bazinda siparis --- STAR'
SELECT count(*) FROM (
  SELECT d.hafta_gunu, count(*) FROM star.fct_orders f
  JOIN star.dim_date d ON d.date_key = f.date_key GROUP BY d.hafta_gunu) t;

\echo '### 7) Ortalama sepet tutari --- OLTP'
SELECT count(*) FROM (
  SELECT avg(sepet) FROM (
    SELECT oi.order_id, sum(oi.quantity*oi.unit_price) AS sepet
    FROM order_items oi JOIN orders o ON o.id = oi.order_id
    WHERE o.status IN ('paid','shipped','delivered') GROUP BY oi.order_id) x) t;
\echo '### 7) Ortalama sepet tutari --- STAR'
SELECT count(*) FROM (
  SELECT avg(brut_tutar) FROM star.fct_orders
  WHERE status IN ('paid','shipped','delivered')) t;

\echo '### 8) Kupon indiriminin toplam etkisi --- OLTP'
SELECT count(*) FROM (
  WITH sepet AS (
    SELECT o.id, sum(oi.quantity*oi.unit_price) AS brut, sum(oi.quantity*oi.unit_cost) AS maliyet
    FROM orders o JOIN order_items oi ON oi.order_id = o.id
    WHERE o.status IN ('paid','shipped','delivered') GROUP BY o.id),
  ind AS (SELECT order_id, sum(discount_applied) AS indirim FROM order_coupons GROUP BY order_id)
  SELECT sum(s.brut - s.maliyet) AS brut_marj, sum(COALESCE(i.indirim,0)) AS indirim
  FROM sepet s LEFT JOIN ind i ON i.order_id = s.id) t;
\echo '### 8) Kupon indiriminin toplam etkisi --- STAR'
SELECT count(*) FROM (
  SELECT sum(brut_marj) AS brut_marj, sum(indirim_tutar) AS indirim
  FROM star.fct_orders WHERE status IN ('paid','shipped','delivered')) t;

\echo '### 9) Ulke bazinda ciro --- OLTP'
SELECT count(*) FROM (
  SELECT COALESCE(o.shipping_country,'bilinmiyor') AS ulke, sum(oi.quantity*oi.unit_price) AS ciro
  FROM orders o JOIN order_items oi ON oi.order_id = o.id
  WHERE o.status IN ('paid','shipped','delivered') GROUP BY ulke) t;
\echo '### 9) Ulke bazinda ciro --- STAR'
SELECT count(*) FROM (
  SELECT COALESCE(shipping_country,'bilinmiyor') AS ulke, sum(brut_tutar) AS ciro
  FROM star.fct_orders WHERE status IN ('paid','shipped','delivered') GROUP BY ulke) t;

\echo '### 10) Kok kategori bazinda ciro --- OLTP (recursive CTE gerekiyor)'
SELECT count(*) FROM (
  WITH RECURSIVE agac AS (
    SELECT id AS kok_id, name AS kok_ad, id AS alt_id FROM categories WHERE parent_id IS NULL
    UNION ALL
    SELECT a.kok_id, a.kok_ad, c.id FROM categories c JOIN agac a ON c.parent_id = a.alt_id)
  SELECT a.kok_ad, sum(oi.quantity*oi.unit_price) AS ciro
  FROM agac a
  JOIN products p    ON p.category_id = a.alt_id
  JOIN order_items oi ON oi.product_id = p.id
  JOIN orders o      ON o.id = oi.order_id
  WHERE o.status IN ('paid','shipped','delivered') GROUP BY a.kok_ad) t;
\echo '### 10) Kok kategori bazinda ciro --- STAR'
SELECT count(*) FROM (
  SELECT dp.kok_kategori, sum(fi.brut_tutar) AS ciro
  FROM star.fct_order_items fi JOIN star.dim_product dp ON dp.product_sk = fi.product_sk
  WHERE fi.status IN ('paid','shipped','delivered') GROUP BY dp.kok_kategori) t;

-- q11_kullanici_siparis_harcama.sql
-- Soru: Her kullanicinin siparis sayisi ve toplam harcamasi nedir?
-- Konu: INNER JOIN, tablo takma adi, fan-out, count(DISTINCT)

-- a) Fan-out'un ciplak kaniti
SELECT (SELECT count(*) FROM orders)       AS orders_satir,
       (SELECT count(*) FROM order_items)  AS order_items_satir;

SELECT count(*)             AS join_sonucu_satir,
       count(DISTINCT o.id) AS gercek_siparis_sayisi
FROM orders o
JOIN order_items oi ON oi.order_id = o.id;

-- b) Kullanici bazinda: YANLIS ve DOGRU sayim yan yana
SELECT u.id,
       u.email,
       count(o.id)                                AS yanlis_siparis_sayisi,
       count(DISTINCT o.id)                       AS dogru_siparis_sayisi,
       round(sum(oi.quantity * oi.unit_price), 2) AS toplam_harcama
FROM users u
JOIN orders o       ON o.user_id  = u.id
JOIN order_items oi ON oi.order_id = o.id
GROUP BY u.id, u.email
ORDER BY toplam_harcama DESC
LIMIT 15;

-- c) Ortalama sepet tutari
SELECT u.id,
       u.email,
       count(DISTINCT o.id)                       AS siparis,
       round(sum(oi.quantity * oi.unit_price), 2) AS toplam_harcama,
       round(sum(oi.quantity * oi.unit_price) / count(DISTINCT o.id), 2) AS ortalama_sepet
FROM users u
JOIN orders o       ON o.user_id  = u.id
JOIN order_items oi ON oi.order_id = o.id
GROUP BY u.id, u.email
ORDER BY toplam_harcama DESC
LIMIT 15;

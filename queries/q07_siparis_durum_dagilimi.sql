-- q07_siparis_durum_dagilimi.sql
-- Soru: Siparisler durumlarina gore nasil dagiliyor?
-- Konu: GROUP BY, toplama fonksiyonlari, HAVING

-- a) Durum bazinda sayim
SELECT status, count(*) AS siparis_sayisi
FROM orders
GROUP BY status
ORDER BY siparis_sayisi DESC;

-- b) Yuzde payiyla birlikte
SELECT status,
       count(*) AS siparis_sayisi,
       round(100.0 * count(*) / (SELECT count(*) FROM orders), 2) AS yuzde
FROM orders
GROUP BY status
ORDER BY siparis_sayisi DESC;

-- c) HAVING: yalnizca 5000'den fazla siparis iceren durumlar
SELECT status, count(*) AS siparis_sayisi
FROM orders
GROUP BY status
HAVING count(*) > 5000
ORDER BY siparis_sayisi DESC;

-- d) Iki kolonlu gruplama: durum + ulke (ilk 15)
SELECT status, shipping_country, count(*) AS siparis_sayisi
FROM orders
GROUP BY status, shipping_country
ORDER BY siparis_sayisi DESC
LIMIT 15;

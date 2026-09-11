-- q16_q17_ortalama_sepet_ve_kalem.sql
-- Soru 16: Siparis basina ortalama sepet tutari.
-- Soru 17: Siparis basina ortalama kalem sayisi.
-- Konu: turetilmis tablo (FROM icinde alt sorgu), ortalamalarin ortalamasi tuzagi
-- Kapsam: paid + shipped + delivered siparisler.

-- 16a) Ortalama sepet tutari (dogru: once siparis basina topla, sonra ortala)
SELECT count(*)                        AS siparis_sayisi,
       round(avg(siparis_toplami), 2)  AS ortalama_sepet,
       round(min(siparis_toplami), 2)  AS en_kucuk_sepet,
       round(max(siparis_toplami), 2)  AS en_buyuk_sepet
FROM (
    SELECT oi.order_id,
           sum(oi.quantity * oi.unit_price) AS siparis_toplami
    FROM order_items oi
    JOIN orders o ON o.id = oi.order_id
    WHERE o.status IN ('paid', 'shipped', 'delivered')
    GROUP BY oi.order_id
) AS siparisler;

-- 16b) YANLIS yaklasim: kalem ortalamasi (siparis ortalamasi degil)
SELECT round(avg(oi.quantity * oi.unit_price), 2) AS kalem_ortalamasi_YANLIS
FROM order_items oi
JOIN orders o ON o.id = oi.order_id
WHERE o.status IN ('paid', 'shipped', 'delivered');

-- 17) Siparis basina ortalama kalem sayisi ve kalem sayisi dagilimi
SELECT round(avg(kalem_sayisi), 3) AS ortalama_kalem,
       min(kalem_sayisi)           AS en_az,
       max(kalem_sayisi)           AS en_cok
FROM (
    SELECT oi.order_id, count(*) AS kalem_sayisi
    FROM order_items oi
    JOIN orders o ON o.id = oi.order_id
    WHERE o.status IN ('paid', 'shipped', 'delivered')
    GROUP BY oi.order_id
) AS siparisler;

SELECT kalem_sayisi,
       count(*) AS siparis_sayisi,
       round(100.0 * count(*) / sum(count(*)) OVER (), 2) AS yuzde
FROM (
    SELECT oi.order_id, count(*) AS kalem_sayisi
    FROM order_items oi
    JOIN orders o ON o.id = oi.order_id
    WHERE o.status IN ('paid', 'shipped', 'delivered')
    GROUP BY oi.order_id
) AS siparisler
GROUP BY kalem_sayisi
ORDER BY kalem_sayisi;

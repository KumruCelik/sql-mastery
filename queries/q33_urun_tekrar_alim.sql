-- q33_urun_tekrar_alim.sql
-- Soru: Ayni kullanicinin ayni urunu tekrar alma orani nedir? (zorunlu)
-- Konu: kullanici-urun tanecigi, FILTER ile oran, minimum hacim esigi
-- Kapsam: paid + shipped + delivered siparisler.

-- a) Genel tekrar alim orani
WITH kullanici_urun AS (
    SELECT o.user_id,
           oi.product_id,
           count(DISTINCT o.id) AS kac_siparis
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    WHERE o.status IN ('paid', 'shipped', 'delivered')
    GROUP BY o.user_id, oi.product_id
)
SELECT count(*)                                                        AS kullanici_urun_cifti,
       count(*) FILTER (WHERE kac_siparis >= 2)                        AS tekrar_alinan_cift,
       round(100.0 * count(*) FILTER (WHERE kac_siparis >= 2) / count(*), 2) AS tekrar_alim_orani,
       max(kac_siparis)                                                AS en_cok_tekrar
FROM kullanici_urun;

-- b) Urun bazinda tekrar alim orani (en az 100 farkli kullanici almis urunler)
WITH kullanici_urun AS (
    SELECT o.user_id, oi.product_id, count(DISTINCT o.id) AS kac_siparis
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    WHERE o.status IN ('paid','shipped','delivered')
    GROUP BY o.user_id, oi.product_id
)
SELECT ku.product_id,
       p.sku,
       p.list_price,
       count(*)                                                          AS alan_kullanici,
       count(*) FILTER (WHERE ku.kac_siparis >= 2)                       AS tekrar_alan,
       round(100.0 * count(*) FILTER (WHERE ku.kac_siparis >= 2) / count(*), 2) AS tekrar_orani
FROM kullanici_urun ku
JOIN products p ON p.id = ku.product_id
GROUP BY ku.product_id, p.sku, p.list_price
HAVING count(*) >= 100
ORDER BY tekrar_orani DESC, ku.product_id
LIMIT 15;

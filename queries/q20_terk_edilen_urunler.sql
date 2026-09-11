-- q20_terk_edilen_urunler.sql
-- Soru: Sepete girip satin alinmayan urunler hangileri? (zorunlu)
-- Kapsam: semada sepet tablosu yok. En yakin karsilik olarak
--         'cancelled' ve 'created' durumundaki siparislerdeki urunler alindi.
-- Konu: FILTER ile kosullu toplama, oran hesabi, minimum hacim esigi

-- a) Genel buyukluk: terk edilen adet ve tutar
SELECT sum(oi.quantity)                                    AS terk_edilen_adet,
       round(sum(oi.quantity * oi.unit_price), 2)          AS terk_edilen_tutar,
       count(DISTINCT o.id)                                AS siparis_sayisi,
       count(DISTINCT oi.product_id)                       AS etkilenen_urun
FROM order_items oi
JOIN orders o ON o.id = oi.order_id
WHERE o.status IN ('created', 'cancelled');

-- b) Urun basina terk orani (en az 100 adet hareket gormus urunler)
SELECT p.id,
       p.sku,
       p.list_price,
       sum(oi.quantity)                                                              AS toplam_adet,
       sum(oi.quantity) FILTER (WHERE o.status IN ('paid','shipped','delivered'))     AS satilan,
       sum(oi.quantity) FILTER (WHERE o.status IN ('created','cancelled'))            AS terk_edilen,
       round(100.0 * sum(oi.quantity) FILTER (WHERE o.status IN ('created','cancelled'))
                   / NULLIF(sum(oi.quantity), 0), 2)                                  AS terk_orani
FROM order_items oi
JOIN orders o   ON o.id = oi.order_id
JOIN products p ON p.id = oi.product_id
GROUP BY p.id, p.sku, p.list_price
HAVING sum(oi.quantity) >= 100
ORDER BY terk_orani DESC, p.id
LIMIT 15;

-- c) Esik koymazsak ne olur? (kucuk payda gurultusu)
SELECT count(*) AS terk_orani_yuzde_100_olan_urun
FROM (
    SELECT p.id, sum(oi.quantity) AS toplam_adet,
           sum(oi.quantity) FILTER (WHERE o.status IN ('created','cancelled')) AS terk
    FROM order_items oi
    JOIN orders o   ON o.id = oi.order_id
    JOIN products p ON p.id = oi.product_id
    GROUP BY p.id
) t
WHERE terk = toplam_adet;

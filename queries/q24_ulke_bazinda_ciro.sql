-- q24_ulke_bazinda_ciro.sql
-- Soru: Ulke bazinda siparis sayisi ve ciro nedir?
-- Konu: COALESCE ile NULL grubunu etiketleme, IS DISTINCT FROM
-- Kapsam: paid + shipped + delivered siparisler.

-- a) Ulke bazinda dagilim
SELECT COALESCE(o.shipping_country, 'bilinmiyor')                            AS ulke,
       count(DISTINCT o.id)                                                  AS siparis,
       sum(oi.quantity)                                                      AS adet,
       round(sum(oi.quantity * oi.unit_price), 2)                            AS ciro,
       round(sum(oi.quantity * oi.unit_price) / count(DISTINCT o.id), 2)     AS ort_sepet,
       round(100.0 * sum(oi.quantity * oi.unit_price)
             / (SELECT sum(oi2.quantity * oi2.unit_price)
                  FROM order_items oi2
                  JOIN orders o2 ON o2.id = oi2.order_id
                 WHERE o2.status IN ('paid','shipped','delivered')), 2)      AS ciro_payi
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
WHERE o.status IN ('paid', 'shipped', 'delivered')
GROUP BY ulke
ORDER BY ciro DESC;

-- b) Tutarlilik: siparisin gonderi ulkesi, kullanicinin ulkesiyle ayni mi?
SELECT count(*)                                                          AS toplam_siparis,
       count(*) FILTER (WHERE u.country IS NOT DISTINCT FROM o.shipping_country) AS ayni,
       count(*) FILTER (WHERE u.country IS DISTINCT FROM o.shipping_country)     AS farkli,
       round(100.0 * count(*) FILTER (WHERE u.country IS DISTINCT FROM o.shipping_country)
                   / count(*), 2)                                         AS farkli_yuzde
FROM orders o
JOIN users u ON u.id = o.user_id;

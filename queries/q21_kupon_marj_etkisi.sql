-- q21_kupon_marj_etkisi.sql
-- Soru: Kupon kullaniminin marj uzerindeki etkisi nedir? (zorunlu)
-- Konu: CTE (WITH), cifte fan-out'tan kacinma, FILTER
-- Kapsam: paid + shipped + delivered siparisler.

-- a) CIFTE FAN-OUT'UN KANITI: uc tabloyu dogrudan birlestirince satirlar cogaliyor
SELECT count(*) AS dogrudan_join_satir
FROM orders o
JOIN order_items oi   ON oi.order_id = o.id
JOIN order_coupons oc ON oc.order_id = o.id
WHERE o.status IN ('paid', 'shipped', 'delivered');

SELECT count(*) AS kuponlu_kalem_satiri
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
WHERE o.status IN ('paid', 'shipped', 'delivered')
  AND EXISTS (SELECT 1 FROM order_coupons oc WHERE oc.order_id = o.id);

-- b) DOGRU YAKLASIM: her tabloyu kendi taneciginde topla, sonra birlestir
WITH siparis_marji AS (
    SELECT o.id                                            AS order_id,
           sum(oi.quantity * oi.unit_price)                AS sepet_tutari,
           sum(oi.quantity * (oi.unit_price - oi.unit_cost)) AS brut_marj
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    WHERE o.status IN ('paid', 'shipped', 'delivered')
    GROUP BY o.id
),
siparis_indirimi AS (
    SELECT order_id,
           sum(discount_applied) AS indirim,
           count(*)              AS kupon_adedi
    FROM order_coupons
    GROUP BY order_id
)
SELECT CASE WHEN k.order_id IS NULL THEN 'kuponsuz' ELSE 'kuponlu' END AS grup,
       count(*)                                              AS siparis_sayisi,
       round(avg(s.sepet_tutari), 2)                         AS ort_sepet,
       round(avg(s.brut_marj), 2)                            AS ort_brut_marj,
       round(avg(COALESCE(k.indirim, 0)), 2)                 AS ort_indirim,
       round(avg(s.brut_marj - COALESCE(k.indirim, 0)), 2)   AS ort_net_marj,
       round(100.0 * avg(s.brut_marj) / avg(s.sepet_tutari), 2)                       AS brut_marj_yuzde,
       round(100.0 * avg(s.brut_marj - COALESCE(k.indirim, 0)) / avg(s.sepet_tutari), 2) AS net_marj_yuzde
FROM siparis_marji s
LEFT JOIN siparis_indirimi k ON k.order_id = s.order_id
GROUP BY grup
ORDER BY grup;

-- c) Toplam etki: kuponlarin goturdugu para
WITH siparis_marji AS (
    SELECT o.id AS order_id,
           sum(oi.quantity * (oi.unit_price - oi.unit_cost)) AS brut_marj
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    WHERE o.status IN ('paid', 'shipped', 'delivered')
    GROUP BY o.id
),
siparis_indirimi AS (
    SELECT order_id, sum(discount_applied) AS indirim
    FROM order_coupons
    GROUP BY order_id
)
SELECT round(sum(s.brut_marj), 2)                          AS toplam_brut_marj,
       round(sum(COALESCE(k.indirim, 0)), 2)               AS toplam_indirim,
       round(sum(s.brut_marj - COALESCE(k.indirim, 0)), 2) AS toplam_net_marj,
       round(100.0 * sum(COALESCE(k.indirim, 0)) / sum(s.brut_marj), 2) AS indirimin_marja_orani
FROM siparis_marji s
LEFT JOIN siparis_indirimi k ON k.order_id = s.order_id;

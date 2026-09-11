-- q40_q42_q43.sql
-- Soru 40: En sik birlikte satin alinan urun ciftleri. (self join ile cift uretme)
-- Soru 42: Kullanici yasam boyu degeri (LTV) ve ilk 90 gunun payi.
-- Soru 43: Stok defterinden gun gun stok seyri. (kumulatif toplam)
-- Kapsam: paid + shipped + delivered siparisler.

-- 40) Birlikte satin alinan urun ciftleri
SELECT oi1.product_id                 AS urun_a,
       p1.sku                         AS sku_a,
       oi2.product_id                 AS urun_b,
       p2.sku                         AS sku_b,
       count(DISTINCT oi1.order_id)   AS birlikte_siparis
FROM order_items oi1
JOIN order_items oi2 ON oi2.order_id = oi1.order_id
                    AND oi1.product_id < oi2.product_id   -- < ile her cift bir kez
JOIN orders o   ON o.id = oi1.order_id
JOIN products p1 ON p1.id = oi1.product_id
JOIN products p2 ON p2.id = oi2.product_id
WHERE o.status IN ('paid', 'shipped', 'delivered')
GROUP BY oi1.product_id, p1.sku, oi2.product_id, p2.sku
ORDER BY birlikte_siparis DESC, urun_a, urun_b
LIMIT 15;

-- 42) LTV ve ilk 90 gunun payi
WITH ilk_gun AS (
    SELECT user_id, min(ordered_at) AS ilk_siparis
    FROM orders
    WHERE status IN ('paid','shipped','delivered')
    GROUP BY user_id
),
harcama AS (
    SELECT o.user_id,
           sum(oi.quantity * oi.unit_price)                                        AS ltv,
           sum(oi.quantity * oi.unit_price) FILTER (
               WHERE o.ordered_at < i.ilk_siparis + interval '90 days')             AS ilk90,
           max(o.ordered_at)::date - min(o.ordered_at)::date                        AS musteri_omru_gun
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    JOIN ilk_gun i      ON i.user_id = o.user_id
    WHERE o.status IN ('paid','shipped','delivered')
    GROUP BY o.user_id
)
SELECT count(*)                                                             AS musteri,
       round(avg(ltv), 2)                                                   AS ort_ltv,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY ltv)::numeric, 2)  AS medyan_ltv,
       round(avg(ilk90), 2)                                                 AS ort_ilk90,
       round(100.0 * sum(ilk90) / sum(ltv), 2)                              AS ilk90_payi_yuzde,
       round(avg(musteri_omru_gun), 1)                                      AS ort_omur_gun
FROM harcama;

-- 43) Stok seyri: tek urun icin gun gun kumulatif bakiye
SELECT m.occurred_at::date                                              AS gun,
       sum(m.quantity)                                                  AS gunluk_hareket,
       sum(sum(m.quantity)) OVER (ORDER BY m.occurred_at::date)         AS kumulatif_stok
FROM inventory_movements m
WHERE m.product_id = 169
GROUP BY m.occurred_at::date
ORDER BY gun
LIMIT 20;

-- 43b) Stogu ilk kez negatife dusen gun (urun 169)
WITH gunluk AS (
    SELECT m.occurred_at::date AS gun,
           sum(sum(m.quantity)) OVER (ORDER BY m.occurred_at::date) AS kumulatif
    FROM inventory_movements m
    WHERE m.product_id = 169
    GROUP BY m.occurred_at::date
)
SELECT min(gun) AS ilk_negatif_gun, min(kumulatif) AS en_dip
FROM gunluk
WHERE kumulatif < 0;

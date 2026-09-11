-- q28_hareketli_ortalama.sql
-- Soru: Urun basina 7 gunluk hareketli ortalama satis. (zorunlu)
-- Konu: pencere cercevesi, ROWS vs RANGE, eksik gunler, generate_series, WINDOW yan tumcesi
-- Kapsam: paid + shipped + delivered siparisler.

-- a) ROWS ve RANGE karsilastirmasi: yogun bir urun (169) ve seyrek bir urun (1488)
WITH gunluk AS (
    SELECT oi.product_id,
           o.ordered_at::date  AS gun,
           sum(oi.quantity)    AS adet
    FROM order_items oi
    JOIN orders o ON o.id = oi.order_id
    WHERE o.status IN ('paid', 'shipped', 'delivered')
      AND oi.product_id IN (169, 1488)
    GROUP BY oi.product_id, gun
)
SELECT product_id,
       gun,
       adet,
       count(*)          OVER w_rows  AS pencere_satir,
       round(avg(adet)   OVER w_rows, 2) AS ma7_rows,
       count(*)          OVER w_range AS pencere_gun,
       round(avg(adet)   OVER w_range, 2) AS ma7_range
FROM gunluk
WINDOW w_rows  AS (PARTITION BY product_id ORDER BY gun
                   ROWS  BETWEEN 6 PRECEDING AND CURRENT ROW),
       w_range AS (PARTITION BY product_id ORDER BY gun
                   RANGE BETWEEN INTERVAL '6 days' PRECEDING AND CURRENT ROW)
ORDER BY product_id, gun
LIMIT 30;

-- b) Seyrek satan urunde satirlar kac gune yayiliyor?
WITH gunluk AS (
    SELECT oi.product_id, o.ordered_at::date AS gun, sum(oi.quantity) AS adet
    FROM order_items oi
    JOIN orders o ON o.id = oi.order_id
    WHERE o.status IN ('paid','shipped','delivered') AND oi.product_id = 1488
    GROUP BY oi.product_id, gun
)
SELECT count(*)                                   AS satisli_gun_sayisi,
       min(gun)                                   AS ilk_satis,
       max(gun)                                   AS son_satis,
       (max(gun) - min(gun))                      AS kapsanan_gun,
       round(100.0 * count(*) / (max(gun) - min(gun) + 1), 2) AS satisli_gun_yuzdesi
FROM gunluk;

-- c) DOGRU hareketli ortalama: bos gunler sifirla dolduruluyor (urun 1488, 2026 Q1)
WITH gunler AS (
    SELECT generate_series(date '2026-01-01', date '2026-03-31', interval '1 day')::date AS gun
),
gunluk AS (
    SELECT o.ordered_at::date AS gun, sum(oi.quantity) AS adet
    FROM order_items oi
    JOIN orders o ON o.id = oi.order_id
    WHERE o.status IN ('paid','shipped','delivered') AND oi.product_id = 1488
    GROUP BY gun
)
SELECT g.gun,
       COALESCE(d.adet, 0) AS adet,
       round(avg(COALESCE(d.adet, 0)) OVER (ORDER BY g.gun
                                            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 3) AS ma7_dogru
FROM gunler g
LEFT JOIN gunluk d ON d.gun = g.gun
ORDER BY g.gun
LIMIT 30;

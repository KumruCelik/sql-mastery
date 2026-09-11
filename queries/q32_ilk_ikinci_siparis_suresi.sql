-- q32_ilk_ikinci_siparis_suresi.sql
-- Soru: Ilk siparis ile ikinci siparis arasindaki medyan sure. (zorunlu)
-- Konu: ROW_NUMBER ile siparis sirasi, percentile_cont, medyan vs ortalama
-- Kapsam: paid + shipped + delivered siparisler.

-- a) Medyan ve diger yuzdelikler
WITH siralanmis AS (
    SELECT o.user_id,
           o.ordered_at,
           ROW_NUMBER() OVER (PARTITION BY o.user_id ORDER BY o.ordered_at, o.id) AS siparis_sirasi
    FROM orders o
    WHERE o.status IN ('paid', 'shipped', 'delivered')
),
ilk_iki AS (
    SELECT user_id,
           max(ordered_at) FILTER (WHERE siparis_sirasi = 1) AS ilk,
           max(ordered_at) FILTER (WHERE siparis_sirasi = 2) AS ikinci
    FROM siralanmis
    WHERE siparis_sirasi <= 2
    GROUP BY user_id
),
farklar AS (
    SELECT user_id,
           EXTRACT(EPOCH FROM (ikinci - ilk)) / 86400.0 AS gun_farki
    FROM ilk_iki
    WHERE ikinci IS NOT NULL
)
SELECT count(*)                                                              AS ikinci_siparis_veren,
       round(avg(gun_farki)::numeric, 2)                                     AS ortalama_gun,
       round(percentile_cont(0.25) WITHIN GROUP (ORDER BY gun_farki)::numeric, 2) AS p25,
       round(percentile_cont(0.50) WITHIN GROUP (ORDER BY gun_farki)::numeric, 2) AS medyan,
       round(percentile_cont(0.75) WITHIN GROUP (ORDER BY gun_farki)::numeric, 2) AS p75,
       round(percentile_cont(0.90) WITHIN GROUP (ORDER BY gun_farki)::numeric, 2) AS p90,
       round(max(gun_farki)::numeric, 2)                                     AS en_uzun
FROM farklar;

-- b) Kac musteri hic ikinci siparis vermemis?
WITH siparis_sayilari AS (
    SELECT user_id, count(*) AS siparis
    FROM orders
    WHERE status IN ('paid','shipped','delivered')
    GROUP BY user_id
)
SELECT count(*)                                            AS siparis_veren_musteri,
       count(*) FILTER (WHERE siparis = 1)                 AS tek_siparisli,
       count(*) FILTER (WHERE siparis >= 2)                AS tekrar_eden,
       round(100.0 * count(*) FILTER (WHERE siparis >= 2) / count(*), 2) AS tekrar_orani
FROM siparis_sayilari;

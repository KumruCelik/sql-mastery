-- q39_q45_siparis_ritmi_ve_terk.sql
-- Soru 39: Kullanici basina siparis araliklarinin ortalamasi.
-- Soru 45: Terk orani - daha once siparis vermis ama son 90 gundur vermeyen kullanicilar.
-- Konu: LAG ile ardisik fark, sabit esik vs kisiye ozel esik
-- Kapsam: paid + shipped + delivered siparisler.

-- 39) Siparis araliklari
WITH siralanmis AS (
    SELECT o.user_id,
           o.ordered_at,
           LAG(o.ordered_at) OVER (PARTITION BY o.user_id ORDER BY o.ordered_at, o.id) AS onceki
    FROM orders o
    WHERE o.status IN ('paid', 'shipped', 'delivered')
),
araliklar AS (
    SELECT user_id,
           EXTRACT(EPOCH FROM (ordered_at - onceki)) / 86400.0 AS gun
    FROM siralanmis
    WHERE onceki IS NOT NULL
),
musteri_ritmi AS (
    SELECT user_id, count(*) AS aralik_sayisi, avg(gun) AS ort_aralik_gun
    FROM araliklar
    GROUP BY user_id
)
SELECT count(*)                                                                  AS musteri,
       round(avg(ort_aralik_gun)::numeric, 2)                                    AS ortalamalarin_ortalamasi,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY ort_aralik_gun)::numeric, 2) AS medyan_musteri_ritmi,
       round((SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY gun) FROM araliklar)::numeric, 2) AS medyan_aralik_ham
FROM musteri_ritmi;

-- 45) Terk: sabit 90 gun esigi vs kisiye ozel esik
WITH ufuk AS (
    SELECT max(ordered_at)::date AS son_gun
    FROM orders WHERE status IN ('paid','shipped','delivered')
),
siralanmis AS (
    SELECT o.user_id, o.ordered_at,
           LAG(o.ordered_at) OVER (PARTITION BY o.user_id ORDER BY o.ordered_at, o.id) AS onceki
    FROM orders o
    WHERE o.status IN ('paid','shipped','delivered')
),
musteri AS (
    SELECT s.user_id,
           max(s.ordered_at)::date AS son_siparis,
           count(*)                AS siparis,
           avg(EXTRACT(EPOCH FROM (s.ordered_at - s.onceki)) / 86400.0) AS ort_aralik_gun
    FROM siralanmis s
    GROUP BY s.user_id
)
SELECT count(*)                                                                     AS musteri,
       count(*) FILTER (WHERE u.son_gun - m.son_siparis > 90)                        AS terk_sabit_90,
       round(100.0 * count(*) FILTER (WHERE u.son_gun - m.son_siparis > 90) / count(*), 2) AS terk_sabit_yuzde,
       count(*) FILTER (WHERE m.ort_aralik_gun IS NOT NULL
                          AND u.son_gun - m.son_siparis > 2 * m.ort_aralik_gun)      AS terk_kisiye_ozel,
       round(100.0 * count(*) FILTER (WHERE m.ort_aralik_gun IS NOT NULL
                          AND u.son_gun - m.son_siparis > 2 * m.ort_aralik_gun)
                   / count(*), 2)                                                    AS terk_kisiye_ozel_yuzde,
       count(*) FILTER (WHERE m.ort_aralik_gun IS NULL)                              AS tek_siparisli_olcelemeyen
FROM musteri m
CROSS JOIN ufuk u;

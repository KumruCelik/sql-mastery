-- q41_q44_musteri_sirasi_ve_pareto.sql
-- Soru 41: Her ayin en iyi 3 musterisi.
-- Soru 44: Ciroda ilk %20 musterinin payi (Pareto).
-- Konu: RANK, kumulatif toplam, PERCENT_RANK, yogunlasma olcumu
-- Kapsam: paid + shipped + delivered siparisler.

-- 41) Her ayin en iyi 3 musterisi
WITH aylik_musteri AS (
    SELECT date_trunc('month', o.ordered_at)::date     AS ay,
           o.user_id,
           count(DISTINCT o.id)                        AS siparis,
           sum(oi.quantity * oi.unit_price)            AS harcama
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    WHERE o.status IN ('paid', 'shipped', 'delivered')
    GROUP BY ay, o.user_id
),
siralanmis AS (
    SELECT *,
           RANK() OVER (PARTITION BY ay ORDER BY harcama DESC)        AS sira,
           sum(harcama) OVER (PARTITION BY ay)                        AS ay_toplam
    FROM aylik_musteri
)
SELECT ay, sira, user_id, siparis,
       round(harcama, 2)                        AS harcama,
       round(100.0 * harcama / ay_toplam, 2)    AS ay_icindeki_pay
FROM siralanmis
WHERE sira <= 3
  AND ay >= date '2025-10-01'
ORDER BY ay, sira;

-- 44) Pareto: musterilerin ilk yuzdeliklerinde cironun ne kadari birikiyor?
WITH musteri AS (
    SELECT o.user_id,
           sum(oi.quantity * oi.unit_price) AS harcama
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    WHERE o.status IN ('paid', 'shipped', 'delivered')
    GROUP BY o.user_id
),
kumulatif AS (
    SELECT user_id,
           harcama,
           ROW_NUMBER() OVER (ORDER BY harcama DESC, user_id)          AS musteri_sirasi,
           count(*)     OVER ()                                        AS toplam_musteri,
           sum(harcama) OVER (ORDER BY harcama DESC, user_id)          AS kumulatif_ciro,
           sum(harcama) OVER ()                                        AS toplam_ciro
    FROM musteri
)
SELECT round(100.0 * musteri_sirasi / toplam_musteri, 0)  AS musteri_yuzdeligi,
       min(musteri_sirasi)                                AS kacinci_musteriden,
       round(min(100.0 * kumulatif_ciro / toplam_ciro), 2) AS bu_noktada_ciro_payi
FROM kumulatif
WHERE musteri_sirasi IN (
        SELECT round(toplam_musteri * p / 100.0)::int
        FROM kumulatif, (VALUES (1),(5),(10),(20),(30),(50),(80),(100)) AS v(p)
        LIMIT 8
      )
   OR musteri_sirasi = toplam_musteri
GROUP BY musteri_yuzdeligi
ORDER BY musteri_yuzdeligi;

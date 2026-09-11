-- q27_rfm_segmentasyonu.sql
-- Soru: RFM segmentasyonu (NTILE ile). (zorunlu)
-- Konu: NTILE, kuantil bolme, CROSS JOIN ile skaler tasima, corr()
-- Kapsam: paid + shipped + delivered siparisler.

-- a) Segment dagilimi
WITH musteri AS (
    SELECT o.user_id,
           max(o.ordered_at)::date          AS son_siparis,
           count(DISTINCT o.id)             AS siparis_sayisi,
           sum(oi.quantity * oi.unit_price) AS toplam_harcama
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    WHERE o.status IN ('paid', 'shipped', 'delivered')
    GROUP BY o.user_id
),
referans AS (
    SELECT max(son_siparis) AS ufuk FROM musteri
),
skorlu AS (
    SELECT m.user_id,
           (r.ufuk - m.son_siparis)                     AS recency_gun,
           m.siparis_sayisi,
           m.toplam_harcama,
           NTILE(5) OVER (ORDER BY m.son_siparis)       AS r_skor,
           NTILE(5) OVER (ORDER BY m.siparis_sayisi)    AS f_skor,
           NTILE(5) OVER (ORDER BY m.toplam_harcama)    AS m_skor
    FROM musteri m
    CROSS JOIN referans r
)
SELECT CASE
           WHEN r_skor = 5 AND f_skor >= 4 THEN 'Sampiyon'
           WHEN f_skor >= 4 AND r_skor <= 2 THEN 'Riskli sadik'
           WHEN r_skor = 5 AND f_skor <= 2 THEN 'Yeni musteri'
           WHEN r_skor <= 2 AND f_skor <= 2 THEN 'Kayip'
           ELSE 'Orta'
       END                                                  AS segment,
       count(*)                                             AS musteri,
       round(100.0 * count(*) / sum(count(*)) OVER (), 2)   AS yuzde,
       round(avg(recency_gun), 1)                           AS ort_recency_gun,
       round(avg(siparis_sayisi), 2)                        AS ort_siparis,
       round(avg(toplam_harcama), 2)                        AS ort_harcama,
       round(sum(toplam_harcama), 2)                        AS toplam_ciro
FROM skorlu
GROUP BY segment
ORDER BY toplam_ciro DESC;

-- b) F ve M gercekten ayri bilgi mi tasiyor? Korelasyonu olcelim.
WITH musteri AS (
    SELECT o.user_id,
           max(o.ordered_at)::date          AS son_siparis,
           count(DISTINCT o.id)             AS siparis_sayisi,
           sum(oi.quantity * oi.unit_price) AS toplam_harcama
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    WHERE o.status IN ('paid','shipped','delivered')
    GROUP BY o.user_id
),
referans AS (SELECT max(son_siparis) AS ufuk FROM musteri),
skorlu AS (
    SELECT (r.ufuk - m.son_siparis)                  AS recency_gun,
           m.siparis_sayisi,
           m.toplam_harcama,
           NTILE(5) OVER (ORDER BY m.son_siparis)    AS r_skor,
           NTILE(5) OVER (ORDER BY m.siparis_sayisi) AS f_skor,
           NTILE(5) OVER (ORDER BY m.toplam_harcama) AS m_skor
    FROM musteri m CROSS JOIN referans r
)
SELECT round(corr(siparis_sayisi, toplam_harcama)::numeric, 4)  AS f_m_korelasyon,
       round(corr(recency_gun,    siparis_sayisi)::numeric, 4)  AS r_f_korelasyon,
       count(*)                                                 AS musteri,
       count(*) FILTER (WHERE f_skor = m_skor)                   AS f_ve_m_ayni_dilim,
       round(100.0 * count(*) FILTER (WHERE f_skor = m_skor) / count(*), 2) AS ayni_dilim_yuzde
FROM skorlu;

-- c) NTILE tuzagi: kac musteri tam olarak 1 siparis vermis ve hangi dilimlere dagilmislar?
WITH musteri AS (
    SELECT o.user_id, count(DISTINCT o.id) AS siparis_sayisi
    FROM orders o
    WHERE o.status IN ('paid','shipped','delivered')
    GROUP BY o.user_id
),
skorlu AS (
    SELECT siparis_sayisi, NTILE(5) OVER (ORDER BY siparis_sayisi) AS f_skor
    FROM musteri
)
SELECT siparis_sayisi,
       count(*)              AS musteri,
       min(f_skor)           AS en_dusuk_dilim,
       max(f_skor)           AS en_yuksek_dilim,
       count(DISTINCT f_skor) AS kac_farkli_dilime_dagilmis
FROM skorlu
GROUP BY siparis_sayisi
ORDER BY siparis_sayisi
LIMIT 10;

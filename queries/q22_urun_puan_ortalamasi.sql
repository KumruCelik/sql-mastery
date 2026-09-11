-- q22_urun_puan_ortalamasi.sql
-- Soru: Urun basina ortalama puan ve yorum sayisi nedir?
-- Konu: CTE, "en buyuge self-join" kalibi, tekrarli yorumlarin ortalamaya etkisi
-- Baglam: K-005 geregi ayni kullanici ayni urune birden cok yorum yazabilir.

-- a) Tekrarli ciftlerin buyuklugu
SELECT count(*) AS toplam_yorum,
       count(DISTINCT (user_id, product_id)) AS benzersiz_kullanici_urun_cifti,
       count(*) - count(DISTINCT (user_id, product_id)) AS fazladan_yorum
FROM reviews;

-- b) NAIF hesap: butun yorumlar sayilir
SELECT p.id, p.sku,
       count(*)                 AS yorum_sayisi,
       round(avg(r.rating), 3)  AS ort_puan
FROM reviews r
JOIN products p ON p.id = r.product_id
GROUP BY p.id, p.sku
ORDER BY yorum_sayisi DESC, p.id
LIMIT 10;

-- c) TEKILLESTIRILMIS hesap: kullanici-urun basina yalnizca en son yorum
WITH son_yorum AS (
    SELECT user_id, product_id, max(created_at) AS son_tarih
    FROM reviews
    GROUP BY user_id, product_id
),
tekil_yorumlar AS (
    SELECT r.*
    FROM reviews r
    JOIN son_yorum s
      ON s.user_id    = r.user_id
     AND s.product_id = r.product_id
     AND s.son_tarih  = r.created_at
)
SELECT p.id, p.sku,
       count(*)                 AS yorum_sayisi,
       round(avg(t.rating), 3)  AS ort_puan
FROM tekil_yorumlar t
JOIN products p ON p.id = t.product_id
GROUP BY p.id, p.sku
ORDER BY yorum_sayisi DESC, p.id
LIMIT 10;

-- d) Iki hesabin farki: kac urunde ortalama puan degisiyor, ne kadar?
WITH son_yorum AS (
    SELECT user_id, product_id, max(created_at) AS son_tarih
    FROM reviews
    GROUP BY user_id, product_id
),
tekil AS (
    SELECT r.product_id, r.rating
    FROM reviews r
    JOIN son_yorum s
      ON s.user_id    = r.user_id
     AND s.product_id = r.product_id
     AND s.son_tarih  = r.created_at
),
naif_ort AS (
    SELECT product_id, avg(rating) AS ort, count(*) AS adet
    FROM reviews GROUP BY product_id
),
tekil_ort AS (
    SELECT product_id, avg(rating) AS ort, count(*) AS adet
    FROM tekil GROUP BY product_id
)
SELECT count(*)                                                   AS urun_sayisi,
       count(*) FILTER (WHERE n.ort <> t.ort)                      AS ortalamasi_degisen,
       round(max(abs(n.ort - t.ort)), 3)                           AS en_buyuk_sapma,
       round(avg(abs(n.ort - t.ort)), 4)                           AS ortalama_sapma
FROM naif_ort n
JOIN tekil_ort t ON t.product_id = n.product_id;

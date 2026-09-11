-- q35_son_yorum.sql
-- Soru: Kullanici-urun basina en son yorum.
-- Konu: DISTINCT ON, ROW_NUMBER ile esdeger yazim, ikisinin karsilastirilmasi

-- a) DISTINCT ON ile
SELECT DISTINCT ON (user_id, product_id)
       user_id, product_id, rating, created_at
FROM reviews
ORDER BY user_id, product_id, created_at DESC, id DESC
LIMIT 10;

-- b) ROW_NUMBER ile ayni sonuc (tasinabilir yazim)
WITH numarali AS (
    SELECT user_id, product_id, rating, created_at,
           ROW_NUMBER() OVER (PARTITION BY user_id, product_id
                              ORDER BY created_at DESC, id DESC) AS sira
    FROM reviews
)
SELECT user_id, product_id, rating, created_at
FROM numarali
WHERE sira = 1
ORDER BY user_id, product_id
LIMIT 10;

-- c) Iki yontem ayni satir sayisini mi veriyor?
SELECT (SELECT count(*) FROM (
            SELECT DISTINCT ON (user_id, product_id) id
            FROM reviews
            ORDER BY user_id, product_id, created_at DESC, id DESC
        ) t)                                            AS distinct_on_satir,
       (SELECT count(*) FROM (
            SELECT ROW_NUMBER() OVER (PARTITION BY user_id, product_id
                                      ORDER BY created_at DESC, id DESC) AS sira
            FROM reviews
        ) t WHERE sira = 1)                             AS row_number_satir,
       (SELECT count(DISTINCT (user_id, product_id)) FROM reviews) AS benzersiz_cift;

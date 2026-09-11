-- q29_ardisik_gun_serileri.sql
-- Soru: Ardisik gunlerde alisveris yapan kullanici serileri. (zorunlu)
-- Konu: gaps and islands, ROW_NUMBER ile ada anahtari uretme
-- Kapsam: paid + shipped + delivered siparisler.

-- a) Numaranin nasil calistigini goster (ornek: en aktif kullanici)
WITH gunler AS (
    SELECT DISTINCT o.user_id, o.ordered_at::date AS gun
    FROM orders o
    WHERE o.status IN ('paid','shipped','delivered')
      AND o.user_id = 6754
),
numarali AS (
    SELECT user_id, gun,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY gun) AS sira,
           gun - (ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY gun))::int AS ada_anahtari
    FROM gunler
)
SELECT * FROM numarali ORDER BY gun LIMIT 20;

-- b) Serileri cikar
WITH gunler AS (
    SELECT DISTINCT o.user_id, o.ordered_at::date AS gun
    FROM orders o
    WHERE o.status IN ('paid','shipped','delivered')
),
numarali AS (
    SELECT user_id, gun,
           gun - (ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY gun))::int AS ada_anahtari
    FROM gunler
),
seriler AS (
    SELECT user_id,
           min(gun)   AS seri_baslangic,
           max(gun)   AS seri_bitis,
           count(*)   AS seri_uzunlugu
    FROM numarali
    GROUP BY user_id, ada_anahtari
)
SELECT seri_uzunlugu,
       count(*)                                                        AS seri_sayisi,
       count(DISTINCT user_id)                                         AS kullanici_sayisi,
       round(100.0 * count(*) / sum(count(*)) OVER (), 2)              AS yuzde
FROM seriler
GROUP BY seri_uzunlugu
ORDER BY seri_uzunlugu;

-- c) En uzun seriler
WITH gunler AS (
    SELECT DISTINCT o.user_id, o.ordered_at::date AS gun
    FROM orders o
    WHERE o.status IN ('paid','shipped','delivered')
),
numarali AS (
    SELECT user_id, gun,
           gun - (ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY gun))::int AS ada_anahtari
    FROM gunler
),
seriler AS (
    SELECT user_id, min(gun) AS baslangic, max(gun) AS bitis, count(*) AS uzunluk
    FROM numarali
    GROUP BY user_id, ada_anahtari
)
SELECT user_id, baslangic, bitis, uzunluk
FROM seriler
ORDER BY uzunluk DESC, user_id
LIMIT 15;

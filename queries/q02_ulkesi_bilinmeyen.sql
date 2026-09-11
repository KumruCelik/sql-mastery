-- q02_ulkesi_bilinmeyen.sql
-- Soru: Ulkesi bilinmeyen kullanici sayisi kac?
-- Konu: NULL, uc degerli mantik, count(*) vs count(kolon)

-- a) YANLIS yaklasim: NULL ile esitlik karsilastirmasi
--    Hata vermez, sessizce 0 doner. NULL tuzaginin ta kendisi.
SELECT count(*) AS yanlis_yontem
FROM users
WHERE country = NULL;

-- b) DOGRU yaklasim: IS NULL
SELECT count(*) AS ulkesi_bilinmeyen
FROM users
WHERE country IS NULL;

-- c) Ayni sonuca count(*) ile count(kolon) farkindan ulasmak
SELECT count(*)                      AS toplam_kullanici,
       count(country)                AS ulkesi_dolu,
       count(*) - count(country)     AS ulkesi_bos
FROM users;

-- d) Oran
SELECT round(100.0 * (count(*) - count(country)) / count(*), 2) AS bos_yuzde
FROM users;

-- e) Raporda NULL yerine durust bir etiket
SELECT COALESCE(country, 'bilinmiyor') AS ulke, count(*) AS kullanici
FROM users
GROUP BY COALESCE(country, 'bilinmiyor')
ORDER BY kullanici DESC;

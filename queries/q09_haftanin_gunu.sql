-- q09_haftanin_gunu.sql
-- Soru: Haftanin hangi gununde en cok siparis veriliyor?
-- Konu: EXTRACT, to_char, date_trunc, saat dilimi etkisi

-- a) Oturumun saat dilimi (sonuclarin yorumu buna bagli)
SHOW TimeZone;

-- b) Haftanin gunu bazinda siparis sayisi
SELECT EXTRACT(DOW FROM ordered_at)                                   AS gun_no,
       btrim(to_char(ordered_at, 'Day'))                              AS gun_adi,
       count(*)                                                       AS siparis,
       round(100.0 * count(*) / (SELECT count(*) FROM orders), 2)     AS yuzde
FROM orders
GROUP BY gun_no, gun_adi
ORDER BY siparis DESC;

-- c) Aylik dagilim: mevsimsellik goruncek
SELECT date_trunc('month', ordered_at)::date AS ay,
       count(*)                              AS siparis
FROM orders
GROUP BY ay
ORDER BY siparis DESC
LIMIT 12;

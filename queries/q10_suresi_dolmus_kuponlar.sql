-- q10_suresi_dolmus_kuponlar.sql
-- Soru: Gecerlilik suresi dolmus kupon kodlari hangileri?
-- Konu: tarih karsilastirma, referans tarihi secimi, CASE ile durum etiketi

-- a) Referans: verinin son siparis tarihi
SELECT max(ordered_at) AS veri_ufku FROM orders;

-- b) Kuponlarin durumu (referans: verinin son siparis tarihi)
SELECT code,
       discount_type,
       discount_value,
       valid_from::date AS baslangic,
       valid_to::date   AS bitis,
       CASE
           WHEN valid_to   < (SELECT max(ordered_at) FROM orders) THEN 'suresi dolmus'
           WHEN valid_from > (SELECT max(ordered_at) FROM orders) THEN 'henuz baslamamis'
           ELSE 'gecerli'
       END AS durum
FROM coupons
ORDER BY bitis;

-- c) Durum bazinda sayim
SELECT CASE
           WHEN valid_to   < (SELECT max(ordered_at) FROM orders) THEN 'suresi dolmus'
           WHEN valid_from > (SELECT max(ordered_at) FROM orders) THEN 'henuz baslamamis'
           ELSE 'gecerli'
       END AS durum,
       count(*) AS kupon_sayisi
FROM coupons
GROUP BY durum
ORDER BY kupon_sayisi DESC;

-- d) Kuponlarin gecerlilik suresi kac gun?
SELECT min(valid_to - valid_from) AS en_kisa,
       max(valid_to - valid_from) AS en_uzun,
       avg(valid_to - valid_from) AS ortalama
FROM coupons;

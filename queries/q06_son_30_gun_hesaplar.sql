-- q06_son_30_gun_hesaplar.sql
-- Soru: Son 30 gunde acilan hesap sayisi kac?
-- Konu: tarih aritmetigi, interval, now() vs veri setinin referans tarihi

-- a) Bugune gore "son 30 gun" -- veri seti eski oldugu icin bos donecek
SELECT count(*) AS bugune_gore
FROM users
WHERE created_at >= now() - interval '30 days';

-- b) Veri setinin sinirlari nerede?
SELECT min(created_at) AS ilk_kayit,
       max(created_at) AS son_kayit,
       now()           AS simdi
FROM users;

-- c) Dogru yaklasim: referans, verinin kendi son tarihi
SELECT count(*) AS son_30_gun
FROM users
WHERE created_at >= (SELECT max(created_at) FROM users) - interval '30 days';

-- d) Ayni mantikla son 7 ve son 90 gun
SELECT count(*) AS son_7_gun
FROM users
WHERE created_at >= (SELECT max(created_at) FROM users) - interval '7 days';

SELECT count(*) AS son_90_gun
FROM users
WHERE created_at >= (SELECT max(created_at) FROM users) - interval '90 days';

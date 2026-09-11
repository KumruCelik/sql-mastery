-- q01_pasif_kullanicilar.sql
-- Soru: Hesabi kapali (is_active = false) kullanicilar kimler, kac tane?

-- a) Kac tane?
SELECT count(*) AS pasif_kullanici_sayisi
FROM users
WHERE is_active = false;

-- b) En son olusturulmus 10 pasif hesap
SELECT id, email, country, created_at
FROM users
WHERE is_active = false
ORDER BY created_at DESC
LIMIT 10;

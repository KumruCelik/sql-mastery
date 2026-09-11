-- q25_kargo_teslim_suresi.sql
-- Soru: Kargo firmasi bazinda ortalama teslim suresi nedir?
-- Konu: interval aritmetigi, EXTRACT(EPOCH), hayatta kalma yanliligi (survivorship bias)

-- a) Kargo firmasi bazinda: teslim suresi VE teslim edilememe orani birlikte
SELECT carrier                                                                  AS kargo_firmasi,
       count(*)                                                                 AS gonderi,
       count(*) FILTER (WHERE delivered_at IS NOT NULL)                         AS teslim_edilen,
       count(*) FILTER (WHERE delivered_at IS NULL)                             AS teslim_edilmeyen,
       round(100.0 * count(*) FILTER (WHERE delivered_at IS NULL) / count(*), 2) AS teslim_edilmeme_yuzde,
       round(avg(EXTRACT(EPOCH FROM (delivered_at - shipped_at)) / 86400.0)::numeric, 2) AS ort_teslim_gun,
       round(min(EXTRACT(EPOCH FROM (delivered_at - shipped_at)) / 86400.0)::numeric, 2) AS en_hizli_gun,
       round(max(EXTRACT(EPOCH FROM (delivered_at - shipped_at)) / 86400.0)::numeric, 2) AS en_yavas_gun
FROM shipments
GROUP BY carrier
ORDER BY ort_teslim_gun;

-- b) Gonderi durumu dagilimi
SELECT status, count(*) AS gonderi,
       count(*) FILTER (WHERE delivered_at IS NULL) AS teslim_tarihi_bos
FROM shipments
GROUP BY status
ORDER BY gonderi DESC;

-- c) Genel: ortalama avg() kac satiri hesaba katti, kac satiri atladi?
SELECT count(*)                  AS toplam_gonderi,
       count(delivered_at)       AS ortalamaya_giren,
       count(*) - count(delivered_at) AS ortalamanin_disinda_kalan
FROM shipments;

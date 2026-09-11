-- q18_basarisiz_odeme_orani.sql
-- Soru: Odemesi basarisiz olan siparislerin orani nedir?
-- Konu: FILTER ile kosullu toplama, capraz tablo, veri tutarliligi kontrolu

-- a) Odeme kayitlarinin durum dagilimi
SELECT status,
       count(*)                                                       AS odeme_sayisi,
       round(100.0 * count(*) / (SELECT count(*) FROM payments), 2)    AS yuzde,
       round(sum(amount), 2)                                          AS toplam_tutar
FROM payments
GROUP BY status
ORDER BY odeme_sayisi DESC;

-- b) En az bir basarisiz odeme denemesi olan siparis orani
SELECT (SELECT count(*) FROM orders)                                       AS toplam_siparis,
       (SELECT count(DISTINCT order_id) FROM payments WHERE status = 'failed') AS basarisiz_denemeli,
       round(100.0 * (SELECT count(DISTINCT order_id) FROM payments WHERE status = 'failed')
                   / (SELECT count(*) FROM orders), 2)                     AS yuzde;

-- c) Capraz tablo: siparis durumu x odeme kayitlari
SELECT o.status                                              AS siparis_durumu,
       count(DISTINCT o.id)                                  AS siparis,
       count(DISTINCT o.id) FILTER (WHERE p.status = 'success')  AS basarili_odemesi_olan,
       count(DISTINCT o.id) FILTER (WHERE p.status = 'failed')   AS basarisiz_denemesi_olan,
       count(DISTINCT o.id) FILTER (WHERE p.status = 'refunded') AS iade_kaydi_olan
FROM orders o
LEFT JOIN payments p ON p.order_id = o.id
GROUP BY o.status
ORDER BY siparis DESC;

-- d) Tutarlilik: hic basarili odemesi olmayan siparis var mi?
SELECT count(*) AS basarili_odemesi_olmayan_siparis
FROM orders o
WHERE NOT EXISTS (
    SELECT 1 FROM payments p WHERE p.order_id = o.id AND p.status = 'success'
);

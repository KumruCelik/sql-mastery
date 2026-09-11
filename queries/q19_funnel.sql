-- q19_funnel.sql
-- Soru: Funnel — created > paid > shipped > delivered donusum oranlari. (zorunlu)
-- Konu: FILTER ile kumulatif asama sayimi, turetilmis tablo
-- Varsayim: orders.status yalnizca guncel durumu tutuyor; asamalar kumulatif sayiliyor.
--           'returned' siparisler teslim asamasindan gecmis kabul ediliyor.
--           'cancelled' siparislerin hangi asamada iptal edildigi bilinmiyor.

SELECT asama1_olusturuldu,
       asama2_odendi,
       asama3_kargolandi,
       asama4_teslim,
       round(100.0 * asama2_odendi     / asama1_olusturuldu, 2) AS olusturuldu_to_odendi,
       round(100.0 * asama3_kargolandi / asama2_odendi,      2) AS odendi_to_kargolandi,
       round(100.0 * asama4_teslim     / asama3_kargolandi,  2) AS kargolandi_to_teslim,
       round(100.0 * asama4_teslim     / asama1_olusturuldu, 2) AS uctan_uca_donusum
FROM (
    SELECT count(*)                                                                   AS asama1_olusturuldu,
           count(*) FILTER (WHERE status IN ('paid','shipped','delivered','returned')) AS asama2_odendi,
           count(*) FILTER (WHERE status IN ('shipped','delivered','returned'))        AS asama3_kargolandi,
           count(*) FILTER (WHERE status IN ('delivered','returned'))                  AS asama4_teslim
    FROM orders
) AS f;

-- Her asamada kac siparis dustu?
SELECT 'olusturuldu -> odendi'   AS gecis,
       count(*) FILTER (WHERE status = 'created')   AS dusen_siparis
FROM orders
UNION ALL
SELECT 'odendi -> kargolandi',
       count(*) FILTER (WHERE status = 'paid')
FROM orders
UNION ALL
SELECT 'kargolandi -> teslim',
       count(*) FILTER (WHERE status = 'shipped')
FROM orders
UNION ALL
SELECT 'iptal (asamasi bilinmiyor)',
       count(*) FILTER (WHERE status = 'cancelled')
FROM orders;

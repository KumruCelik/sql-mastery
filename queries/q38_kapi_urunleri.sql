-- q38_kapi_urunleri.sql
-- Soru: Her kullanicinin ilk siparisinde aldigi urunler.
-- Is sorusu: hangi urunler yeni musteri getiriyor? (kapi urunu / gateway product)
-- Konu: DISTINCT ON ile ilk siparis, oran hesabi, fan-out'tan kacinma
-- Kapsam: paid + shipped + delivered siparisler.

-- a) Kapi orani: bir urunu alanlarin yuzde kaci onu ILK siparisinde almis?
WITH ilk_siparis AS (
    SELECT DISTINCT ON (o.user_id)
           o.user_id, o.id AS order_id
    FROM orders o
    WHERE o.status IN ('paid', 'shipped', 'delivered')
    ORDER BY o.user_id, o.ordered_at, o.id
),
ilk_urunler AS (
    SELECT oi.product_id, count(DISTINCT i.user_id) AS ilk_sipariste_alan
    FROM ilk_siparis i
    JOIN order_items oi ON oi.order_id = i.order_id
    GROUP BY oi.product_id
),
tum_alanlar AS (
    SELECT oi.product_id, count(DISTINCT o.user_id) AS toplam_alan
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    WHERE o.status IN ('paid','shipped','delivered')
    GROUP BY oi.product_id
)
SELECT p.id, p.sku, p.list_price,
       t.toplam_alan,
       COALESCE(f.ilk_sipariste_alan, 0)                                   AS ilk_sipariste_alan,
       round(100.0 * COALESCE(f.ilk_sipariste_alan, 0) / t.toplam_alan, 2) AS kapi_orani
FROM tum_alanlar t
JOIN products p ON p.id = t.product_id
LEFT JOIN ilk_urunler f ON f.product_id = t.product_id
WHERE t.toplam_alan >= 200
ORDER BY kapi_orani DESC, p.id
LIMIT 15;

-- b) Genel ozet. DIKKAT: siparis basina tek satira indirgenmeden ortalama alinmaz,
--    yoksa cok kalemli siparisler fazla temsil edilir (boyut yanliligi).
WITH ilk_siparis AS (
    SELECT DISTINCT ON (o.user_id) o.user_id, o.id AS order_id
    FROM orders o
    WHERE o.status IN ('paid','shipped','delivered')
    ORDER BY o.user_id, o.ordered_at, o.id
),
kalem_sayilari AS (
    SELECT i.user_id, i.order_id, count(*) AS kalem
    FROM ilk_siparis i
    JOIN order_items oi ON oi.order_id = i.order_id
    GROUP BY i.user_id, i.order_id
)
SELECT count(*)                 AS ilk_siparis_sayisi,
       round(avg(kalem), 3)     AS ort_kalem_dogru,
       (SELECT round(avg(kalem)::numeric, 3)
          FROM kalem_sayilari k2
          JOIN order_items oi2 ON oi2.order_id = k2.order_id) AS ort_kalem_yanli,
       (SELECT count(DISTINCT oi.product_id)
          FROM ilk_siparis i JOIN order_items oi ON oi.order_id = i.order_id) AS farkli_urun
FROM kalem_sayilari;

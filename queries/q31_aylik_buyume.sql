-- q31_aylik_buyume.sql
-- Soru: Ay bazinda buyume orani nedir? (zorunlu)
-- Konu: LAG, window function ile donemsel karsilastirma
-- Kapsam: paid + shipped + delivered siparisler.

WITH aylik AS (
    SELECT date_trunc('month', o.ordered_at)::date     AS ay,
           count(DISTINCT o.id)                        AS siparis,
           sum(oi.quantity * oi.unit_price)            AS ciro
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    WHERE o.status IN ('paid', 'shipped', 'delivered')
    GROUP BY ay
)
SELECT ay,
       siparis,
       round(ciro, 2)                                                      AS ciro,
       round(LAG(ciro) OVER (ORDER BY ay), 2)                              AS onceki_ay_ciro,
       round(ciro - LAG(ciro) OVER (ORDER BY ay), 2)                       AS fark,
       round(100.0 * (ciro - LAG(ciro) OVER (ORDER BY ay))
             / NULLIF(LAG(ciro) OVER (ORDER BY ay), 0), 2)                 AS aylik_buyume_yuzde,
       round(100.0 * (ciro - LAG(ciro, 12) OVER (ORDER BY ay))
             / NULLIF(LAG(ciro, 12) OVER (ORDER BY ay), 0), 2)             AS yillik_buyume_yuzde
FROM aylik
ORDER BY ay;

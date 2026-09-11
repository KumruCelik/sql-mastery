-- q36_kumulatif_ciro.sql
-- Soru: Kumulatif ciro seyri nedir?
-- Konu: pencere cercevesi (frame), varsayilan cerceve, OVER () ve OVER (ORDER BY ...)
-- Kapsam: paid + shipped + delivered siparisler.

WITH aylik AS (
    SELECT date_trunc('month', o.ordered_at)::date  AS ay,
           sum(oi.quantity * oi.unit_price)         AS ciro
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    WHERE o.status IN ('paid', 'shipped', 'delivered')
    GROUP BY ay
)
SELECT ay,
       round(ciro, 2)                                                   AS ciro,
       round(sum(ciro) OVER (ORDER BY ay), 2)                           AS kumulatif_ciro,
       round(sum(ciro) OVER (), 2)                                      AS genel_toplam,
       round(100.0 * sum(ciro) OVER (ORDER BY ay) / sum(ciro) OVER (), 2) AS toplamin_yuzdesi,
       round(avg(ciro) OVER (PARTITION BY EXTRACT(YEAR FROM ay)), 2)    AS o_yilin_ay_ortalamasi
FROM aylik
ORDER BY ay;

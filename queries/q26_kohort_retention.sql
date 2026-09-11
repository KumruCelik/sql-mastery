-- q26_kohort_retention.sql
-- Soru: Kohort retention tablosu - yeni kullanicilarin N. ay donus orani. (zorunlu)
-- Konu: kohort tanimi, ay farki hesabi, FILTER ile pivot, gelecek hucrelerin NULL olmasi
-- Kapsam: paid + shipped + delivered siparisler.
-- Kohort tanimi: kullanicinin ILK siparisinin ayi.

WITH aktivite AS (
    SELECT DISTINCT o.user_id,
           date_trunc('month', o.ordered_at)::date AS ay
    FROM orders o
    WHERE o.status IN ('paid', 'shipped', 'delivered')
),
ilk_ay AS (
    SELECT user_id, min(ay) AS kohort
    FROM aktivite
    GROUP BY user_id
),
ufuk AS (
    SELECT max(ay) AS son_ay FROM aktivite
),
kohort_aktivite AS (
    SELECT i.kohort,
           a.user_id,
           (EXTRACT(YEAR FROM age(a.ay, i.kohort)) * 12
            + EXTRACT(MONTH FROM age(a.ay, i.kohort)))::int AS ay_no
    FROM ilk_ay i
    JOIN aktivite a ON a.user_id = i.user_id
),
boyut AS (
    SELECT kohort, count(*) AS kohort_boyu
    FROM ilk_ay
    GROUP BY kohort
)
SELECT b.kohort,
       b.kohort_boyu,
       CASE WHEN b.kohort + interval '1 month' <= (SELECT son_ay FROM ufuk)
            THEN round(100.0 * count(DISTINCT k.user_id) FILTER (WHERE k.ay_no = 1) / b.kohort_boyu, 1)
       END AS m1,
       CASE WHEN b.kohort + interval '2 month' <= (SELECT son_ay FROM ufuk)
            THEN round(100.0 * count(DISTINCT k.user_id) FILTER (WHERE k.ay_no = 2) / b.kohort_boyu, 1)
       END AS m2,
       CASE WHEN b.kohort + interval '3 month' <= (SELECT son_ay FROM ufuk)
            THEN round(100.0 * count(DISTINCT k.user_id) FILTER (WHERE k.ay_no = 3) / b.kohort_boyu, 1)
       END AS m3,
       CASE WHEN b.kohort + interval '6 month' <= (SELECT son_ay FROM ufuk)
            THEN round(100.0 * count(DISTINCT k.user_id) FILTER (WHERE k.ay_no = 6) / b.kohort_boyu, 1)
       END AS m6,
       CASE WHEN b.kohort + interval '12 month' <= (SELECT son_ay FROM ufuk)
            THEN round(100.0 * count(DISTINCT k.user_id) FILTER (WHERE k.ay_no = 12) / b.kohort_boyu, 1)
       END AS m12
FROM boyut b
JOIN kohort_aktivite k ON k.kohort = b.kohort
GROUP BY b.kohort, b.kohort_boyu
ORDER BY b.kohort;

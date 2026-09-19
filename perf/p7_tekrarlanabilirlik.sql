-- P7: Olcum tekrarlanabilirligi
-- P1'deki iki sorgu surumu N kez calistirilir; ortanca ve yayilim raporlanir.
-- Amac: sure makine/onbellek durumuna bagli, buffer sayisi degil -- bunu olcmek.
--
-- Iki kosulda calistirilir:
--   SOGUK : docker compose restart db  ->  hemen bu dosya
--   SICAK : ayni dosya ikinci kez
-- Plan onbellegi etkisini disarida birakmak icin sorgular EXECUTE ile dinamik calistirilir.

\timing off
\pset border 2

DROP TABLE IF EXISTS olcum;
CREATE TEMP TABLE olcum (surum text, tekrar int, ms numeric);

DO $$
DECLARE
    yavas text := $q$
        SELECT p.id
        FROM products p
        WHERE p.stock_cached <> COALESCE((SELECT sum(m.quantity)
                                          FROM inventory_movements m
                                          WHERE m.product_id = p.id), 0)
    $q$;
    hizli text := $q$
        WITH bakiye AS (
            SELECT product_id, sum(quantity) AS q
            FROM inventory_movements
            GROUP BY product_id
        )
        SELECT p.id
        FROM products p
        LEFT JOIN bakiye b ON b.product_id = p.id
        WHERE p.stock_cached <> COALESCE(b.q, 0)
    $q$;
    t0 timestamptz;
    i  int;
    n  int := 7;
BEGIN
    FOR i IN 1..n LOOP
        t0 := clock_timestamp();
        EXECUTE 'SELECT count(*) FROM (' || yavas || ') s';
        INSERT INTO olcum
        VALUES ('yavas', i, extract(epoch FROM clock_timestamp() - t0) * 1000);
    END LOOP;

    FOR i IN 1..n LOOP
        t0 := clock_timestamp();
        EXECUTE 'SELECT count(*) FROM (' || hizli || ') s';
        INSERT INTO olcum
        VALUES ('hizli', i, extract(epoch FROM clock_timestamp() - t0) * 1000);
    END LOOP;
END $$;

\echo ''
\echo '===== 1) HER TEKRARIN SURESI (ms) ====='
SELECT tekrar,
       round(max(ms) FILTER (WHERE surum = 'yavas'), 2) AS yavas,
       round(max(ms) FILTER (WHERE surum = 'hizli'), 2) AS hizli
FROM olcum
GROUP BY tekrar
ORDER BY tekrar;

\echo ''
\echo '===== 2) OZET: ortanca ve yayilim ====='
SELECT surum,
       count(*)                                                                  AS tekrar,
       round(min(ms), 2)                                                         AS en_dusuk,
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY ms)::numeric, 2)        AS ortanca,
       round(max(ms), 2)                                                         AS en_yuksek,
       round(((max(ms) - min(ms))
              / percentile_cont(0.5) WITHIN GROUP (ORDER BY ms)::numeric) * 100, 1)
                                                                                 AS yayilim_yuzde,
       round(max(ms) FILTER (WHERE tekrar = 1), 2)                               AS ilk_kosu
FROM olcum
GROUP BY surum
ORDER BY ortanca DESC;

\echo ''
\echo '===== 3) BUFFER (deterministik olmasi beklenen olcu) ====='
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
SELECT p.id
FROM products p
WHERE p.stock_cached <> COALESCE((SELECT sum(m.quantity)
                                  FROM inventory_movements m
                                  WHERE m.product_id = p.id), 0);

EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
WITH bakiye AS (
    SELECT product_id, sum(quantity) AS q
    FROM inventory_movements
    GROUP BY product_id
)
SELECT p.id
FROM products p
LEFT JOIN bakiye b ON b.product_id = p.id
WHERE p.stock_cached <> COALESCE(b.q, 0);

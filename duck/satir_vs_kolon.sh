#!/usr/bin/env bash
# Ayni veri, iki depolama bicimi: Postgres (satir bazli) vs DuckDB/Parquet (kolon bazli).
set -e
cd ~/projects/sql-mastery
PSQL="psql -h localhost -p 5433 -U kumru -d shop"
DUCK=~/.local/bin/duckdb

echo "===== 1) fct_order_items Parquet'e aktariliyor ====="
$PSQL -q -c "\copy (SELECT * FROM star.fct_order_items) TO 'data/fct_order_items.csv' WITH (FORMAT csv, HEADER true)"
$DUCK -c "COPY (SELECT * FROM read_csv_auto('data/fct_order_items.csv')) TO 'data/fct_order_items.parquet' (FORMAT parquet);"

echo ""
echo "===== 2) DEPOLAMA BOYUTU ====="
$PSQL -t -c "SELECT 'postgres tablo: ' || pg_size_pretty(pg_total_relation_size('star.fct_order_items'));"
ls -lh data/fct_order_items.csv data/fct_order_items.parquet | awk '{print $9": "$5}'

echo ""
echo "===== 3) POSTGRES (satir bazli) ====="
$PSQL -c '\timing on' -c "SELECT sum(brut_tutar) FROM star.fct_order_items;" \
      -c "SELECT status, count(*), sum(brut_tutar) FROM star.fct_order_items GROUP BY status;" \
      -c "SELECT product_sk, sum(brut_tutar) AS c FROM star.fct_order_items GROUP BY product_sk ORDER BY c DESC LIMIT 10;" \
      2>&1 | grep -E "^Time:|^ *sum|rows\)"

echo ""
echo "===== 4) DUCKDB / PARQUET (kolon bazli) ====="
$DUCK -c ".timer on" -c "SELECT sum(brut_tutar) FROM 'data/fct_order_items.parquet';" \
      -c "SELECT status, count(*), sum(brut_tutar) FROM 'data/fct_order_items.parquet' GROUP BY status;" \
      -c "SELECT product_sk, sum(brut_tutar) AS c FROM 'data/fct_order_items.parquet' GROUP BY product_sk ORDER BY c DESC LIMIT 10;" \
      2>&1 | grep -E "Run Time|sum\(brut"

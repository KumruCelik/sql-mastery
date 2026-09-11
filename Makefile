.RECIPEPREFIX = >
PSQL := psql -h localhost -p 5433 -U kumru -d shop -v ON_ERROR_STOP=1
DUCK := $(HOME)/.local/bin/duckdb

.PHONY: up down wait migrate generate load seed refresh-stock check \
        star star-test compare duck duck-compare perf clean help

help:
> @echo "up            konteyneri baslat"
> @echo "down          konteyneri durdur"
> @echo "migrate       migrations/*.sql dosyalarini sirayla uygular"
> @echo "generate      sentetik veriyi uretir (data/*.csv)"
> @echo "load          CSV'leri veritabanina yukler"
> @echo "seed          SIFIRDAN kurar ve doldurur (volume silinir)"
> @echo "refresh-stock stock_cached kolonunu defterden yeniden hesaplar"
> @echo "check         veri kalitesi kontrolleri"
> @echo "star          analitik katmani doldurur (idempotent)"
> @echo "star-test     SCD2 ve idempotency testleri"
> @echo "compare       10 is sorusu: OLTP vs star schema"
> @echo "duck          NYC taksi verisi uzerinde 10 DuckDB sorgusu"
> @echo "duck-compare  DuckDB vs pandas, satir vs kolon bazli depolama"
> @echo "perf          performans laboratuvari olcumleri"

up:
> docker compose up -d

down:
> docker compose down

wait:
> until docker compose exec -T db pg_isready -U kumru -d shop >/dev/null 2>&1; do sleep 1; done

migrate:
> for f in migrations/*.sql; do $(PSQL) -f "$$f"; done

generate:
> python3 scripts/generate.py

load:
> $(PSQL) -f seed/load.sql

refresh-stock:
> $(PSQL) -f seed/refresh_stock.sql

check:
> $(PSQL) -f seed/checks.sql

star:
> $(PSQL) -f star/load_star.sql
> $(PSQL) -f star/load_price_scd2.sql

star-test:
> $(PSQL) -f star/scd2_test.sql

compare:
> $(PSQL) -f star/karsilastirma.sql

duck:
> $(DUCK) < duck/analiz.sql

duck-compare:
> python3 duck/pandas_karsilastirma.py
> ./duck/satir_vs_kolon.sh

perf:
> for f in perf/p*.sql; do echo "=== $$f ==="; $(PSQL) -f "$$f"; done

clean:
> rm -f data/*.csv data/fct_order_items.parquet

# DoD: sifirdan kurup doldurur. DIKKAT: mevcut veritabanini siler.
seed:
> docker compose down -v
> docker compose up -d
> $(MAKE) wait
> $(MAKE) migrate
> $(MAKE) generate
> $(MAKE) load
> $(MAKE) star
> $(MAKE) check

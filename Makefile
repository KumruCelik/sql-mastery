.RECIPEPREFIX = >
PSQL := psql -h localhost -p 5433 -U kumru -d shop -v ON_ERROR_STOP=1

.PHONY: up down wait migrate generate load seed refresh-stock check clean

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

clean:
> rm -f data/*.csv

# DoD: sifirdan kurup doldurur. DIKKAT: mevcut veritabanini siler.
seed:
> docker compose down -v
> docker compose up -d
> $(MAKE) wait
> $(MAKE) migrate
> $(MAKE) generate
> $(MAKE) load
> $(MAKE) check

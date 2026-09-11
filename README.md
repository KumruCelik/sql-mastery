# sql-mastery

"Yapay Zekâ & Veri Odaklı Yazılım Mühendisi" programı, **Bölüm 3 — SQL ve veri modelleme** çalışması.

Sıfırdan kurulan bir e-ticaret OLTP şeması, 685 bin satırlık sentetik veri üreticisi,
50 iş sorusundan oluşan analitik sorgu seti, performans laboratuvarı, SCD2'li star schema
ve DuckDB ile dosya analitiği.

Yazılı çıktılar (cevaplar, ölçümler, araştırma yazıları) ayrı bir depoda:
[`ai-engineer-journey/bolum03`](https://github.com/KumruCelik/ai-engineer-journey/tree/main/bolum03)

---

## Gereksinimler

- Docker (PostgreSQL 16 konteyneri için)
- `psql` istemcisi — `sudo apt install postgresql-client`
- Python 3.12 (standart kütüphane yeterli; karşılaştırma betiği için `duckdb pandas pyarrow`)
- DuckDB CLI (yalnızca Ödev 3.5 için) — `~/.local/bin/duckdb`

## Hızlı başlangıç

```bash
cp .env.example .env      # kullanici/parola/veritabani adi
make seed                 # sifirdan kurar ve doldurur (~1 dakika)
```

`make seed` mevcut veritabanını **siler** ve baştan kurar: konteyneri yeniden başlatır,
migration'ları sırayla uygular, sentetik veriyi üretir, yükler, analitik katmanı doldurur
ve veri kalitesi kontrollerini çalıştırır. Ödev 3.1'in tamamlanma ölçütü budur.

`make help` tüm komutları listeler.

## Klasörler

| Klasör | İçerik |
|---|---|
| `migrations/` | Sıralı şema dosyaları (001–009). Çalışmış bir migration değiştirilmez, üstüne yenisi eklenir. |
| `scripts/` | `generate.py` — sentetik veri üreticisi |
| `seed/` | Yükleme (`load.sql`), stok yenileme, veri kalitesi kontrolleri |
| `queries/` | Ödev 3.2'nin 50 iş sorusu (`q01`–`q50`) |
| `perf/` | Ödev 3.3 performans ölçümleri (`p1`–`p6`) |
| `star/` | Ödev 3.4 analitik katman: yükleme, SCD2 testi, OLTP/star karşılaştırması |
| `duck/` | Ödev 3.5 DuckDB analizi ve pandas karşılaştırması |
| `data/` | Üretilen CSV ve indirilen Parquet dosyaları — **commit edilmez** |

## Şema

**OLTP (`public`)** — 11 tablo:
`users`, `categories` (hiyerarşik), `products`, `orders`, `order_items`,
`payments`, `shipments`, `coupons`, `order_coupons`, `reviews`, `inventory_movements`

ER diyagramı: [`docs/er.mmd`](docs/er.mmd) (Mermaid, GitHub'da doğrudan görüntülenir)

**Analitik (`star`)** — 6 tablo:
`dim_date`, `dim_customer` (SCD2), `dim_product` (SCD1), `dim_product_price` (SCD2 mini-boyut),
`fct_orders`, `fct_order_items`

Tasarım kararları ve reddedilen alternatifler: [`DESIGN.md`](DESIGN.md)

## Veri

Üretici sabit tohumla (`random.seed(42)`) çalışır, dolayısıyla tekrarlanabilirdir.
Ürettiği özellikler: mevsimsellik (kasım-aralık zirvesi, haftasonu artışı), ürün ve
kullanıcı popülerliğinde güç yasası, ~%2 iade, ~%5 eksik veri ve kasıtlı anomaliler.

| Tablo | Satır |
|---|---|
| `users` | 20.000 |
| `products` | 2.000 |
| `orders` | 100.000 |
| `order_items` | 168.920 |
| `inventory_movements` | 164.012 |
| `payments` | 108.094 |
| `shipments` | 77.999 |
| `reviews` | 26.810 |
| **Toplam** | **685.966** |

Üreticinin bilinen gerçekçilik kusurları (zarar anomalisinin sabit oranlı olması,
alım hareketlerinin talepten bağımsız üretilmesi, kupon istiflemesinin sepeti sıfıra
indirebilmesi) `notes/odev-3.2/cevaplar.md` içinde iyileştirme notu olarak kayıtlıdır.

## Öne çıkan ölçümler

**Performans (Ödev 3.3)**

| Sorgu | Önce | Sonra | Kazanç |
|---|---|---|---|
| `refresh_stock` UPDATE | 13.220 ms | 26 ms | 508× |
| `stock_cached` doğrulaması | 12.272 ms | 54 ms | 226× |
| Yorumsuz ürünler | 1.926 ms | 31 ms | 63× |
| Ödeme doğrulaması | 766 ms | 249 ms | 3,1× |

**Star schema (Ödev 3.4)** — 10 iş sorusu toplamı: 769,6 ms → 226,5 ms (3,4×).
Sipariş taneciğinde önceden hesaplanmış ölçülerde 140×'e kadar kazanç.

**DuckDB vs pandas (Ödev 3.5)** — 2,96 milyon satır, aynı üç toplama:
148,9 ms / 171,7 MB (DuckDB) karşı 2.796,4 ms / 1.336,9 MB (pandas).

**Satır vs kolon bazlı depolama** — aynı 168.920 satır:
PostgreSQL 77 MB ve 75,9 ms; Parquet 5,5 MB ve 13 ms.

## Uyulan kurallar

- Conventional Commits
- Veri dosyaları commit'lenmez; onları üreten komut commit'lenir
- Linter kuralı kapatılmaz; dar ve gerekçeli istisna yazılır
- Tasarım kararları `DESIGN.md`'ye reddedilen alternatifiyle birlikte yazılır;
  karar değişirse silinmez, "GERİ ALINDI" diye işaretlenir
- Çalışmış bir migration geriye dönük değiştirilmez
